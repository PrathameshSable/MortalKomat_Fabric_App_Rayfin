# =====================================================
# Step 18 - Final Responsive Cinematic UI Patch
# Mortal Kombat Arena Intelligence
# =====================================================
# Fixes:
# - Light mode command center KPI visibility
# - Home page browser fit + cinematic animated background
# - Optional arena background image support
# - Native white dropdown issue in Compare via custom fighter picker
# - Compare page image fitting and less scrolling
# - Responsive tile/card behavior
# =====================================================

$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\Projects\mk-arena-intelligence"
$AppRoot = Join-Path $ProjectRoot "mortal-kombat-arena-intelligence"
$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"
$StylesFile = Join-Path $AppRoot "src\styles\mk-theme.css"

$IncomingBackgrounds = Join-Path $ProjectRoot "incoming-assets\backgrounds"
$PublicBackgrounds = Join-Path $AppRoot "public\assets\backgrounds"

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

    $folder = Split-Path $Path -Parent

    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "WROTE: $Path"
}

Write-Host "========================================"
Write-Host "Step 18 - Final Responsive Cinematic UI Patch"
Write-Host "========================================"
Write-Host "AppRoot: $AppRoot"
Write-Host "ComponentsFolder: $ComponentsFolder"
Write-Host "StylesFile: $StylesFile"
Write-Host ""

if (-not (Test-Path $AppRoot)) {
    throw "App root not found: $AppRoot"
}

if (-not (Test-Path $ComponentsFolder)) {
    throw "Components folder not found: $ComponentsFolder"
}

if (-not (Test-Path $StylesFile)) {
    throw "Styles file not found: $StylesFile"
}

# =====================================================
# Optional background image copy
# =====================================================
New-Item -Path $PublicBackgrounds -ItemType Directory -Force | Out-Null

if (Test-Path $IncomingBackgrounds) {
    $bgFile = Get-ChildItem -Path $IncomingBackgrounds -File -Include *.png,*.jpg,*.jpeg,*.webp -Recurse -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First 1

    if ($bgFile) {
        $ext = $bgFile.Extension.ToLowerInvariant()
        $dest = Join-Path $PublicBackgrounds "home-arena$ext"
        Copy-Item $bgFile.FullName $dest -Force
        Write-Host "COPIED HOME BACKGROUND: $($bgFile.FullName) -> $dest"
    }
    else {
        Write-Host "No background image found in $IncomingBackgrounds. CSS fallback gradients will be used."
    }
}
else {
    Write-Host "Incoming background folder not found: $IncomingBackgrounds"
    Write-Host "Create it and place your arena image there if you want a realistic background."
}

# =====================================================
# Backups
# =====================================================
Backup-File (Join-Path $ComponentsFolder "HomeLanding.tsx")
Backup-File (Join-Path $ComponentsFolder "CompareTab.tsx")
Backup-File (Join-Path $ComponentsFolder "FighterPicker.tsx")
Backup-File $StylesFile

# =====================================================
# FighterPicker.tsx - custom dropdown to avoid native white select
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterPicker.tsx") -Content @'
import { useEffect, useMemo, useRef, useState } from "react";

type FighterPickerProps = {
    label: string;
    value: string;
    options: string[];
    onChange: (value: string) => void;
};

