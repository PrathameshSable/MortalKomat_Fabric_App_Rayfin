# =====================================================
# Step 8 - Create React UI Components
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"

$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"
$StylesFolder = Join-Path $AppRoot "src\styles"
$AppFile = Join-Path $AppRoot "src\App.tsx"

Write-Host "========================================"
Write-Host "Step 8 - Create React UI components"
Write-Host "========================================"
Write-Host "AppRoot: $AppRoot"
Write-Host "ComponentsFolder: $ComponentsFolder"
Write-Host "StylesFolder: $StylesFolder"
Write-Host ""

if (-not (Test-Path $AppRoot)) {
    throw "Rayfin app folder not found: $AppRoot"
}

New-Item -Path $ComponentsFolder -ItemType Directory -Force | Out-Null
New-Item -Path $StylesFolder -ItemType Directory -Force | Out-Null

if (Test-Path $AppFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Copy-Item $AppFile "$AppFile.backup_$timestamp" -Force
    Write-Host "Backed up App.tsx to App.tsx.backup_$timestamp"
}

function Write-TextFile {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    $folder = Split-Path $Path -Parent
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "WROTE: $Path"
}

# =====================================================
# CSS THEME
# =====================================================

Write-TextFile -Path (Join-Path $StylesFolder "mk-theme.css") -Content @'
:root {
    --mk-bg: #050302;
    --mk-bg-2: #120705;
    --mk-panel: rgba(18, 12, 9, 0.86);
    --mk-panel-strong: rgba(34, 20, 15, 0.94);
    --mk-border: rgba(255, 111, 28, 0.28);
    --mk-text: #fff4e6;
    --mk-muted: #b9a798;
    --mk-gold: #f8b84e;
    --mk-red: #d71920;
    --mk-orange: #ff5a1f;
    --mk-ice: #62c8ff;
    --mk-green: #39ff88;
    --mk-purple: #a855f7;
}

