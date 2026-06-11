# =====================================================
# Step 12B - Apply Cinematic Gallery Hover UI
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"
$StylesFile = Join-Path $AppRoot "src\styles\mk-theme.css"

if (-not (Test-Path $AppRoot)) { throw "App root not found: $AppRoot" }
if (-not (Test-Path $ComponentsFolder)) { throw "Components folder not found: $ComponentsFolder" }
if (-not (Test-Path $StylesFile)) { throw "Styles file not found: $StylesFile" }

function Backup-File {
    param([string]$Path)

    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Copy-Item $Path "$Path.backup_$timestamp" -Force
        Write-Host "BACKUP: $Path.backup_$timestamp"
    }
}

function Write-TextFile {
    param([string]$Path, [string]$Content)

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "WROTE: $Path"
}

Backup-File (Join-Path $ComponentsFolder "FighterCard3D.tsx")
Backup-File (Join-Path $ComponentsFolder "FighterProfilePanel.tsx")
Backup-File (Join-Path $ComponentsFolder "HomeLanding.tsx")
Backup-File (Join-Path $ComponentsFolder "KpiSummary.tsx")
Backup-File (Join-Path $ComponentsFolder "MkAppShell.tsx")
Backup-File $StylesFile

Write-TextFile -Path (Join-Path $ComponentsFolder "assetManifest.ts") -Content @'
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
'@

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterShowcaseVisual.tsx") -Content @'
import { useEffect, useMemo, useState } from "react";
import { useFighterAssets } from "./assetManifest";

type FighterShowcaseVisualProps = {
    fighterName: string;
    imagePath?: string;
    isActive?: boolean;
    className?: string;
    fallbackClassName?: string;
    mode?: "card" | "profile";
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
        const gallery = assets?.gallery ?? [];
        const preferred = mode === "profile"
            ? [assets?.hero ?? "", assets?.portrait ?? ""]
            : [assets?.hero ?? "", ...(gallery ?? [])];

        return unique([
            ...preferred,
            imagePath ?? "",
            toSvgFallback(imagePath),
        ]).filter((src) => !failedSources.has(src));
    }, [assets, imagePath, failedSources, mode]);

    useEffect(() => {
        setImageIndex(0);
    }, [fighterName, images.length]);

    useEffect(() => {
        if (!isActive || images.length <= 1) {
            return;
        }

        const interval = window.setInterval(() => {
            setImageIndex((current) => (current + 1) % images.length);
        }, 850);

        return () => window.clearInterval(interval);
    }, [isActive, images.length]);

    const activeImage = images[Math.min(imageIndex, Math.max(images.length - 1, 0))];

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
                    {imageIndex + 1}/{images.length}
                </div>
            ) : null}
        </div>
    );
}
'@

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterCard3D.tsx") -Content @'
import { useState } from "react";
import type { CSSProperties } from "react";
import type { FighterRow } from "./types";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";

type FighterCard3DProps = {
    fighter: FighterRow;
    isSelected?: boolean;
    onSelect: () => void;
};

export function FighterCard3D({ fighter, isSelected = false, onSelect }: FighterCard3DProps) {
    const [isHovering, setIsHovering] = useState(false);

    const style = {
        "--fighter-primary": fighter.primaryColor || "#ff5a1f",
        "--fighter-secondary": fighter.secondaryColor || "#120705",
    } as CSSProperties;

    return (
        <button
            type="button"
            className={`mk-fighter-card${isSelected ? " is-selected" : ""}${isHovering ? " is-hovering" : ""}`}
            onClick={onSelect}
            onMouseEnter={() => setIsHovering(true)}
            onMouseLeave={() => setIsHovering(false)}
            style={style}
            aria-label={`View profile for ${fighter.fighterName}`}
        >
            <div className="mk-fighter-card__glow" />
            <div className="mk-fighter-card__flame-ring" />

            <div className="mk-fighter-card__meta">
                <span className="mk-pill">{fighter.rosterGroup}</span>
                <strong className="mk-pill">{fighter.element}</strong>
            </div>

            <div className="mk-fighter-card__image-wrap">
                <FighterShowcaseVisual
                    fighterName={fighter.fighterName}
                    imagePath={fighter.fullBodyImagePath}
                    isActive={isHovering || isSelected}
                    className="mk-fighter-card__image"
                    mode="card"
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
                    <span>{isSelected ? "Selected" : isHovering ? "Cycle render" : "View profile"}</span>
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
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";

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
                    <FighterShowcaseVisual
                        fighterName={fighter.fighterName}
                        imagePath={fighter.fullBodyImagePath}
                        isActive
                        className="mk-profile-image__img"
                        fallbackClassName="mk-profile-image__fallback"
                        mode="profile"
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
                Hover fighter cards to cycle available render images. Select another card to switch profile.
            </div>
        </section>
    );
}
'@

Write-TextFile -Path (Join-Path $ComponentsFolder "HomeLanding.tsx") -Content @'
import type { AppTab } from "./AppNavigation";

type HomeLandingProps = {
    onNavigate: (tab: AppTab) => void;
};