export function FighterPicker({ label, value, options, onChange }: FighterPickerProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [search, setSearch] = useState("");
    const rootRef = useRef<HTMLDivElement | null>(null);

    const filteredOptions = useMemo(() => {
        const searchText = search.trim().toLowerCase();

        if (!searchText) {
            return options;
        }

        return options.filter((option) => option.toLowerCase().includes(searchText));
    }, [options, search]);

    useEffect(() => {
        function handlePointerDown(event: PointerEvent) {
            if (!rootRef.current) {
                return;
            }

            if (!rootRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        }

        window.addEventListener("pointerdown", handlePointerDown);

        return () => {
            window.removeEventListener("pointerdown", handlePointerDown);
        };
    }, []);

    return (
        <div className="mk-fighter-picker" ref={rootRef}>
            <label>{label}</label>

            <button
                type="button"
                className="mk-fighter-picker__button"
                onClick={() => setIsOpen((current) => !current)}
            >
                <span>{value || "Select fighter"}</span>
                <strong>⌄</strong>
            </button>

            {isOpen ? (
                <div className="mk-fighter-picker__menu">
                    <input
                        value={search}
                        onChange={(event) => setSearch(event.target.value)}
                        placeholder="Search fighter..."
                        autoFocus
                    />

                    <div className="mk-fighter-picker__list">
                        {filteredOptions.map((option) => (
                            <button
                                key={option}
                                type="button"
                                className={option === value ? "is-selected" : ""}
                                onClick={() => {
                                    onChange(option);
                                    setIsOpen(false);
                                    setSearch("");
                                }}
                            >
                                {option}
                            </button>
                        ))}
                    </div>
                </div>
            ) : null}
        </div>
    );
}
'@

# =====================================================
# HomeLanding.tsx - cinematic background with fit
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "HomeLanding.tsx") -Content @'
import type { AppTab } from "./AppNavigation";

type HomeLandingProps = {
    onNavigate: (tab: AppTab) => void;
};

export function HomeLanding({ onNavigate }: HomeLandingProps) {
    return (
        <section className="mk-home mk-home-cinematic">
            <div className="mk-cinematic-bg" />
            <div className="mk-cinematic-vignette" />
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
                        A cinematic analytics arena powered by Microsoft Fabric,
                        semantic models, DAX and Rayfin.
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
                    <p>Filter by realm, element and style.</p>
                </article>
                <article>
                    <span>03</span>
                    <h3>Compare Mode</h3>
                    <p>Side-by-side fighter analytics.</p>
                </article>
                <article>
                    <span>04</span>
                    <h3>Hover Renders</h3>
                    <p>Cycle official fighter visuals.</p>
                </article>
            </div>
        </section>
    );
}
'@

# =====================================================
# CompareTab.tsx - custom dropdown + compact compare layout
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "CompareTab.tsx") -Content @'
import { useEffect, useMemo, useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery } from "@/queries/kombat";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";
import { FighterPicker } from "./FighterPicker";

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
        };
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
    const leftPct = Math.max((leftValue / max) * 100, 4);
    const rightPct = Math.max((rightValue / max) * 100, 4);

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