.mk-app {
    min-height: 100vh;
    color: var(--mk-text);
    background:
        radial-gradient(circle at 15% 10%, rgba(255, 92, 31, 0.22), transparent 32%),
        radial-gradient(circle at 88% 8%, rgba(215, 25, 32, 0.18), transparent 28%),
        linear-gradient(135deg, #040201 0%, #120705 45%, #050302 100%);
    padding: 32px;
    overflow-x: hidden;
}

.mk-hero {
    position: relative;
    min-height: 340px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 32px;
    margin-bottom: 28px;
    padding: 44px;
    border-radius: 34px;
    background:
        radial-gradient(circle at 18% 18%, rgba(255, 90, 31, 0.24), transparent 32%),
        linear-gradient(145deg, rgba(37, 17, 10, 0.96), rgba(5, 3, 2, 0.98));
    border: 1px solid rgba(255, 111, 28, 0.34);
    box-shadow:
        0 36px 100px rgba(0, 0, 0, 0.68),
        inset 0 1px 0 rgba(255, 255, 255, 0.08);
    overflow: hidden;
}

.mk-hero::before {
    content: "";
    position: absolute;
    inset: -40%;
    background:
        conic-gradient(from 45deg, transparent, rgba(255, 90, 31, 0.16), transparent, rgba(215, 25, 32, 0.12), transparent);
    animation: mk-spin 18s linear infinite;
    filter: blur(18px);
}

.mk-hero-content,
.mk-hero-badge {
    position: relative;
    z-index: 2;
}

.mk-hero h1 {
    max-width: 920px;
    margin: 0;
    font-size: clamp(52px, 7vw, 108px);
    line-height: 0.88;
    letter-spacing: -0.07em;
    text-transform: uppercase;
    color: #fff4e6;
    text-shadow:
        0 0 26px rgba(255, 90, 31, 0.62),
        0 18px 48px rgba(0, 0, 0, 0.78);
}

.mk-hero p {
    max-width: 760px;
    margin-top: 22px;
    color: var(--mk-muted);
    font-size: 19px;
    line-height: 1.6;
}

.mk-eyebrow {
    display: inline-flex;
    margin-bottom: 14px;
    color: var(--mk-gold);
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.18em;
    text-transform: uppercase;
}

.mk-hero-badge {
    min-width: 190px;
    width: 190px;
    height: 190px;
    display: grid;
    place-items: center;
    border-radius: 999px;
    background:
        radial-gradient(circle, #ffd36a, #ff5a1f 46%, rgba(215, 25, 32, 0.42) 72%, transparent);
    box-shadow:
        0 0 90px rgba(255, 90, 31, 0.62),
        inset 0 0 42px rgba(255, 255, 255, 0.32);
    transform: perspective(900px) rotateY(-18deg) rotateX(8deg);
}

.mk-hero-badge span {
    color: #160504;
    font-size: 58px;
    font-weight: 1000;
}

.mk-section-header {
    margin: 34px 0 20px;
}

.mk-section-header span {
    color: var(--mk-gold);
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.18em;
    text-transform: uppercase;
}

.mk-section-header h2 {
    margin: 8px 0 8px;
    font-size: 36px;
    text-transform: uppercase;
}

.mk-section-header p {
    max-width: 860px;
    color: var(--mk-muted);
    font-size: 16px;
    line-height: 1.6;
}

.mk-kpi-grid {
    display: grid;
    grid-template-columns: repeat(6, minmax(0, 1fr));
    gap: 16px;
    margin-bottom: 28px;
}

.mk-kpi-card,
.mk-panel {
    padding: 18px;
    border-radius: 22px;
    background:
        radial-gradient(circle at top left, rgba(255, 90, 31, 0.18), transparent 34%),
        linear-gradient(145deg, rgba(35, 24, 18, 0.95), rgba(8, 6, 5, 0.95));
    border: 1px solid rgba(255, 90, 31, 0.28);
    box-shadow:
        0 24px 60px rgba(0, 0, 0, 0.45),
        inset 0 1px 0 rgba(255, 255, 255, 0.08);
}

.mk-kpi-card span {
    display: block;
    color: var(--mk-muted);
    font-size: 11px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
}

.mk-kpi-card strong {
    display: block;
    margin-top: 8px;
    font-size: 26px;
    color: #fff4e6;
}

.mk-layout-grid {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: 24px;
}

.mk-fighter-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
    gap: 24px;
    perspective: 1200px;
}

.mk-fighter-card {
    position: relative;
    min-height: 500px;
    overflow: hidden;
    border: 1px solid var(--mk-border);
    border-radius: 28px;
    padding: 0;
    text-align: left;
    color: var(--mk-text);
    background:
        radial-gradient(circle at 50% 8%, color-mix(in srgb, var(--fighter-primary) 24%, transparent), transparent 40%),
        linear-gradient(145deg, rgba(40, 22, 16, 0.98), rgba(7, 5, 4, 0.98));
    box-shadow:
        0 28px 80px rgba(0, 0, 0, 0.62),
        inset 0 1px 0 rgba(255, 255, 255, 0.08),
        0 0 40px color-mix(in srgb, var(--fighter-primary) 22%, transparent);
    transform-style: preserve-3d;
    cursor: pointer;
    transition: transform 220ms ease, border-color 220ms ease, box-shadow 220ms ease;
}

.mk-fighter-card:hover {
    transform: perspective(900px) rotateX(5deg) rotateY(-5deg) translateY(-8px);
    border-color: rgba(248, 184, 78, 0.62);
}

.mk-fighter-card__glow {
    position: absolute;
    inset: -30%;
    background:
        conic-gradient(
            from 90deg,
            transparent,
            color-mix(in srgb, var(--fighter-primary) 35%, transparent),
            transparent,
            color-mix(in srgb, var(--fighter-secondary) 35%, transparent),
            transparent
        );
    opacity: 0.35;
    filter: blur(24px);
    animation: mk-spin 12s linear infinite;
}

@keyframes mk-spin {
    to {
        transform: rotate(360deg);
    }
}

.mk-fighter-card__meta {
    position: absolute;
    z-index: 4;
    top: 18px;
    left: 18px;
    right: 18px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    transform: translateZ(48px);
}

.mk-pill {
    padding: 8px 12px;
    border-radius: 999px;
    background: rgba(0, 0, 0, 0.48);
    border: 1px solid rgba(255, 255, 255, 0.12);
    color: var(--mk-gold);
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}

.mk-fighter-card__image-wrap {
    position: absolute;
    inset: 40px 0 132px;
    display: grid;
    place-items: center;
    transform: translateZ(70px);
}

.mk-fighter-card__image {
    max-width: 112%;
    max-height: 112%;
    object-fit: contain;
    filter:
        drop-shadow(0 32px 42px rgba(0, 0, 0, 0.78))
        drop-shadow(0 0 28px color-mix(in srgb, var(--fighter-primary) 42%, transparent));
}

.mk-fighter-card__fallback {
    width: 170px;
    height: 170px;
    border-radius: 999px;
    display: grid;
    place-items: center;
    color: #160504;
    font-size: 54px;
    font-weight: 1000;
    background: radial-gradient(circle, var(--fighter-primary), rgba(255, 90, 31, 0.3));
    box-shadow: 0 0 70px color-mix(in srgb, var(--fighter-primary) 50%, transparent);
}

.mk-fighter-card__content {
    position: absolute;
    z-index: 5;
    left: 18px;
    right: 18px;
    bottom: 18px;
    padding: 18px;
    border-radius: 22px;
    background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.03)),
        rgba(8, 6, 5, 0.74);
    border: 1px solid rgba(255, 255, 255, 0.12);
    backdrop-filter: blur(18px);
    transform: translateZ(96px);
}

