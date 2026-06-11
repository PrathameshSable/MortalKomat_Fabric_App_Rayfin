# =====================================================
# Step 17 - Final Contest UI Polish
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"
$StylesFile = Join-Path $AppRoot "src\styles\mk-theme.css"

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

Backup-File (Join-Path $ComponentsFolder "FighterShowcaseVisual.tsx")
Backup-File (Join-Path $ComponentsFolder "HomeLanding.tsx")
Backup-File (Join-Path $ComponentsFolder "CompareTab.tsx")
Backup-File $StylesFile

# =====================================================
# 1. FighterShowcaseVisual.tsx
# Fix hover cycling:
# - If manifest gallery exists, use ONLY those images
# - Limit to max 2 images
# - Do not add semantic-model imagePath to the rotation
# - If no gallery exists, fallback safely to imagePath or SVG
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterShowcaseVisual.tsx") -Content @'
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
'@

# =====================================================
# 2. HomeLanding.tsx
# Tighter cinematic hero for desktop
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "HomeLanding.tsx") -Content @'
import type { AppTab } from "./AppNavigation";

type HomeLandingProps = {
    onNavigate: (tab: AppTab) => void;
};

export function HomeLanding({ onNavigate }: HomeLandingProps) {
    return (
        <section className="mk-home mk-home-cinematic">
            <div className="mk-fire-layer" />
            <div className="mk-fire-layer mk-fire-layer--mid" />
            <div className="mk-fire-layer mk-fire-layer--front" />
            <div className="mk-ember-field" />

            <div className="mk-home-hero mk-home-hero-fit">
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
                        A premium Mortal Kombat analytics experience powered by
                        Microsoft Fabric, semantic models, DAX and Rayfin.
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

            <div className="mk-home-card-grid mk-home-card-grid-fit">
                <article>
                    <span>01</span>
                    <h3>Semantic Model</h3>
                    <p>Live KPIs and rankings from Fabric.</p>
                </article>
                <article>
                    <span>02</span>
                    <h3>Roster Slicers</h3>
                    <p>Filter by realm, element and combat style.</p>
                </article>
                <article>
                    <span>03</span>
                    <h3>Compare Mode</h3>
                    <p>Side-by-side fighter analytics comparison.</p>
                </article>
                <article>
                    <span>04</span>
                    <h3>Hover Renders</h3>
                    <p>Cycle through official fighter visuals on hover.</p>
                </article>
            </div>
        </section>
    );
}
'@

# =====================================================
# 3. CompareTab.tsx
# Remove Matchup Intelligence section
# Make page tighter and more professional
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "CompareTab.tsx") -Content @'
import { useEffect, useMemo, useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery } from "@/queries/kombat";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";

type FighterRecord = {
    fighterName: string;
    rosterGroup: string;
    realm: string;
    element: string;
    combatStyle: string;
    difficulty: string;
    matchesPlayed: number;
    wins: number;
    losses: number;
    winRate: number;
    totalXP: number;
    totalScore: number;
    totalKOs: number;
    fatalities: number;
    brutalities: number;
    damageEfficiency: number;
    rank: number;
    fullBodyImagePath?: string;
    primaryColor?: string;
    secondaryColor?: string;
};

function valueOf(row: Record<string, unknown>, aliases: string[], fallback: unknown = "") {
    for (const alias of aliases) {
        if (alias in row) {
            return row[alias];
        }
    }
    return fallback;
}

