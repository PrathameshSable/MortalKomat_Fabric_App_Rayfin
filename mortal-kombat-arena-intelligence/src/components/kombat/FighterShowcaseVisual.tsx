import { useEffect, useMemo, useState } from "react";
import { useFighterAssets } from "./assetManifest";

type FighterShowcaseVisualProps = {
    fighterName: string;
    imagePath?: string;
    isActive?: boolean;
    className?: string;
    fallbackClassName?: string;
    mode?: "card" | "profile" | "compare";
};

function initials(name: string) {
    return name
        .split(" ")
        .map((part) => part[0])
        .join("")
        .slice(0, 2)
        .toUpperCase();
}

function toSvgFallback(path?: string) {
    if (!path) {
        return "";
    }

    return path.replace(/\.(webp|png|jpg|jpeg)$/i, ".svg");
}

function unique(values: string[]) {
    return Array.from(new Set(values.filter(Boolean)));
}

export function FighterShowcaseVisual({
    fighterName,
    imagePath,
    isActive = false,
    className,
    fallbackClassName = "mk-fighter-card__fallback",
    mode = "card",
}: FighterShowcaseVisualProps) {
    const assets = useFighterAssets(fighterName, imagePath);
    const [imageIndex, setImageIndex] = useState(0);
    const [failedSources, setFailedSources] = useState<Set<string>>(() => new Set());

    const images = useMemo(() => {
        const gallery = (assets?.gallery ?? []).slice(0, 2);

        // Prefer imported gallery images only if they exist.
        const manifestImages =
            gallery.length > 0
                ? gallery
                : unique([
                      assets?.hero ?? "",
                      assets?.portrait ?? "",
                      imagePath ?? "",
                      toSvgFallback(imagePath),
                  ]);

        return unique(manifestImages).filter((src) => !failedSources.has(src));
    }, [assets, imagePath, failedSources]);

    useEffect(() => {
        setImageIndex(0);
        setFailedSources(new Set());
    }, [fighterName]);

    useEffect(() => {
        if (!isActive || images.length <= 1) {
            return;
        }

        const interval = window.setInterval(() => {
            setImageIndex((current) => (current + 1) % images.length);
        }, 1400);

        return () => window.clearInterval(interval);
    }, [isActive, images.length]);

    const safeIndex = images.length === 0 ? 0 : imageIndex % images.length;
    const activeImage = images[safeIndex];

    if (!activeImage) {
        return <div className={fallbackClassName}>{initials(fighterName)}</div>;
    }

    return (
        <div className="mk-showcase-visual">
            <img
                key={activeImage}
                src={activeImage}
                alt={fighterName}
                className={className}
                loading="lazy"
                onError={() => {
                    setFailedSources((current) => {
                        const next = new Set(current);
                        next.add(activeImage);
                        return next;
                    });
                }}
            />

            {images.length > 1 ? (
                <div className="mk-gallery-count">
                    {safeIndex + 1}/{images.length}
                </div>
            ) : null}
        </div>
    );
}