.mk-fighter-card__realm {
    color: var(--mk-gold);
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 0.14em;
    text-transform: uppercase;
}

.mk-fighter-card__content h3 {
    margin: 6px 0 0;
    font-size: 30px;
    line-height: 1;
    letter-spacing: -0.04em;
    text-transform: uppercase;
    text-shadow: 0 0 18px color-mix(in srgb, var(--fighter-primary) 50%, transparent);
}

.mk-fighter-card__content p {
    margin: 6px 0 16px;
    color: var(--mk-muted);
}

.mk-fighter-card__stats {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 8px;
}

.mk-fighter-card__stats div,
.mk-mini-stat {
    padding: 10px;
    border-radius: 14px;
    background: rgba(255, 255, 255, 0.045);
    border: 1px solid rgba(255, 255, 255, 0.07);
}

.mk-fighter-card__stats span,
.mk-mini-stat span {
    display: block;
    color: var(--mk-muted);
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.08em;
}

.mk-fighter-card__stats strong,
.mk-mini-stat strong {
    display: block;
    margin-top: 4px;
    font-size: 14px;
}

.mk-fighter-card__footer {
    display: flex;
    justify-content: space-between;
    margin-top: 14px;
    color: var(--mk-gold);
    font-size: 12px;
    font-weight: 700;
}

.mk-profile-grid {
    display: grid;
    grid-template-columns: 280px minmax(0, 1fr);
    gap: 22px;
    align-items: stretch;
}

.mk-profile-image {
    min-height: 320px;
    border-radius: 22px;
    display: grid;
    place-items: center;
    background:
        radial-gradient(circle at center, rgba(255, 90, 31, 0.18), transparent 52%),
        rgba(0, 0, 0, 0.28);
    overflow: hidden;
}

.mk-profile-image img {
    max-width: 120%;
    max-height: 340px;
    object-fit: contain;
    filter: drop-shadow(0 36px 42px rgba(0, 0, 0, 0.72));
}

.mk-mini-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 12px;
}

.mk-table {
    width: 100%;
    border-collapse: collapse;
    overflow: hidden;
    border-radius: 18px;
}

.mk-table th,
.mk-table td {
    padding: 14px 12px;
    text-align: left;
    border-bottom: 1px solid rgba(255, 255, 255, 0.07);
}

.mk-table th {
    color: var(--mk-gold);
    font-size: 11px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    background: rgba(255, 90, 31, 0.08);
}