function CompareCard({ fighter, side }: { fighter: FighterRecord; side: "left" | "right" }) {
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
                    <p>{fighter.combatStyle} · {fighter.difficulty}</p>

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
                <p>Pick two fighters and compare live semantic-model metrics side by side.</p>
            </div>

            <div className="mk-compare-toolbar">
                <FighterPicker
                    label="Fighter A"
                    value={fighterAName}
                    options={fighterNames}
                    onChange={setFighterAName}
                />

                <div className="mk-compare-vs">VS</div>

                <FighterPicker
                    label="Fighter B"
                    value={fighterBName}
                    options={fighterNames}
                    onChange={setFighterBName}
                />
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
# CSS patch
# =====================================================

$currentCss = Get-Content -Path $StylesFile -Raw

if ($currentCss -notlike "*Step 18 - Final responsive cinematic corrections*") {
    Add-Content -Path $StylesFile -Value @'

/* =====================================================
   Step 18 - Final responsive cinematic corrections
   ===================================================== */

/* ---------- Light mode readability ---------- */

.mk-app[data-theme="light"] {
    color-scheme: light;
    background:
        radial-gradient(circle at 12% 10%, rgba(234, 88, 12, 0.16), transparent 32%),
        radial-gradient(circle at 88% 8%, rgba(185, 28, 28, 0.10), transparent 28%),
        linear-gradient(135deg, #fff7ed 0%, #f8e7d8 52%, #fff1df 100%);
}

.mk-app[data-theme="light"] .mk-tab-hero,
.mk-app[data-theme="light"] .mk-compare-header,
.mk-app[data-theme="light"] .mk-panel {
    background:
        radial-gradient(circle at 18% 12%, rgba(234, 88, 12, 0.16), transparent 30%),
        linear-gradient(135deg, rgba(255, 255, 255, 0.88), rgba(253, 236, 220, 0.88));
    border-color: rgba(180, 83, 9, 0.28);
}

.mk-app[data-theme="light"] .mk-tab-hero h1,
.mk-app[data-theme="light"] .mk-tab-hero h2,
.mk-app[data-theme="light"] .mk-panel h2,
.mk-app[data-theme="light"] .mk-panel h3,
.mk-app[data-theme="light"] .mk-compare-header h2 {
    color: #2b140d;
    text-shadow: none;
}

.mk-app[data-theme="light"] .mk-tab-hero p,
.mk-app[data-theme="light"] .mk-panel p,
.mk-app[data-theme="light"] .mk-muted-text {
    color: #6f4b3b;
}

.mk-app[data-theme="light"] .mk-kpi-card-premium,
.mk-app[data-theme="light"] .mk-kpi-card {
    background:
        linear-gradient(145deg, rgba(255, 255, 255, 0.96), rgba(255, 237, 213, 0.92));
    border-color: rgba(234, 88, 12, 0.26);
    box-shadow:
        0 18px 44px rgba(146, 64, 14, 0.14),
        inset 0 1px 0 rgba(255, 255, 255, 0.80);
}

.mk-app[data-theme="light"] .mk-kpi-card-premium::before {
    opacity: 0.14;
}

.mk-app[data-theme="light"] .mk-kpi-card span {
    color: #7c4a31;
}

.mk-app[data-theme="light"] .mk-kpi-card strong {
    color: #2b140d;
    text-shadow: none;
    opacity: 1;
}

.mk-app[data-theme="light"] .mk-kpi-icon {
    color: #fff7ed;
    background: linear-gradient(135deg, #b91c1c, #ea580c);
}

/* ---------- Native select fallback styling ---------- */

.mk-select,
.mk-input,
.mk-filter-group select {
    color-scheme: dark;
    background-color: #080302;
    color: #fff4e6;
}

.mk-select option,
.mk-filter-group select option {
    background-color: #080302;
    color: #fff4e6;
}

.mk-app[data-theme="light"] .mk-select,
.mk-app[data-theme="light"] .mk-input,
.mk-app[data-theme="light"] .mk-filter-group select {
    color-scheme: light;
    background-color: #fff7ed;
    color: #2b140d;
}

.mk-app[data-theme="light"] .mk-select option,
.mk-app[data-theme="light"] .mk-filter-group select option {
    background-color: #fff7ed;
    color: #2b140d;
}

/* ---------- Custom fighter dropdown ---------- */

.mk-fighter-picker {
    position: relative;
    display: grid;
    gap: 8px;
}

.mk-fighter-picker label {
    color: var(--mk-muted);
    font-size: 11px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}

.mk-fighter-picker__button {
    min-height: 52px;
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border: 1px solid rgba(248, 184, 78, 0.30);
    border-radius: 16px;
    padding: 0 16px;
    color: var(--mk-text);
    background: rgba(5, 3, 2, 0.82);
    cursor: pointer;
}

.mk-fighter-picker__button strong {
    color: var(--mk-gold);
    font-size: 18px;
}

.mk-fighter-picker__menu {
    position: absolute;
    top: calc(100% + 8px);
    left: 0;
    right: 0;
    z-index: 80;
    padding: 10px;
    border-radius: 18px;
    background: rgba(8, 3, 2, 0.98);
    border: 1px solid rgba(248, 184, 78, 0.34);
    box-shadow: 0 28px 70px rgba(0, 0, 0, 0.68);
}

.mk-fighter-picker__menu input {
    width: 100%;
    min-height: 42px;
    margin-bottom: 10px;
    border: 1px solid rgba(248, 184, 78, 0.26);
    border-radius: 12px;
    padding: 0 12px;
    color: #fff4e6;
    background: rgba(0, 0, 0, 0.54);
}

.mk-fighter-picker__list {
    max-height: 270px;
    overflow-y: auto;
    display: grid;
    gap: 4px;
}

.mk-fighter-picker__list button {
    min-height: 38px;
    border: 0;
    border-radius: 10px;
    padding: 0 10px;
    text-align: left;
    color: #fff4e6;
    background: transparent;
    cursor: pointer;
}

.mk-fighter-picker__list button:hover,
.mk-fighter-picker__list button.is-selected {
    color: #160504;
    background: linear-gradient(135deg, var(--mk-gold), var(--mk-orange));
}

.mk-app[data-theme="light"] .mk-fighter-picker__button {
    color: #2b140d;
    background: rgba(255, 247, 237, 0.88);
}

.mk-app[data-theme="light"] .mk-fighter-picker__menu {
    background: rgba(255, 247, 237, 0.98);
    box-shadow: 0 24px 60px rgba(146, 64, 14, 0.24);
}

.mk-app[data-theme="light"] .mk-fighter-picker__menu input {
    color: #2b140d;
    background: rgba(255, 255, 255, 0.92);
}

.mk-app[data-theme="light"] .mk-fighter-picker__list button {
    color: #2b140d;
}

/* ---------- Home cinematic background ---------- */

.mk-app--home {
    min-height: 100vh;
    overflow-y: auto;
}

.mk-home-cinematic {
    position: relative;
    min-height: calc(100vh - 126px);
    height: auto;
    overflow: hidden;
    display: grid;
    grid-template-rows: minmax(430px, 1fr) auto;
    gap: 14px;
}

.mk-cinematic-bg,
.mk-cinematic-vignette {
    position: absolute;
    inset: 0;
    pointer-events: none;
}

.mk-cinematic-bg {
    z-index: 0;
    background-image:
        linear-gradient(90deg, rgba(5, 3, 2, 0.94) 0%, rgba(5, 3, 2, 0.62) 34%, rgba(5, 3, 2, 0.72) 100%),
        url("/assets/backgrounds/home-arena.webp"),
        url("/assets/backgrounds/home-arena.png"),
        url("/assets/backgrounds/home-arena.jpg"),
        radial-gradient(circle at 50% 50%, rgba(255, 90, 31, 0.20), transparent 36%);
    background-size: cover, cover, cover, cover, cover;
    background-position: center, center, center, center, center;
    animation: mk-cinematic-pan 16s ease-in-out infinite alternate;
    transform: scale(1.03);
}

.mk-cinematic-vignette {
    z-index: 1;
    background:
        radial-gradient(circle at 50% 42%, transparent 0%, rgba(0, 0, 0, 0.20) 42%, rgba(0, 0, 0, 0.72) 100%),
        linear-gradient(180deg, rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0.58));
}

@keyframes mk-cinematic-pan {
    from {
        transform: scale(1.03) translate3d(-10px, 0, 0);
        filter: saturate(1.05) contrast(1.03);
    }
    to {
        transform: scale(1.08) translate3d(12px, -6px, 0);
        filter: saturate(1.18) contrast(1.08);
    }
}

.mk-home-hero-fit {
    position: relative;
    z-index: 3;
    min-height: 0;
    height: 100%;
    grid-template-columns: minmax(0, 1fr) minmax(220px, 320px);
    align-items: center;
    padding: clamp(22px, 3vw, 42px);
    background: rgba(20, 7, 4, 0.50);
    backdrop-filter: blur(2px);
}

.mk-home-copy {
    position: relative;
    z-index: 4;
}

.mk-home-logo {
    max-width: clamp(180px, 20vw, 300px);
}

.mk-home-copy h1 {
    font-size: clamp(48px, 7vw, 96px);
    line-height: 0.94;
    margin: 8px 0 12px;
}

.mk-home-copy p {
    max-width: 620px;
    font-size: 17px;
    line-height: 1.48;
}

.mk-home-card-grid-fit {
    position: relative;
    z-index: 5;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 12px;
}

.mk-home-card-grid-fit article {
    min-height: 98px;
    padding: 14px;
    backdrop-filter: blur(14px);
}

/* ---------- Fire / embers ---------- */

.mk-fire-layer {
    position: absolute;
    left: -10%;
    right: -10%;
    bottom: -18%;
    height: 38%;
    pointer-events: none;
    z-index: 2;
    background:
        radial-gradient(circle at 10% 100%, rgba(255, 90, 31, 0.56), transparent 26%),
        radial-gradient(circle at 28% 100%, rgba(248, 184, 78, 0.40), transparent 28%),
        radial-gradient(circle at 50% 100%, rgba(215, 25, 32, 0.38), transparent 30%),
        radial-gradient(circle at 72% 100%, rgba(255, 90, 31, 0.42), transparent 28%),
        radial-gradient(circle at 90% 100%, rgba(248, 184, 78, 0.34), transparent 24%);
    filter: blur(12px);
    animation: mk-fire-rise 2.6s ease-in-out infinite alternate;
    opacity: 0.82;
}

.mk-fire-layer--mid {
    bottom: -20%;
    height: 30%;
    filter: blur(18px);
    animation-duration: 3.4s;
    opacity: 0.60;
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
    z-index: 2;
    background:
        radial-gradient(circle at 8% 78%, rgba(248,184,78,0.28) 0 2px, transparent 3px),
        radial-gradient(circle at 18% 55%, rgba(255,90,31,0.20) 0 2px, transparent 3px),
        radial-gradient(circle at 32% 68%, rgba(248,184,78,0.22) 0 2px, transparent 3px),
        radial-gradient(circle at 55% 52%, rgba(215,25,32,0.18) 0 2px, transparent 3px),
        radial-gradient(circle at 74% 72%, rgba(248,184,78,0.20) 0 2px, transparent 3px),
        radial-gradient(circle at 86% 46%, rgba(255,90,31,0.18) 0 2px, transparent 3px);
    animation: mk-ember-float 9s linear infinite;
}

@keyframes mk-fire-rise {
    from {
        transform: translateY(12px) scaleX(1);
        opacity: 0.70;
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

/* ---------- Compare layout corrections ---------- */

.mk-compare-page {
    display: grid;
    gap: 16px;
}

.mk-compare-header {
    padding: 22px 28px;
    border-radius: 24px;
}

.mk-compare-header h2 {
    margin: 6px 0 6px;
    font-size: clamp(42px, 5.2vw, 76px);
    line-height: 0.95;
}

.mk-compare-toolbar {
    position: relative;
    z-index: 40;
    display: grid;
    grid-template-columns: 1fr 88px 1fr;
    gap: 14px;
    align-items: end;
    padding: 16px;
    border-radius: 22px;
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
}

.mk-compare-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 18px;
}

.mk-compare-card {
    min-height: 430px;
    border-radius: 24px;
    overflow: hidden;
}

.mk-compare-card__hero {
    min-height: 430px;
    padding: 16px;
}

.mk-compare-visual {
    position: absolute;
    inset: 48px 16px 145px 16px;
    display: grid;
    place-items: end center;
    overflow: hidden;
}

.mk-compare-visual__img {
    width: auto;
    height: 100%;
    max-width: 92%;
    max-height: 100%;
    object-fit: contain;
    object-position: center bottom;
    filter:
        drop-shadow(0 30px 42px rgba(0, 0, 0, 0.75))
        drop-shadow(0 0 28px rgba(255, 90, 31, 0.16));
}

.mk-compare-card__content {
    left: 16px;
    right: 16px;
    bottom: 16px;
    padding: 14px;
}

.mk-compare-card__content h3 {
    margin: 6px 0 3px;
    font-size: 22px;
}

.mk-compare-card__content p {
    margin: 0 0 10px;
    font-size: 13px;
}

.mk-compare-mini-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 7px;
}

.mk-compare-mini-grid div {
    padding: 8px;
    border-radius: 13px;
}

.mk-compare-card__footer {
    margin-top: 10px;
}

.mk-compare-metrics {
    padding: 18px;
}

.mk-metric-row {
    display: grid;
    grid-template-columns: 1fr 160px 1fr;
    gap: 12px;
    align-items: center;
    padding: 8px 0;
}

/* ---------- Responsive corrections ---------- */

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
        min-height: 0;
        height: auto;
        overflow: visible;
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
    Write-Host "APPENDED: Step 18 CSS"
}
else {
    Write-Host "Step 18 CSS already exists. Skipping CSS append."
}

Write-Host ""
Write-Host "========================================"
Write-Host "Step 18 final patch applied."
Write-Host "========================================"
Write-Host "Next:"
Write-Host "cd $AppRoot"
Write-Host "npm run build:fabric"
