import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const appRoot = process.cwd();
const incomingRoot = process.argv[2] || path.resolve(appRoot, "..", "incoming-assets", "fighters");
const outputRoot = path.join(appRoot, "public", "assets", "fighters");

const maxImagesPerFighter = Number(process.env.MAX_IMAGES_PER_FIGHTER || 3);
const quality = Number(process.env.WEBP_QUALITY || 68);
const maxWidth = Number(process.env.MAX_WIDTH || 900);
const maxHeight = Number(process.env.MAX_HEIGHT || 1200);

const imageExtensions = new Set([".png", ".jpg", ".jpeg", ".webp"]);

function prettyNameFromSlug(slug) {
    return slug
        .split("-")
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(" ");
}

function scoreFileName(fileName) {
    const name = fileName.toLowerCase();
    let score = 0;

    if (name.includes("hero")) score += 100;
    if (name.includes("render")) score += 80;
    if (name.includes("action")) score += 70;
    if (name.includes("pose")) score += 60;
    if (name.includes("season")) score += 50;
    if (name.includes("stpat")) score += 45;
    if (name.includes("mk95")) score += 40;
    if (name.includes("background")) score += 30;
    if (name.includes("portrait")) score += 20;

    return score;
}

async function exists(filePath) {
    try {
        await fs.access(filePath);
        return true;
    } catch {
        return false;
    }
}

async function ensureDir(folderPath) {
    await fs.mkdir(folderPath, { recursive: true });
}

async function listFilesRecursive(folderPath) {
    const entries = await fs.readdir(folderPath, { withFileTypes: true });
    const files = [];

    for (const entry of entries) {
        const currentPath = path.join(folderPath, entry.name);

        if (entry.isDirectory()) {
            files.push(...await listFilesRecursive(currentPath));
        } else {
            const ext = path.extname(entry.name).toLowerCase();

            if (imageExtensions.has(ext)) {
                const stat = await fs.stat(currentPath);
                files.push({
                    path: currentPath,
                    name: entry.name,
                    size: stat.size,
                });
            }
        }
    }

    return files;
}

async function cleanOldOutput() {
    await ensureDir(outputRoot);

    const entries = await fs.readdir(outputRoot, { withFileTypes: true });

    for (const entry of entries) {
        const currentPath = path.join(outputRoot, entry.name);

        if (entry.isDirectory()) {
            await fs.rm(path.join(currentPath, "gallery"), {
                recursive: true,
                force: true,
            });

            const files = await fs.readdir(currentPath, { withFileTypes: true });

            for (const file of files) {
                if (!file.isFile()) continue;

                const ext = path.extname(file.name).toLowerCase();

                if (imageExtensions.has(ext)) {
                    await fs.rm(path.join(currentPath, file.name), {
                        force: true,
                    });
                }
            }
        }
    }

    await fs.rm(path.join(outputRoot, "_fighter-assets.json"), { force: true });
    await fs.rm(path.join(outputRoot, "_fighter-assets-report.csv"), { force: true });
    await fs.rm(path.join(outputRoot, "_unmatched-assets.txt"), { force: true });
}

function toWebPath(slug, fileName) {
    return `/assets/fighters/${slug}/gallery/${fileName}`;
}

async function main() {
    console.log("========================================");
    console.log("Optimized fighter asset import");
    console.log("========================================");
    console.log("App root:", appRoot);
    console.log("Incoming root:", incomingRoot);
    console.log("Output root:", outputRoot);
    console.log("MAX_IMAGES_PER_FIGHTER:", maxImagesPerFighter);
    console.log("WEBP_QUALITY:", quality);
    console.log("MAX_WIDTH:", maxWidth);
    console.log("MAX_HEIGHT:", maxHeight);
    console.log("");

    if (!await exists(incomingRoot)) {
        throw new Error(`Incoming fighter assets folder not found: ${incomingRoot}`);
    }

    await cleanOldOutput();

    const fighterFolders = (await fs.readdir(incomingRoot, { withFileTypes: true }))
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .sort();

    const manifest = {};
    const report = [];

    for (const slug of fighterFolders) {
        const sourceFolder = path.join(incomingRoot, slug);
        const outputFolder = path.join(outputRoot, slug);
        const galleryFolder = path.join(outputFolder, "gallery");

        await ensureDir(galleryFolder);

        const sourceFiles = await listFilesRecursive(sourceFolder);

        const selectedFiles = sourceFiles
            .sort((a, b) => {
                const scoreDiff = scoreFileName(b.name) - scoreFileName(a.name);

                if (scoreDiff !== 0) {
                    return scoreDiff;
                }

                return b.size - a.size;
            })
            .slice(0, maxImagesPerFighter);

        const gallery = [];

        for (let index = 0; index < selectedFiles.length; index += 1) {
            const source = selectedFiles[index];
            const outputName = `image-${String(index + 1).padStart(2, "0")}.webp`;
            const outputPath = path.join(galleryFolder, outputName);

            await sharp(source.path)
                .resize({
                    width: maxWidth,
                    height: maxHeight,
                    fit: "inside",
                    withoutEnlargement: true,
                })
                .webp({
                    quality,
                    effort: 5,
                })
                .toFile(outputPath);

            gallery.push(toWebPath(slug, outputName));
        }

        manifest[slug] = {
            slug,
            name: prettyNameFromSlug(slug),
            hero: gallery[0] ?? null,
            portrait: gallery[0] ?? null,
            background: gallery[1] ?? gallery[0] ?? null,
            gallery,
        };

        const totalOutputBytes = await Promise.all(
            gallery.map(async (webPath) => {
                const fileName = path.basename(webPath);
                const stat = await fs.stat(path.join(galleryFolder, fileName));
                return stat.size;
            })
        );

        const outputMb = totalOutputBytes.reduce((sum, value) => sum + value, 0) / 1024 / 1024;

        report.push({
            Fighter: prettyNameFromSlug(slug),
            Slug: slug,
            SourceFiles: sourceFiles.length,
            ImportedFiles: gallery.length,
            OutputMB: outputMb.toFixed(2),
            Hero: manifest[slug].hero ?? "",
        });

        console.log(`${slug}: source ${sourceFiles.length}, imported ${gallery.length}, output ${outputMb.toFixed(2)} MB`);
    }

    await fs.writeFile(
        path.join(outputRoot, "_fighter-assets.json"),
        JSON.stringify(manifest, null, 2),
        "utf8"
    );

    const csvHeader = "Fighter,Slug,SourceFiles,ImportedFiles,OutputMB,Hero";
    const csvRows = report.map((row) =>
        [
            row.Fighter,
            row.Slug,
            row.SourceFiles,
            row.ImportedFiles,
            row.OutputMB,
            row.Hero,
        ]
            .map((value) => `"${String(value).replaceAll('"', '""')}"`)
            .join(",")
    );

    await fs.writeFile(
        path.join(outputRoot, "_fighter-assets-report.csv"),
        [csvHeader, ...csvRows].join("\n"),
        "utf8"
    );

    const publicSize = await listFilesRecursive(path.join(appRoot, "public"));
    const publicMb = publicSize.reduce((sum, file) => sum + file.size, 0) / 1024 / 1024;

    console.log("");
    console.log("Manifest written:", path.join(outputRoot, "_fighter-assets.json"));
    console.log("Report written:", path.join(outputRoot, "_fighter-assets-report.csv"));
    console.log("Current public folder image size approx:", publicMb.toFixed(2), "MB");
    console.log("");
    console.log("Done.");
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