.mk-table td {
    color: var(--mk-text);
    font-size: 14px;
}

.mk-two-column {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 24px;
}

.mk-loading,
.mk-error {
    padding: 24px;
    border-radius: 22px;
    background: rgba(12, 7, 5, 0.82);
    border: 1px solid rgba(255, 111, 28, 0.28);
    color: var(--mk-gold);
}

@media (max-width: 1250px) {
    .mk-kpi-grid {
        grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    .mk-two-column {
        grid-template-columns: 1fr;
    }
}

@media (max-width: 860px) {
    .mk-app {
        padding: 16px;
    }

    .mk-hero {
        flex-direction: column;
        align-items: flex-start;
    }

    .mk-kpi-grid {
        grid-template-columns: 1fr;
    }

    .mk-profile-grid {
        grid-template-columns: 1fr;
    }

    .mk-mini-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}
'@

# =====================================================
# TYPES
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "types.ts") -Content @'
export type FighterRow = {
    fighterName: string;
    rosterGroup: string;
    realm: string;
    element: string;
    combatStyle: string;
    alignment: string;
    difficulty: string;
    primaryColor: string;
    secondaryColor: string;
    portraitImagePath: string;
    fullBodyImagePath: string;
    cardBackgroundPath: string;
    model3DPath: string;
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
};
'@

# =====================================================
# HERO
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "MkHero.tsx") -Content @'
export function MkHero() {
    return (
        <section className="mk-hero">
            <div className="mk-hero-content">
                <span className="mk-eyebrow">Fabric + Rayfin Data App</span>
                <h1>Mortal Kombat Arena Intelligence</h1>
                <p>
                    A cinematic fighting-game analytics experience powered by Microsoft Fabric,
                    a semantic model, DAX queries, and a Rayfin-hosted React app.
                </p>
            </div>

            <div className="mk-hero-badge">
                <span>KO</span>
            </div>
        </section>
    );
}
'@

# =====================================================
# KPI SUMMARY
# =====================================================

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
        ["Total Matches", formatNumber(row[0])],
        ["Total XP", formatNumber(row[5])],
        ["Total Score", formatNumber(row[7])],
        ["KOs", formatNumber(row[9])],
        ["Win Rate", formatPercent(row[4])],
        ["Fatalities", formatNumber(row[11])],
    ];

    return (
        <section className="mk-kpi-grid">
            {cards.map(([label, value]) => (
                <div className="mk-kpi-card" key={label}>
                    <span>{label}</span>
                    <strong>{value}</strong>
                </div>
            ))}
        </section>
    );
}
'@

# =====================================================
# FIGHTER CARD
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterCard3D.tsx") -Content @'
import type { CSSProperties } from "react";
import type { FighterRow } from "./types";

type FighterCard3DProps = {
    fighter: FighterRow;
    onSelect: () => void;
};

function initials(name: string) {
    return name
        .split(" ")
        .map((part) => part[0])
        .join("")
        .slice(0, 2)
        .toUpperCase();
}

export function FighterCard3D({ fighter, onSelect }: FighterCard3DProps) {
    const style = {
        "--fighter-primary": fighter.primaryColor || "#ff5a1f",
        "--fighter-secondary": fighter.secondaryColor || "#120705",
    } as CSSProperties;

    return (
        <button className="mk-fighter-card" onClick={onSelect} style={style}>
            <div className="mk-fighter-card__glow" />

            <div className="mk-fighter-card__meta">
                <span className="mk-pill">{fighter.rosterGroup}</span>
                <strong className="mk-pill">{fighter.element}</strong>
            </div>

            <div className="mk-fighter-card__image-wrap">
                {fighter.fullBodyImagePath ? (
                    <img
                        src={fighter.fullBodyImagePath}
                        alt={fighter.fighterName}
                        className="mk-fighter-card__image"
                        loading="lazy"
                        onError={(event) => {
                            event.currentTarget.style.display = "none";
                        }}
                    />
                ) : null}

                <div className="mk-fighter-card__fallback">
                    {initials(fighter.fighterName)}
                </div>
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
                    <span>View profile</span>
                </div>
            </div>
        </button>
    );
}
'@

