import { useMemo, useState } from "react";

type FighterVisualProps = {
    fighterName: string;
    imagePath?: string;
    className?: string;
    fallbackClassName?: string;
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

    return path.replace(/\.webp$/i, ".svg");
}

export function FighterVisual({
    fighterName,
    imagePath,
    className,
    fallbackClassName = "mk-fighter-card__fallback",
}: FighterVisualProps) {
    const svgFallback = useMemo(() => toSvgFallback(imagePath), [imagePath]);
    const [sourceMode, setSourceMode] = useState<"webp" | "svg" | "fallback">(
        imagePath ? "webp" : svgFallback ? "svg" : "fallback"
    );

    const src = sourceMode === "webp" ? imagePath : sourceMode === "svg" ? svgFallback : "";

    if (!src || sourceMode === "fallback") {
        return <div className={fallbackClassName}>{initials(fighterName)}</div>;
    }

    return (
        <img
            src={src}
            alt={fighterName}
            className={className}
            loading="lazy"
            onError={() => {
                if (sourceMode === "webp" && svgFallback) {
                    setSourceMode("svg");
                } else {
                    setSourceMode("fallback");
                }
            }}
        />
    );
}
