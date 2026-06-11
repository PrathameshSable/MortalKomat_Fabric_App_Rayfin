import { useEffect, useMemo, useState } from "react";

export type FighterAssetSet = {
    slug: string;
    name: string;
    hero?: string | null;
    portrait?: string | null;
    background?: string | null;
    gallery?: string[];
};

type FighterManifest = Record<string, FighterAssetSet>;

let manifestCache: FighterManifest | null = null;
let manifestPromise: Promise<FighterManifest> | null = null;

function slugify(value: string) {
    return value
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "");
}

export function slugFromPath(path?: string) {
    if (!path) {
        return "";
    }

    const match = path.match(/\/assets\/fighters\/([^/]+)\//i);
    return match?.[1] ?? "";
}

async function loadFighterManifest() {
    if (manifestCache) {
        return manifestCache;
    }

    if (!manifestPromise) {
        manifestPromise = fetch("/assets/fighters/_fighter-assets.json", {
            cache: "no-store",
        })
            .then((response) => {
                if (!response.ok) {
                    return {};
                }

                return response.json();
            })
            .then((manifest: FighterManifest) => {
                manifestCache = manifest;
                return manifest;
            })
            .catch(() => {
                manifestCache = {};
                return {};
            });
    }

    return manifestPromise;
}

export function useFighterAssets(fighterName: string, fullBodyImagePath?: string) {
    const [manifest, setManifest] = useState<FighterManifest | null>(manifestCache);

    useEffect(() => {
        let isMounted = true;

        loadFighterManifest().then((loadedManifest) => {
            if (isMounted) {
                setManifest(loadedManifest);
            }
        });

        return () => {
            isMounted = false;
        };
    }, []);

    const slug = useMemo(() => {
        return slugFromPath(fullBodyImagePath) || slugify(fighterName);
    }, [fighterName, fullBodyImagePath]);

    return manifest?.[slug] ?? null;
}