# =====================================================
# FIGHTER PROFILE PANEL
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterProfilePanel.tsx") -Content @'
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterProfileQuery } from "@/queries/kombat";
import type { FighterRow } from "./types";

type FighterProfilePanelProps = {
    fighter: FighterRow;
};

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function FighterProfilePanel({ fighter }: FighterProfilePanelProps) {
    const { connection, query } = fighterProfileQuery(fighter.fighterName);

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;
    const row = result?.status === "success" ? result.table.rows[0] ?? [] : [];

    return (
        <section className="mk-panel">
            <div className="mk-section-header" style={{ marginTop: 0 }}>
                <span>Selected Fighter</span>
                <h2>{fighter.fighterName}</h2>
                <p>
                    {fighter.realm} · {fighter.element} · {fighter.combatStyle} · Rank #
                    {fighter.rank}
                </p>
            </div>

            <div className="mk-profile-grid">
                <div className="mk-profile-image">
                    {fighter.fullBodyImagePath ? (
                        <img
                            src={fighter.fullBodyImagePath}
                            alt={fighter.fighterName}
                            onError={(event) => {
                                event.currentTarget.style.display = "none";
                            }}
                        />
                    ) : (
                        <strong>{fighter.fighterName}</strong>
                    )}
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
        </section>
    );
}
'@

# =====================================================
# FIGHTER GRID
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterGrid.tsx") -Content @'
import { useMemo, useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery } from "@/queries/kombat";
import { FighterCard3D } from "./FighterCard3D";
import { FighterProfilePanel } from "./FighterProfilePanel";
import type { FighterRow } from "./types";

function mapFighterRow(row: unknown[]): FighterRow {
    return {
        fighterName: String(row[0] ?? ""),
        rosterGroup: String(row[1] ?? ""),
        realm: String(row[2] ?? ""),
        element: String(row[3] ?? ""),
        combatStyle: String(row[4] ?? ""),
        alignment: String(row[5] ?? ""),
        difficulty: String(row[6] ?? ""),
        primaryColor: String(row[7] ?? "#ff5a1f"),
        secondaryColor: String(row[8] ?? "#120705"),
        portraitImagePath: String(row[9] ?? ""),
        fullBodyImagePath: String(row[10] ?? ""),
        cardBackgroundPath: String(row[11] ?? ""),
        model3DPath: String(row[12] ?? ""),
        matchesPlayed: Number(row[13] ?? 0),
        wins: Number(row[14] ?? 0),
        losses: Number(row[15] ?? 0),
        winRate: Number(row[16] ?? 0),
        totalXP: Number(row[17] ?? 0),
        totalScore: Number(row[18] ?? 0),
        totalKOs: Number(row[19] ?? 0),
        fatalities: Number(row[20] ?? 0),
        brutalities: Number(row[21] ?? 0),
        damageEfficiency: Number(row[22] ?? 0),
        rank: Number(row[23] ?? 0),
    };
}

export function FighterGrid() {
    const [selectedFighter, setSelectedFighter] = useState<FighterRow | null>(null);

    const { connection, query } = fighterGridQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;

    const fighters = useMemo(() => {
        if (!result || result.status !== "success") {
            return [];
        }

        return (result.table.rows as unknown[][]).map(mapFighterRow);
    }, [result]);

    if (isLoading) {
        return <div className="mk-loading">Loading fighter roster...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load fighter roster.</div>;
    }

    return (
        <section>
            <div className="mk-section-header">
                <span>Choose Your Fighter</span>
                <h2>Roster Intelligence</h2>
                <p>
                    Select a fighter to inspect wins, losses, XP, KOs, fatalities, damage
                    efficiency, and rank — all coming from your Fabric semantic model.
                </p>
            </div>

            {selectedFighter ? (
                <div style={{ marginBottom: 24 }}>
                    <FighterProfilePanel fighter={selectedFighter} />
                </div>
            ) : null}

            <div className="mk-fighter-grid">
                {fighters.map((fighter) => (
                    <FighterCard3D
                        key={fighter.fighterName}
                        fighter={fighter}
                        onSelect={() => setSelectedFighter(fighter)}
                    />
                ))}
            </div>
        </section>
    );
}
'@