export function HomeLanding({ onNavigate }: HomeLandingProps) {
    return (
        <section className="mk-home mk-home-cinematic">
            <div className="mk-fire-layer" />
            <div className="mk-home-hero mk-home-hero-compact">
                <div className="mk-home-copy">
                    <img
                        src="/assets/branding/mk-logo.png"
                        alt="Mortal Kombat"
                        className="mk-home-logo"
                        onError={(event) => {
                            event.currentTarget.style.display = "none";
                        }}
                    />

                    <span className="mk-eyebrow">Live Fabric Data App</span>
                    <h1>Arena Intelligence</h1>
                    <p>
                        Enter a cinematic analytics arena powered by Microsoft Fabric, semantic
                        models, DAX and Rayfin.
                    </p>

                    <div className="mk-home-actions">
                        <button type="button" onClick={() => onNavigate("roster")}>
                            Choose Your Fighter
                        </button>
                        <button type="button" onClick={() => onNavigate("compare")}>
                            Fighter A vs Fighter B
                        </button>
                    </div>
                </div>

                <div className="mk-home-emblem mk-home-emblem-live">
                    <span>LIVE</span>
                    <strong>35</strong>
                    <em>fighters loaded</em>
                </div>
            </div>

            <div className="mk-home-card-grid mk-home-card-grid-compact">
                <article>
                    <span>01</span>
                    <h3>Semantic Model</h3>
                    <p>Live KPIs and rankings from Fabric.</p>
                </article>
                <article>
                    <span>02</span>
                    <h3>Roster Slicers</h3>
                    <p>Filter by realm, element and style.</p>
                </article>
                <article>
                    <span>03</span>
                    <h3>Compare Mode</h3>
                    <p>Fighter A vs Fighter B stat clash.</p>
                </article>
                <article>
                    <span>04</span>
                    <h3>3D Renders</h3>
                    <p>Hover cards to cycle fighter images.</p>
                </article>
            </div>
        </section>
    );
}
'@

Write-TextFile -Path (Join-Path $ComponentsFolder "KpiSummary.tsx") -Content @'
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { kpiSummaryQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function KpiSummary() {
    const { connection, query } = kpiSummaryQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    if (isLoading) {
        return <div className="mk-loading">Loading Kombat KPIs...</div>;
    }

    const result = data as any;

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load KPIs.</div>;
    }

    if (!result || result.status !== "success") {
        return null;
    }

    const row = result.table.rows[0] ?? [];

    const cards = [
        { label: "Total Matches", value: formatNumber(row[0]), icon: "⚔" },
        { label: "Total XP", value: formatNumber(row[5]), icon: "✦" },
        { label: "Total Score", value: formatNumber(row[7]), icon: "♛" },
        { label: "KOs", value: formatNumber(row[9]), icon: "☠" },
        { label: "Win Rate", value: formatPercent(row[4]), icon: "◈" },
        { label: "Fatalities", value: formatNumber(row[11]), icon: "🔥" },
    ];

    return (
        <section className="mk-kpi-grid">
            {cards.map((card) => (
                <div className="mk-kpi-card mk-kpi-card-premium" key={card.label}>
                    <div className="mk-kpi-icon">{card.icon}</div>
                    <span>{card.label}</span>
                    <strong>{card.value}</strong>
                </div>
            ))}
        </section>
    );
}
'@

# Patch MkAppShell home mode.
$mkShellPath = Join-Path $ComponentsFolder "MkAppShell.tsx"
$mkShellContent = Get-Content -Path $mkShellPath -Raw
$mkShellContent = $mkShellContent -replace '<main className="mk-app">', '<main className={`mk-app ${activeTab === "home" ? "mk-app--home" : ""}`}>'
Set-Content -Path $mkShellPath -Value $mkShellContent -Encoding UTF8
Write-Host "PATCHED: MkAppShell home mode class"

# Append CSS overrides once.
$currentCss = Get-Content -Path $StylesFile -Raw