function toNumber(value: unknown, fallback = 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function formatNumber(value: number) {
    return value.toLocaleString();
}

function formatPercent(value: number) {
    return `${(value * 100).toFixed(1)}%`;
}

function buildRows(result: any): FighterRecord[] {
    if (!result || result.status !== "success") {
        return [];
    }

    const columns = result.table.columns.map((column: any) => column.name);
    const rows = result.table.rows ?? [];

    return rows.map((values: unknown[]) => {
        const rowObject: Record<string, unknown> = {};

        columns.forEach((columnName: string, index: number) => {
            rowObject[columnName] = values[index];
        });

        return {
            fighterName: String(valueOf(rowObject, ["fighterName", "FighterName", "dimfighter[FighterName]"], "")),
            rosterGroup: String(valueOf(rowObject, ["rosterGroup", "RosterGroup", "dimfighter[RosterGroup]"], "")),
            realm: String(valueOf(rowObject, ["realm", "Realm", "dimfighter[Realm]"], "")),
            element: String(valueOf(rowObject, ["element", "Element", "dimfighter[Element]"], "")),
            combatStyle: String(valueOf(rowObject, ["combatStyle", "CombatStyle", "dimfighter[CombatStyle]"], "")),
            difficulty: String(valueOf(rowObject, ["difficulty", "Difficulty", "dimfighter[Difficulty]"], "Medium")),
            matchesPlayed: toNumber(valueOf(rowObject, ["matchesPlayed", "Matches Played", "[Matches Played]"])),
            wins: toNumber(valueOf(rowObject, ["wins", "Wins", "[Wins]"])),
            losses: toNumber(valueOf(rowObject, ["losses", "Losses", "[Losses]"])),
            winRate: toNumber(valueOf(rowObject, ["winRate", "Win Rate", "[Win Rate]"])),
            totalXP: toNumber(valueOf(rowObject, ["totalXP", "Total XP", "[Total XP]"])),
            totalScore: toNumber(valueOf(rowObject, ["totalScore", "Total Score", "[Total Score]"])),
            totalKOs: toNumber(valueOf(rowObject, ["totalKOs", "Total KOs", "[Total KOs]"])),
            fatalities: toNumber(valueOf(rowObject, ["fatalities", "Fatalities", "[Fatalities]"])),
            brutalities: toNumber(valueOf(rowObject, ["brutalities", "Brutalities", "[Brutalities]"])),
            damageEfficiency: toNumber(valueOf(rowObject, ["damageEfficiency", "Damage Efficiency", "[Damage Efficiency]"])),
            rank: toNumber(valueOf(rowObject, ["rank", "Fighter Rank by Score", "[Fighter Rank by Score]"]), 0),
            fullBodyImagePath: String(valueOf(rowObject, ["fullBodyImagePath", "FullBodyImagePath", "dimfighter[FullBodyImagePath]"], "")),
            primaryColor: String(valueOf(rowObject, ["primaryColor", "PrimaryColor", "dimfighter[PrimaryColor]"], "#ff5a1f")),
            secondaryColor: String(valueOf(rowObject, ["secondaryColor", "SecondaryColor", "dimfighter[SecondaryColor]"], "#140706")),
        } as FighterRecord;
    });
}

function MetricRow({
    label,
    leftValue,
    rightValue,
    format = "number",
}: {
    label: string;
    leftValue: number;
    rightValue: number;
    format?: "number" | "percent" | "decimal";
}) {
    const max = Math.max(leftValue, rightValue, 1);
    const leftPct = (leftValue / max) * 100;
    const rightPct = (rightValue / max) * 100;

    const leftDisplay =
        format === "percent" ? formatPercent(leftValue) :
        format === "decimal" ? leftValue.toFixed(2) :
        formatNumber(leftValue);

    const rightDisplay =
        format === "percent" ? formatPercent(rightValue) :
        format === "decimal" ? rightValue.toFixed(2) :
        formatNumber(rightValue);

    return (
        <div className="mk-metric-row">
            <div className="mk-metric-side mk-metric-side--left">
                <strong>{leftDisplay}</strong>
                <div className="mk-metric-bar">
                    <span style={{ width: `${leftPct}%` }} />
                </div>
            </div>

            <div className="mk-metric-label">{label}</div>

            <div className="mk-metric-side mk-metric-side--right">
                <div className="mk-metric-bar">
                    <span style={{ width: `${rightPct}%` }} />
                </div>
                <strong>{rightDisplay}</strong>
            </div>
        </div>
    );
}

function CompareCard({
    fighter,
    side,
}: {
    fighter: FighterRecord;
    side: "left" | "right";
}) {
    return (
        <section className={`mk-compare-card mk-compare-card--${side}`}>
            <div className="mk-compare-card__hero">
                <div className="mk-compare-pill-row">
                    <span className="mk-pill">{fighter.rosterGroup}</span>
                    <span className="mk-pill">{fighter.element}</span>
                </div>

                <div className="mk-compare-visual">
                    <FighterShowcaseVisual
                        fighterName={fighter.fighterName}
                        imagePath={fighter.fullBodyImagePath}
                        isActive
                        className="mk-compare-visual__img"
                        fallbackClassName="mk-profile-image__fallback"
                        mode="compare"
                    />
                </div>

                <div className="mk-compare-card__content">
                    <span className="mk-eyebrow">{fighter.realm}</span>
                    <h3>{fighter.fighterName}</h3>
                    <p>
                        {fighter.combatStyle} · {fighter.difficulty}
                    </p>

                    <div className="mk-compare-mini-grid">
                        <div>
                            <span>XP</span>
                            <strong>{formatNumber(fighter.totalXP)}</strong>
                        </div>
                        <div>
                            <span>KOs</span>
                            <strong>{formatNumber(fighter.totalKOs)}</strong>
                        </div>
                        <div>
                            <span>Win</span>
                            <strong>{formatPercent(fighter.winRate)}</strong>
                        </div>
                        <div>
                            <span>Score</span>
                            <strong>{formatNumber(fighter.totalScore)}</strong>
                        </div>
                    </div>

                    <div className="mk-compare-card__footer">
                        <span>{formatNumber(fighter.matchesPlayed)} matches</span>
                        <span>Rank #{fighter.rank}</span>
                    </div>
                </div>
            </div>
        </section>
    );
}

export function CompareTab() {
    const { connection, query } = fighterGridQuery();
    const { data, isLoading, error } = useSemanticModelQuery({ connection, query });

    const fighters = useMemo(() => buildRows(data), [data]);
    const fighterNames = useMemo(() => fighters.map((fighter) => fighter.fighterName), [fighters]);

    const [fighterAName, setFighterAName] = useState("");
    const [fighterBName, setFighterBName] = useState("");

    useEffect(() => {
        if (fighterNames.length === 0) {
            return;
        }

        if (!fighterAName) {
            setFighterAName(fighterNames[0]);
        }

        if (!fighterBName) {
            setFighterBName(fighterNames[1] ?? fighterNames[0]);
        }
    }, [fighterNames, fighterAName, fighterBName]);

    const fighterA = fighters.find((fighter) => fighter.fighterName === fighterAName) ?? fighters[0];
    const fighterB = fighters.find((fighter) => fighter.fighterName === fighterBName) ?? fighters[1] ?? fighters[0];

    if (isLoading) {
        return <div className="mk-loading">Loading compare experience...</div>;
    }

    if (error || !data || (data as any)?.status === "error") {
        return <div className="mk-error">Unable to load compare experience.</div>;
    }

    if (!fighterA || !fighterB) {
        return <div className="mk-empty-state">No fighters available for comparison.</div>;
    }

    return (
        <section className="mk-compare-page">
            <div className="mk-compare-header">
                <span className="mk-eyebrow">Fighter A vs Fighter B</span>
                <h2>Compare Fighters</h2>
                <p>
                    Pick two fighters and compare live semantic-model metrics side by side.
                </p>
            </div>

            <div className="mk-compare-toolbar">
                <div className="mk-filter-group">
                    <label>Fighter A</label>
                    <select value={fighterAName} onChange={(event) => setFighterAName(event.target.value)}>
                        {fighters.map((fighter) => (
                            <option key={`a-${fighter.fighterName}`} value={fighter.fighterName}>
                                {fighter.fighterName}
                            </option>
                        ))}
                    </select>
                </div>

                <div className="mk-compare-vs">VS</div>

                <div className="mk-filter-group">
                    <label>Fighter B</label>
                    <select value={fighterBName} onChange={(event) => setFighterBName(event.target.value)}>
                        {fighters.map((fighter) => (
                            <option key={`b-${fighter.fighterName}`} value={fighter.fighterName}>
                                {fighter.fighterName}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="mk-compare-grid">
                <CompareCard fighter={fighterA} side="left" />
                <CompareCard fighter={fighterB} side="right" />
            </div>

            <div className="mk-panel mk-compare-metrics">
                <div className="mk-section-heading">
                    <h3>Combat Comparison</h3>
                    <p>Live side-by-side stat comparison.</p>
                </div>

                <MetricRow label="Matches Played" leftValue={fighterA.matchesPlayed} rightValue={fighterB.matchesPlayed} />
                <MetricRow label="Wins" leftValue={fighterA.wins} rightValue={fighterB.wins} />
                <MetricRow label="Win Rate" leftValue={fighterA.winRate} rightValue={fighterB.winRate} format="percent" />
                <MetricRow label="Total XP" leftValue={fighterA.totalXP} rightValue={fighterB.totalXP} />
                <MetricRow label="Total Score" leftValue={fighterA.totalScore} rightValue={fighterB.totalScore} />
                <MetricRow label="Total KOs" leftValue={fighterA.totalKOs} rightValue={fighterB.totalKOs} />
                <MetricRow label="Fatalities" leftValue={fighterA.fatalities} rightValue={fighterB.fatalities} />
                <MetricRow label="Brutalities" leftValue={fighterA.brutalities} rightValue={fighterB.brutalities} />
                <MetricRow label="Damage Efficiency" leftValue={fighterA.damageEfficiency} rightValue={fighterB.damageEfficiency} format="decimal" />
            </div>
        </section>
    );
}
'@

# =====================================================
# 4. CSS append
# =====================================================

Add-Content -Path $StylesFile -Value @'

/* =====================================================
   Step 17 - Final contest UI polish
   ===================================================== */

/* --- NAVBAR / BRAND --- */
.mk-top-nav {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 20px;
    min-height: 96px;
    padding: 14px 18px;
}

.mk-brand-logo {
    height: clamp(64px, 6vw, 92px);
    width: auto;
    object-fit: contain;
    filter: drop-shadow(0 0 18px rgba(215, 25, 32, 0.45));
}

.mk-nav-brand {
    display: inline-flex;
    align-items: center;
    gap: 14px;
}

/* --- HOME --- */
.mk-app--home {
    min-height: 100vh;
    overflow: hidden;
}

.mk-home-cinematic {
    position: relative;
    height: calc(100vh - 112px);
    min-height: 650px;
    overflow: hidden;
    display: grid;
    grid-template-rows: minmax(0, 1fr) auto;
    gap: 14px;
}

.mk-home-hero-fit {
    min-height: 0;
    height: 100%;
    grid-template-columns: minmax(0, 1fr) 280px;
    align-items: center;
    padding: clamp(20px, 3vw, 42px);
    position: relative;
    z-index: 2;
}

.mk-home-logo {
    max-width: clamp(180px, 20vw, 280px);
    width: 100%;
    height: auto;
    object-fit: contain;
    margin-bottom: 16px;
    filter:
        drop-shadow(0 0 22px rgba(215, 25, 32, 0.45))
        drop-shadow(0 18px 28px rgba(0, 0, 0, 0.48));
}

.mk-home-copy h1 {
    font-size: clamp(50px, 7vw, 100px);
    line-height: 0.95;
    margin: 8px 0 12px;
}

.mk-home-copy p {
    max-width: 620px;
    font-size: 17px;
    line-height: 1.5;
}

.mk-home-card-grid-fit {
    position: relative;
    z-index: 3;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 12px;
}

.mk-home-card-grid-fit article {
    min-height: 98px;
    padding: 14px;
    backdrop-filter: blur(12px);
}

.mk-home-card-grid-fit h3 {
    margin: 4px 0 4px;
    font-size: 15px;
}

.mk-home-card-grid-fit p {
    margin: 0;
    font-size: 12px;
}

/* --- FIRE / EMBERS --- */
.mk-fire-layer {
    position: absolute;
    left: -10%;
    right: -10%;
    bottom: -16%;
    height: 36%;
    pointer-events: none;
    z-index: 0;
    background:
        radial-gradient(circle at 10% 100%, rgba(255, 90, 31, 0.58), transparent 26%),
        radial-gradient(circle at 28% 100%, rgba(248, 184, 78, 0.44), transparent 28%),
        radial-gradient(circle at 50% 100%, rgba(215, 25, 32, 0.42), transparent 30%),
        radial-gradient(circle at 72% 100%, rgba(255, 90, 31, 0.44), transparent 28%),
        radial-gradient(circle at 90% 100%, rgba(248, 184, 78, 0.40), transparent 24%);
    filter: blur(12px);
    animation: mk-fire-rise 2.6s ease-in-out infinite alternate;
    opacity: 0.88;
}

.mk-fire-layer--mid {
    bottom: -18%;
    height: 30%;
    filter: blur(18px);
    animation-duration: 3.4s;
    opacity: 0.62;
}

.mk-fire-layer--front {
    bottom: -10%;
    height: 22%;
    filter: blur(8px);
    animation-duration: 1.9s;
    opacity: 0.95;
}

.mk-ember-field {
    position: absolute;
    inset: 0;
    pointer-events: none;
    z-index: 1;
    background:
        radial-gradient(circle at 8% 78%, rgba(248,184,78,0.26) 0 2px, transparent 3px),
        radial-gradient(circle at 18% 55%, rgba(255,90,31,0.18) 0 2px, transparent 3px),
        radial-gradient(circle at 32% 68%, rgba(248,184,78,0.20) 0 2px, transparent 3px),
        radial-gradient(circle at 55% 52%, rgba(215,25,32,0.18) 0 2px, transparent 3px),
        radial-gradient(circle at 74% 72%, rgba(248,184,78,0.18) 0 2px, transparent 3px),
        radial-gradient(circle at 86% 46%, rgba(255,90,31,0.16) 0 2px, transparent 3px);
    animation: mk-ember-float 9s linear infinite;
}

@keyframes mk-fire-rise {
    from {
        transform: translateY(12px) scaleX(1);
        opacity: 0.74;
    }
    to {
        transform: translateY(-8px) scaleX(1.03);
        opacity: 1;
    }
}

@keyframes mk-ember-float {
    from {
        transform: translateY(24px);
        opacity: 0.45;
    }
    to {
        transform: translateY(-16px);
        opacity: 0.85;
    }
}

/* --- ROSTER / CARDS --- */
.mk-fighter-grid {
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 16px;
}

.mk-fighter-card {
    min-height: 375px;
    border-radius: 22px;
    overflow: hidden;
}

.mk-fighter-card__image-wrap {
    inset: 42px 0 108px;
}

.mk-fighter-card__image {
    max-width: 92%;
    max-height: 92%;
    object-fit: contain;
    transition: transform 220ms ease, filter 220ms ease, opacity 220ms ease;
}

.mk-fighter-card.is-hovering .mk-fighter-card__image,
.mk-fighter-card.is-selected .mk-fighter-card__image {
    transform: translateZ(50px) scale(1.04) translateY(-3px);
}

.mk-fighter-card__content {
    left: 12px;
    right: 12px;
    bottom: 12px;
    padding: 12px;
    border-radius: 18px;
}

.mk-fighter-card__content h3 {
    font-size: 22px;
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

.mk-gallery-count {
    position: absolute;
    right: 10px;
    bottom: 10px;
    z-index: 5;
    padding: 4px 8px;
    border-radius: 999px;
    color: var(--mk-gold);
    background: rgba(0, 0, 0, 0.62);
    border: 1px solid rgba(248, 184, 78, 0.30);
    font-size: 11px;
    font-weight: 900;
}

/* --- COMPARE --- */
.mk-compare-page {
    display: grid;
    gap: 18px;
}

.mk-compare-header {
    padding: 22px 26px;
    border: 1px solid var(--mk-border);
    border-radius: 24px;
    background:
        radial-gradient(circle at left center, rgba(255, 90, 31, 0.18), transparent 30%),
        radial-gradient(circle at right center, rgba(215, 25, 32, 0.12), transparent 28%),
        rgba(12, 5, 4, 0.78);
}

.mk-compare-header h2 {
    margin: 8px 0 8px;
    font-size: clamp(48px, 6vw, 84px);
    line-height: 0.95;
}

.mk-compare-header p {
    margin: 0;
    font-size: 16px;
}

.mk-compare-toolbar {
    display: grid;
    grid-template-columns: 1fr 96px 1fr;
    gap: 14px;
    align-items: end;
    padding: 18px;
    border-radius: 22px;
    border: 1px solid var(--mk-border);
    background: rgba(12, 5, 4, 0.74);
}

.mk-compare-vs {
    height: 52px;
    display: grid;
    place-items: center;
    border-radius: 18px;
    font-size: 22px;
    font-weight: 1000;
    color: #140705;
    background: linear-gradient(135deg, var(--mk-gold), var(--mk-orange));
    box-shadow: 0 0 30px rgba(255, 90, 31, 0.24);
}

.mk-compare-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 20px;
}

.mk-compare-card {
    position: relative;
    min-height: 470px;
    border-radius: 24px;
    overflow: hidden;
    border: 1px solid var(--mk-border);
    background:
        radial-gradient(circle at top, rgba(255,255,255,0.08), transparent 28%),
        rgba(12, 5, 4, 0.82);
}

.mk-compare-card--left {
    background:
        radial-gradient(circle at 30% 20%, rgba(248,184,78,0.22), transparent 28%),
        rgba(12, 5, 4, 0.84);
}

.mk-compare-card--right {
    background:
        radial-gradient(circle at 70% 20%, rgba(215,25,32,0.22), transparent 28%),
        rgba(12, 5, 4, 0.84);
}

.mk-compare-card__hero {
    position: relative;
    min-height: 470px;
    padding: 18px;
}

.mk-compare-pill-row {
    position: absolute;
    inset: 18px 18px auto 18px;
    z-index: 4;
    display: flex;
    justify-content: space-between;
    gap: 8px;
}

.mk-compare-visual {
    position: absolute;
    inset: 54px 18px 150px 18px;
    display: grid;
    place-items: center;
    z-index: 1;
}

.mk-compare-visual__img {
    width: 100%;
    height: 100%;
    object-fit: contain;
    max-width: 95%;
    max-height: 100%;
    filter:
        drop-shadow(0 30px 42px rgba(0, 0, 0, 0.75))
        drop-shadow(0 0 28px rgba(255, 90, 31, 0.16));
}

.mk-compare-card__content {
    position: absolute;
    left: 18px;
    right: 18px;
    bottom: 18px;
    z-index: 3;
    padding: 16px;
    border-radius: 20px;
    background: linear-gradient(180deg, rgba(20, 10, 8, 0.46), rgba(20, 10, 8, 0.90));
    border: 1px solid rgba(255,255,255,0.10);
    backdrop-filter: blur(12px);
}

.mk-compare-card__content h3 {
    margin: 6px 0 4px;
    font-size: 22px;
}

.mk-compare-card__content p {
    margin: 0 0 12px;
    font-size: 13px;
}

.mk-compare-mini-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 8px;
}

.mk-compare-mini-grid div {
    padding: 10px;
    border-radius: 14px;
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(255,255,255,0.08);
}

.mk-compare-mini-grid span {
    display: block;
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    opacity: 0.72;
    margin-bottom: 4px;
}

.mk-compare-mini-grid strong {
    font-size: 14px;
}

.mk-compare-card__footer {
    margin-top: 12px;
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    font-weight: 700;
    color: var(--mk-gold);
}

.mk-compare-metrics {
    padding: 20px;
}

.mk-section-heading h3 {
    margin: 0 0 4px;
    font-size: 24px;
}

.mk-section-heading p {
    margin: 0 0 14px;
    font-size: 13px;
    color: var(--mk-muted);
}

.mk-metric-row {
    display: grid;
    grid-template-columns: 1fr 170px 1fr;
    gap: 12px;
    align-items: center;
    padding: 10px 0;
    border-bottom: 1px solid rgba(255,255,255,0.06);
}

.mk-metric-side {
    display: grid;
    align-items: center;
    gap: 8px;
}

.mk-metric-side--left {
    grid-template-columns: 88px 1fr;
}

.mk-metric-side--right {
    grid-template-columns: 1fr 88px;
}

.mk-metric-side strong {
    font-size: 13px;
}

.mk-metric-label {
    text-align: center;
    font-size: 12px;
    font-weight: 800;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--mk-gold);
}

.mk-metric-bar {
    height: 10px;
    border-radius: 999px;
    overflow: hidden;
    background: rgba(255,255,255,0.08);
    border: 1px solid rgba(255,255,255,0.05);
}

.mk-metric-bar span {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(90deg, var(--mk-orange), var(--mk-gold));
}

/* --- RESPONSIVE --- */
@media (max-width: 1280px) {
    .mk-home-card-grid-fit {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .mk-compare-grid {
        grid-template-columns: 1fr;
    }

    .mk-compare-toolbar {
        grid-template-columns: 1fr;
    }

    .mk-compare-vs {
        height: 46px;
    }
}

@media (max-width: 980px) {
    .mk-top-nav {
        grid-template-columns: 1fr;
        gap: 12px;
    }

    .mk-home-cinematic {
        height: auto;
        min-height: 0;
        overflow: visible;
    }

    .mk-app--home {
        overflow: auto;
    }

    .mk-home-hero-fit {
        grid-template-columns: 1fr;
        height: auto;
    }

    .mk-home-card-grid-fit {
        grid-template-columns: 1fr;
    }

    .mk-compare-mini-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .mk-metric-row {
        grid-template-columns: 1fr;
    }
}
'@

Write-Host ""
Write-Host "========================================"
Write-Host "Final contest UI polish applied."
Write-Host "========================================"
Write-Host "Next:"
Write-Host "cd $AppRoot"
Write-Host "npm run build:fabric"
Write-Host "npm run dev"