# =====================================================
# ARENA INSIGHTS
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "ArenaInsights.tsx") -Content @'
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { arenaInsightsQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function ArenaInsights() {
    const { connection, query } = arenaInsightsQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;

    if (isLoading) {
        return <div className="mk-loading">Loading arena insights...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load arena insights.</div>;
    }

    if (!result || result.status !== "success") {
        return null;
    }

    const rows = result.table.rows as unknown[][];

    return (
        <section className="mk-panel">
            <div className="mk-section-header" style={{ marginTop: 0 }}>
                <span>Arena Intelligence</span>
                <h2>Battlefield Performance</h2>
            </div>

            <table className="mk-table">
                <thead>
                    <tr>
                        <th>Arena</th>
                        <th>Realm</th>
                        <th>Hazard</th>
                        <th>Matches</th>
                        <th>Win Rate</th>
                        <th>KOs</th>
                    </tr>
                </thead>
                <tbody>
                    {rows.slice(0, 8).map((row) => (
                        <tr key={String(row[0])}>
                            <td>{String(row[0])}</td>
                            <td>{String(row[1])}</td>
                            <td>{String(row[2])}</td>
                            <td>{formatNumber(row[4])}</td>
                            <td>{formatPercent(row[5])}</td>
                            <td>{formatNumber(row[6])}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </section>
    );
}
'@

# =====================================================
# KAMEO INSIGHTS
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "KameoInsights.tsx") -Content @'
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { kameoInsightsQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

export function KameoInsights() {
    const { connection, query } = kameoInsightsQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;

    if (isLoading) {
        return <div className="mk-loading">Loading Kameo insights...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load Kameo insights.</div>;
    }

    if (!result || result.status !== "success") {
        return null;
    }

    const rows = result.table.rows as unknown[][];

    return (
        <section className="mk-panel">
            <div className="mk-section-header" style={{ marginTop: 0 }}>
                <span>Kameo Intelligence</span>
                <h2>Best Assist Fighters</h2>
            </div>

            <table className="mk-table">
                <thead>
                    <tr>
                        <th>Kameo</th>
                        <th>Group</th>
                        <th>Element</th>
                        <th>Assist</th>
                        <th>Matches</th>
                        <th>Win Rate</th>
                    </tr>
                </thead>
                <tbody>
                    {rows.slice(0, 10).map((row) => (
                        <tr key={String(row[0])}>
                            <td>{String(row[0])}</td>
                            <td>{String(row[1])}</td>
                            <td>{String(row[2])}</td>
                            <td>{String(row[3])}</td>
                            <td>{formatNumber(row[5])}</td>
                            <td>{formatPercent(row[7])}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </section>
    );
}
'@

# =====================================================
# APP SHELL
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "MkAppShell.tsx") -Content @'
import { MkHero } from "./MkHero";
import { KpiSummary } from "./KpiSummary";
import { FighterGrid } from "./FighterGrid";
import { ArenaInsights } from "./ArenaInsights";
import { KameoInsights } from "./KameoInsights";

export function MkAppShell() {
    return (
        <main className="mk-app">
            <MkHero />
            <KpiSummary />

            <div className="mk-layout-grid">
                <FighterGrid />

                <div className="mk-two-column">
                    <ArenaInsights />
                    <KameoInsights />
                </div>
            </div>
        </main>
    );
}
'@

# =====================================================
# APP.TSX
# =====================================================

Write-TextFile -Path $AppFile -Content @'
import "@/styles/mk-theme.css";
import { MkAppShell } from "@/components/kombat/MkAppShell";

function App() {
    return <MkAppShell />;
}

export default App;
'@

Write-Host ""
Write-Host "========================================"
Write-Host "Step 8 React UI files created."
Write-Host "========================================"
Write-Host "Next command:"
Write-Host "cd $AppRoot"
Write-Host "npm run build:fabric"