if ($currentCss -notlike "*Step 12B - Cinematic gallery hover UI*") {
    Add-Content -Path $StylesFile -Value @'

/* =====================================================
   Step 12B - Cinematic gallery hover UI
   ===================================================== */

.mk-app--home {
    min-height: 100vh;
    overflow: hidden;
}

.mk-app--home .mk-top-nav {
    margin-bottom: 14px;
}

.mk-home-cinematic {
    position: relative;
    height: calc(100vh - 118px);
    min-height: 650px;
    overflow: hidden;
    display: grid;
    grid-template-rows: minmax(0, 1fr) auto;
    gap: 14px;
}

.mk-fire-layer {
    position: absolute;
    inset: auto -10% -20% -10%;
    height: 42%;
    pointer-events: none;
    background:
        radial-gradient(circle at 20% 100%, rgba(255, 90, 31, 0.38), transparent 32%),
        radial-gradient(circle at 50% 100%, rgba(248, 184, 78, 0.26), transparent 36%),
        radial-gradient(circle at 80% 100%, rgba(215, 25, 32, 0.30), transparent 32%);
    filter: blur(10px);
    animation: mk-fire-pulse 2.8s ease-in-out infinite alternate;
    z-index: 0;
}

@keyframes mk-fire-pulse {
    from { transform: translateY(18px) scale(1); opacity: 0.72; }
    to { transform: translateY(-4px) scale(1.04); opacity: 1; }
}

.mk-home-hero-compact {
    min-height: unset;
    height: 100%;
    grid-template-columns: minmax(0, 1fr) 300px;
    padding: 34px 42px;
    z-index: 1;
}

.mk-home-hero-compact .mk-home-copy h1 {
    font-size: clamp(58px, 9vw, 116px);
}

.mk-home-hero-compact .mk-home-copy p {
    font-size: 17px;
    max-width: 650px;
}

.mk-home-card-grid-compact {
    position: relative;
    z-index: 2;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 12px;
}

.mk-home-card-grid-compact article {
    padding: 16px;
    min-height: 110px;
}

.mk-home-card-grid-compact h3 {
    margin: 6px 0;
    font-size: 16px;
}

.mk-home-card-grid-compact p {
    margin: 0;
    font-size: 13px;
}

.mk-home-emblem-live {
    min-height: 280px;
}

.mk-home-emblem-live strong {
    font-size: 112px;
}

.mk-fighter-grid {
    grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
    gap: 18px;
}

.mk-fighter-card {
    min-height: 405px;
    border-radius: 24px;
}

.mk-fighter-card__image-wrap {
    inset: 42px 0 118px;
}

.mk-fighter-card__content {
    left: 12px;
    right: 12px;
    bottom: 12px;
    padding: 13px;
    border-radius: 18px;
}

.mk-fighter-card__content h3 {
    font-size: 24px;
}

.mk-fighter-card__content p {
    margin-bottom: 10px;
    font-size: 12px;
}

.mk-fighter-card__stats {
    gap: 6px;
}

.mk-fighter-card__stats div {
    padding: 7px;
}

.mk-fighter-card__stats strong {
    font-size: 12px;
}

.mk-fighter-card__footer {
    font-size: 11px;
}

.mk-showcase-visual {
    position: relative;
    display: grid;
    place-items: center;
    width: 100%;
    height: 100%;
}

.mk-gallery-count {
    position: absolute;
    right: 14px;
    bottom: 14px;
    z-index: 5;
    padding: 5px 8px;
    border-radius: 999px;
    color: var(--mk-gold);
    background: rgba(0, 0, 0, 0.54);
    border: 1px solid rgba(248, 184, 78, 0.32);
    font-size: 11px;
    font-weight: 900;
}

.mk-fighter-card__flame-ring {
    position: absolute;
    inset: -1px;
    z-index: 1;
    border-radius: inherit;
    pointer-events: none;
    background:
        linear-gradient(135deg,
            transparent,
            color-mix(in srgb, var(--fighter-primary) 38%, transparent),
            transparent,
            rgba(248, 184, 78, 0.20),
            transparent);
    opacity: 0;
    filter: blur(10px);
    transition: opacity 180ms ease;
}

.mk-fighter-card.is-hovering .mk-fighter-card__flame-ring,
.mk-fighter-card.is-selected .mk-fighter-card__flame-ring {
    opacity: 1;
}

.mk-fighter-card.is-hovering .mk-fighter-card__image {
    transform: translateZ(70px) scale(1.08) translateY(-4px);
}

.mk-fighter-card__image {
    transition: transform 250ms ease, filter 250ms ease, opacity 250ms ease;
}

.mk-kpi-card-premium {
    position: relative;
    overflow: hidden;
    min-height: 122px;
}

.mk-kpi-card-premium::before {
    content: "";
    position: absolute;
    inset: -40%;
    background: conic-gradient(from 90deg, transparent, rgba(255, 90, 31, 0.18), transparent, rgba(248, 184, 78, 0.12), transparent);
    animation: mk-spin 14s linear infinite;
    opacity: 0.8;
}

.mk-kpi-card-premium > * {
    position: relative;
    z-index: 2;
}

.mk-kpi-icon {
    width: 42px;
    height: 42px;
    display: grid;
    place-items: center;
    margin-bottom: 12px;
    border-radius: 14px;
    color: #160504;
    background: linear-gradient(135deg, var(--mk-gold), var(--mk-orange));
    box-shadow: 0 0 32px rgba(255, 90, 31, 0.28);
    font-weight: 1000;
    font-size: 20px;
}

@media (max-width: 1100px) {
    .mk-app--home {
        overflow: auto;
    }

    .mk-home-cinematic {
        height: auto;
        min-height: 0;
    }

    .mk-home-hero-compact {
        grid-template-columns: 1fr;
        height: auto;
    }

    .mk-home-card-grid-compact {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}

@media (max-width: 760px) {
    .mk-home-card-grid-compact {
        grid-template-columns: 1fr;
    }
}
'@
    Write-Host "APPENDED: Step 12B CSS"
}
else {
    Write-Host "Step 12B CSS already exists. Skipping CSS append."
}

Write-Host ""
Write-Host "Cinematic gallery hover UI applied."
Write-Host "Next:"
Write-Host "cd $AppRoot"
Write-Host "npm run build:fabric"
