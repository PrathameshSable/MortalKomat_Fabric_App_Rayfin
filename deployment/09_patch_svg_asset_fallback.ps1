# =====================================================
# Step 9 - Patch React Components for SVG Asset Fallback
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"

function Backup-File {
    param([string]$Path)

    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Copy-Item $Path "$Path.backup_$timestamp" -Force
        Write-Host "BACKUP: $Path.backup_$timestamp"
    }
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "WROTE: $Path"
}

Backup-File (Join-Path $ComponentsFolder "FighterCard3D.tsx")
Backup-File (Join-Path $ComponentsFolder "FighterProfilePanel.tsx")

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterVisual.tsx") -Content @'
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
'@

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterCard3D.tsx") -Content @'
import type { CSSProperties } from "react";
import type { FighterRow } from "./types";
import { FighterVisual } from "./FighterVisual";

type FighterCard3DProps = {
    fighter: FighterRow;
    isSelected?: boolean;
    onSelect: () => void;
};

export function FighterCard3D({ fighter, isSelected = false, onSelect }: FighterCard3DProps) {
    const style = {
        "--fighter-primary": fighter.primaryColor || "#ff5a1f",
        "--fighter-secondary": fighter.secondaryColor || "#120705",
    } as CSSProperties;

    return (
        <button
            type="button"
            className={`mk-fighter-card${isSelected ? " is-selected" : ""}`}
            onClick={onSelect}
            style={style}
            aria-label={`View profile for ${fighter.fighterName}`}
        >
            <div className="mk-fighter-card__glow" />

            <div className="mk-fighter-card__meta">
                <span className="mk-pill">{fighter.rosterGroup}</span>
                <strong className="mk-pill">{fighter.element}</strong>
            </div>

            <div className="mk-fighter-card__image-wrap">
                <FighterVisual
                    fighterName={fighter.fighterName}
                    imagePath={fighter.fullBodyImagePath}
                    className="mk-fighter-card__image"
                />
            </div>

            <div className="mk-fighter-card__content">
                <span className="mk-fighter-card__realm">{fighter.realm}</span>
                <h3>{fighter.fighterName}</h3>
                <p>
                    {fighter.combatStyle} · {fighter.difficulty}
                </p>

                <div className="mk-fighter-card__stats">
                    <div>
                        <span>XP</span>
                        <strong>{fighter.totalXP.toLocaleString()}</strong>
                    </div>
                    <div>
                        <span>KOs</span>
                        <strong>{fighter.totalKOs.toLocaleString()}</strong>
                    </div>
                    <div>
                        <span>Win</span>
                        <strong>{(fighter.winRate * 100).toFixed(1)}%</strong>
                    </div>
                    <div>
                        <span>Score</span>
                        <strong>{fighter.totalScore.toLocaleString()}</strong>
                    </div>
                </div>

                <div className="mk-fighter-card__footer">
                    <span>{fighter.matchesPlayed.toLocaleString()} matches</span>
                    <span>{isSelected ? "Selected" : "View profile"}</span>
                </div>
            </div>
        </button>
    );
}
'@

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterProfilePanel.tsx") -Content @'
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterProfileQuery } from "@/queries/kombat";
import type { FighterRow } from "./types";
import { FighterVisual } from "./FighterVisual";

type FighterProfilePanelProps = {
    fighter: FighterRow;
    onClose: () => void;
};

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function FighterProfilePanel({ fighter, onClose }: FighterProfilePanelProps) {
    const { connection, query } = fighterProfileQuery(fighter.fighterName);

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;
    const row = result?.status === "success" ? result.table.rows[0] ?? [] : [];

    return (
        <section className="mk-panel mk-profile-panel">
            <div className="mk-profile-toolbar">
                <div>
                    <span className="mk-eyebrow">Selected Fighter</span>
                    <h2>{fighter.fighterName}</h2>
                    <p>
                        {fighter.realm} · {fighter.element} · {fighter.combatStyle} · Rank #
                        {fighter.rank}
                    </p>
                </div>

                <button type="button" className="mk-profile-close" onClick={onClose}>
                    Close profile
                </button>
            </div>

            <div className="mk-profile-grid">
                <div className="mk-profile-image">
                    <FighterVisual
                        fighterName={fighter.fighterName}
                        imagePath={fighter.fullBodyImagePath}
                        className="mk-profile-image__img"
                        fallbackClassName="mk-profile-image__fallback"
                    />
                </div>

                <div>
                    {isLoading ? (
                        <div className="mk-loading">Loading fighter profile...</div>
                    ) : error || result?.status === "error" ? (
                        <div className="mk-error">Unable to load fighter profile.</div>
                    ) : (
                        <div className="mk-mini-grid">
                            <div className="mk-mini-stat">
                                <span>Matches</span>
                                <strong>{formatNumber(row[0])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Wins</span>
                                <strong>{formatNumber(row[1])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Losses</span>
                                <strong>{formatNumber(row[2])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Win Rate</span>
                                <strong>{formatPercent(row[3])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Total XP</span>
                                <strong>{formatNumber(row[4])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Score</span>
                                <strong>{formatNumber(row[6])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>KOs</span>
                                <strong>{formatNumber(row[8])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Fatalities</span>
                                <strong>{formatNumber(row[10])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Brutalities</span>
                                <strong>{formatNumber(row[11])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Damage Eff.</span>
                                <strong>{Number(row[13] ?? 0).toFixed(2)}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Max Combo</span>
                                <strong>{formatNumber(row[14])}</strong>
                            </div>
                            <div className="mk-mini-stat">
                                <span>Score Rank</span>
                                <strong>#{formatNumber(row[17])}</strong>
                            </div>
                        </div>
                    )}
                </div>
            </div>

            <div className="mk-profile-hint">
                Select any other fighter card below to switch profile.
            </div>
        </section>
    );
}
'@

Write-Host "SVG fallback patch applied."