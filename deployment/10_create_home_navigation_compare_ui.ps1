# =====================================================
# Step 10 - Home Page, Navigation, Slicers and Fighter Compare
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"
$StylesFile = Join-Path $AppRoot "src\styles\mk-theme.css"

Write-Host "========================================"
Write-Host "Step 10 - Home, tabs, slicers, compare"
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

function Backup-File {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Copy-Item $Path "$Path.backup_$timestamp" -Force
        Write-Host "BACKUP: $Path.backup_$timestamp"
    }
}

function Write-TextFile {
    param(
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
# Backups
# =====================================================

Backup-File (Join-Path $ComponentsFolder "MkAppShell.tsx")
Backup-File $StylesFile

# =====================================================
# Shared mapper
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "fighterRowMapper.ts") -Content @'
import type { FighterRow } from "./types";

export function mapFighterRow(row: unknown[]): FighterRow {
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
'@

# =====================================================
# Navigation
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "AppNavigation.tsx") -Content @'
export type AppTab = "home" | "dashboard" | "roster" | "compare";

type AppNavigationProps = {
    activeTab: AppTab;
    onChange: (tab: AppTab) => void;
};

const navItems: Array<{ id: AppTab; label: string; description: string }> = [
    { id: "home", label: "Home", description: "Enter the arena" },
    { id: "dashboard", label: "Command Center", description: "Executive KPIs" },
    { id: "roster", label: "Roster", description: "Choose your fighter" },
    { id: "compare", label: "Compare", description: "Fighter vs fighter" },
];

export function AppNavigation({ activeTab, onChange }: AppNavigationProps) {
    return (
        <header className="mk-top-nav">
            <button type="button" className="mk-nav-brand" onClick={() => onChange("home")}>
                <span className="mk-brand-mark">MK</span>
                <span>
                    <strong>Arena Intelligence</strong>
                    <em>Fabric + Rayfin</em>
                </span>
            </button>

            <nav className="mk-nav-tabs" aria-label="App navigation">
                {navItems.map((item) => (
                    <button
                        key={item.id}
                        type="button"
                        className={activeTab === item.id ? "is-active" : ""}
                        onClick={() => onChange(item.id)}
                    >
                        <strong>{item.label}</strong>
                        <span>{item.description}</span>
                    </button>
                ))}
            </nav>
        </header>
    );
}
'@

# =====================================================
# Home landing
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "HomeLanding.tsx") -Content @'
import type { AppTab } from "./AppNavigation";

type HomeLandingProps = {
    onNavigate: (tab: AppTab) => void;
};

export function HomeLanding({ onNavigate }: HomeLandingProps) {
    return (
        <section className="mk-home">
            <div className="mk-home-hero">
                <div className="mk-home-copy">
                    <span className="mk-eyebrow">Live Fabric Data App</span>
                    <h1>Enter the Arena</h1>
                    <p>
                        A cinematic Mortal Kombat analytics experience powered by Microsoft
                        Fabric, DAX measures, semantic models and a Rayfin React front end.
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

                <div className="mk-home-emblem">
                    <span>FIGHT</span>
                    <strong>35</strong>
                    <em>fighters loaded</em>
                </div>
            </div>

            <div className="mk-home-card-grid">
                <article>
                    <span>01</span>
                    <h3>Live Semantic Model</h3>
                    <p>All KPIs and fighter metrics are queried from your Fabric semantic model.</p>
                </article>
                <article>
                    <span>02</span>
                    <h3>Choose Your Fighter</h3>
                    <p>Filter by roster group, realm, element and combat style.</p>
                </article>
                <article>
                    <span>03</span>
                    <h3>Compare Mode</h3>
                    <p>Pick Fighter A and Fighter B to inspect rank, score, KOs, win rate and head-to-head metrics.</p>
                </article>
                <article>
                    <span>04</span>
                    <h3>Rayfin App Experience</h3>
                    <p>Custom UI, Fabric security context and semantic model reuse in one app.</p>
                </article>
            </div>
        </section>
    );
}
'@

# =====================================================
# Dashboard tab
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "DashboardTab.tsx") -Content @'
import { KpiSummary } from "./KpiSummary";
import { ArenaInsights } from "./ArenaInsights";
import { KameoInsights } from "./KameoInsights";

export function DashboardTab() {
    return (
        <>
            <section className="mk-tab-hero">
                <span className="mk-eyebrow">Command Center</span>
                <h1>Combat Performance Dashboard</h1>
                <p>
                    Executive-level battle intelligence with live KPIs, arena performance and
                    Kameo assist analytics.
                </p>
            </section>

            <KpiSummary />

            <div className="mk-two-column">
                <ArenaInsights />
                <KameoInsights />
            </div>
        </>
    );
}
'@

# =====================================================
# Fighter explorer with slicers
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterExplorer.tsx") -Content @'
import { useEffect, useMemo, useRef, useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery } from "@/queries/kombat";
import { FighterCard3D } from "./FighterCard3D";
import { FighterProfilePanel } from "./FighterProfilePanel";
import { mapFighterRow } from "./fighterRowMapper";
import type { FighterRow } from "./types";

type SortOption = "score" | "xp" | "winRate" | "kos" | "name";

function uniqueValues(fighters: FighterRow[], selector: (fighter: FighterRow) => string) {
    return Array.from(new Set(fighters.map(selector).filter(Boolean))).sort();
}

export function FighterExplorer() {
    const [selectedFighter, setSelectedFighter] = useState<FighterRow | null>(null);
    const [search, setSearch] = useState("");
    const [rosterGroup, setRosterGroup] = useState("All");
    const [realm, setRealm] = useState("All");
    const [element, setElement] = useState("All");
    const [combatStyle, setCombatStyle] = useState("All");
    const [sortBy, setSortBy] = useState<SortOption>("score");

    const profileRef = useRef<HTMLDivElement | null>(null);

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

    const filteredFighters = useMemo(() => {
        const searchText = search.trim().toLowerCase();

        const filtered = fighters.filter((fighter) => {
            const matchesSearch =
                !searchText ||
                fighter.fighterName.toLowerCase().includes(searchText) ||
                fighter.realm.toLowerCase().includes(searchText) ||
                fighter.element.toLowerCase().includes(searchText) ||
                fighter.combatStyle.toLowerCase().includes(searchText);

            return (
                matchesSearch &&
                (rosterGroup === "All" || fighter.rosterGroup === rosterGroup) &&
                (realm === "All" || fighter.realm === realm) &&
                (element === "All" || fighter.element === element) &&
                (combatStyle === "All" || fighter.combatStyle === combatStyle)
            );
        });

        return filtered.sort((a, b) => {
            switch (sortBy) {
                case "xp":
                    return b.totalXP - a.totalXP;
                case "winRate":
                    return b.winRate - a.winRate;
                case "kos":
                    return b.totalKOs - a.totalKOs;
                case "name":
                    return a.fighterName.localeCompare(b.fighterName);
                case "score":
                default:
                    return b.totalScore - a.totalScore;
            }
        });
    }, [fighters, search, rosterGroup, realm, element, combatStyle, sortBy]);

    useEffect(() => {
        if (selectedFighter && profileRef.current) {
            profileRef.current.scrollIntoView({ behavior: "smooth", block: "start" });
        }
    }, [selectedFighter?.fighterName]);

    const rosterGroups = uniqueValues(fighters, (fighter) => fighter.rosterGroup);
    const realms = uniqueValues(fighters, (fighter) => fighter.realm);
    const elements = uniqueValues(fighters, (fighter) => fighter.element);
    const combatStyles = uniqueValues(fighters, (fighter) => fighter.combatStyle);

    if (isLoading) {
        return <div className="mk-loading">Loading fighter roster...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load fighter roster.</div>;
    }

    return (
        <section>
            <div className="mk-tab-hero">
                <span className="mk-eyebrow">Roster Intelligence</span>
                <h1>Choose Your Fighter</h1>
                <p>
                    Use the slicers to narrow the roster, then select a fighter to open a live
                    semantic-model profile.
                </p>
            </div>

            <div className="mk-filter-panel">
                <label>
                    <span>Search</span>
                    <input
                        className="mk-input"
                        value={search}
                        onChange={(event) => setSearch(event.target.value)}
                        placeholder="Search fighter, realm, element..."
                    />
                </label>

                <label>
                    <span>Roster Group</span>
                    <select className="mk-select" value={rosterGroup} onChange={(event) => setRosterGroup(event.target.value)}>
                        <option>All</option>
                        {rosterGroups.map((value) => (
                            <option key={value}>{value}</option>
                        ))}
                    </select>
                </label>

                <label>
                    <span>Realm</span>
                    <select className="mk-select" value={realm} onChange={(event) => setRealm(event.target.value)}>
                        <option>All</option>
                        {realms.map((value) => (
                            <option key={value}>{value}</option>
                        ))}
                    </select>
                </label>

                <label>
                    <span>Element</span>
                    <select className="mk-select" value={element} onChange={(event) => setElement(event.target.value)}>
                        <option>All</option>
                        {elements.map((value) => (
                            <option key={value}>{value}</option>
                        ))}
                    </select>
                </label>

                <label>
                    <span>Combat Style</span>
                    <select className="mk-select" value={combatStyle} onChange={(event) => setCombatStyle(event.target.value)}>
                        <option>All</option>
                        {combatStyles.map((value) => (
                            <option key={value}>{value}</option>
                        ))}
                    </select>
                </label>

                <label>
                    <span>Sort By</span>
                    <select className="mk-select" value={sortBy} onChange={(event) => setSortBy(event.target.value as SortOption)}>
                        <option value="score">Total Score</option>
                        <option value="xp">Total XP</option>
                        <option value="winRate">Win Rate</option>
                        <option value="kos">Total KOs</option>
                        <option value="name">Fighter Name</option>
                    </select>
                </label>
            </div>

            <div className="mk-result-count">
                Showing <strong>{filteredFighters.length}</strong> of <strong>{fighters.length}</strong> fighters
            </div>

            {selectedFighter ? (
                <div ref={profileRef} className="mk-profile-shell">
                    <FighterProfilePanel
                        key={selectedFighter.fighterName}
                        fighter={selectedFighter}
                        onClose={() => setSelectedFighter(null)}
                    />
                </div>
            ) : null}

            <div className="mk-fighter-grid">
                {filteredFighters.map((fighter) => (
                    <FighterCard3D
                        key={fighter.fighterName}
                        fighter={fighter}
                        isSelected={selectedFighter?.fighterName === fighter.fighterName}
                        onSelect={() => setSelectedFighter(fighter)}
                    />
                ))}
            </div>
        </section>
    );
}
'@

# =====================================================
# Compare tab
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "CompareTab.tsx") -Content @'
import { useEffect, useMemo, useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery, matchupMatrixQuery } from "@/queries/kombat";
import { FighterCard3D } from "./FighterCard3D";
import { mapFighterRow } from "./fighterRowMapper";
import type { FighterRow } from "./types";

type MatchupRow = {
    fighterName: string;
    opponentName: string;
    matchesPlayed: number;
    wins: number;
    losses: number;
    winRate: number;
    totalKOs: number;
    damageEfficiency: number;
};

function formatNumber(value: number) {
    return value.toLocaleString();
}

function formatPercent(value: number) {
    return `${(value * 100).toFixed(1)}%`;
}

function mapMatchupRow(row: unknown[]): MatchupRow {
    return {
        fighterName: String(row[0] ?? ""),
        opponentName: String(row[1] ?? ""),
        matchesPlayed: Number(row[2] ?? 0),
        wins: Number(row[3] ?? 0),
        losses: Number(row[4] ?? 0),
        winRate: Number(row[5] ?? 0),
        totalKOs: Number(row[6] ?? 0),
        damageEfficiency: Number(row[7] ?? 0),
    };
}

type CompareStatProps = {
    label: string;
    left: number;
    right: number;
    format?: "number" | "percent" | "decimal";
};

function CompareStat({ label, left, right, format = "number" }: CompareStatProps) {
    const total = Math.max(left + right, 1);
    const leftWidth = Math.max((left / total) * 100, 4);
    const rightWidth = Math.max((right / total) * 100, 4);

    const renderValue = (value: number) => {
        if (format === "percent") {
            return formatPercent(value);
        }

        if (format === "decimal") {
            return value.toFixed(2);
        }

        return formatNumber(value);
    };

    return (
        <div className="mk-comparison-row">
            <div className="mk-comparison-values">
                <strong>{renderValue(left)}</strong>
                <span>{label}</span>
                <strong>{renderValue(right)}</strong>
            </div>
            <div className="mk-versus-meter">
                <div className="left" style={{ width: `${leftWidth}%` }} />
                <div className="right" style={{ width: `${rightWidth}%` }} />
            </div>
        </div>
    );
}

export function CompareTab() {
    const [fighterAName, setFighterAName] = useState("");
    const [fighterBName, setFighterBName] = useState("");

    const fighterQuery = fighterGridQuery();
    const matchupQuery = matchupMatrixQuery();

    const fighterResult = useSemanticModelQuery({
        connection: fighterQuery.connection,
        query: fighterQuery.query,
    });

    const matchupResult = useSemanticModelQuery({
        connection: matchupQuery.connection,
        query: matchupQuery.query,
    });

    const fighterData = fighterResult.data as any;
    const matchupData = matchupResult.data as any;

    const fighters = useMemo(() => {
        if (!fighterData || fighterData.status !== "success") {
            return [];
        }

        return (fighterData.table.rows as unknown[][]).map(mapFighterRow);
    }, [fighterData]);

    const matchupRows = useMemo(() => {
        if (!matchupData || matchupData.status !== "success") {
            return [];
        }

        return (matchupData.table.rows as unknown[][]).map(mapMatchupRow);
    }, [matchupData]);

    useEffect(() => {
        if (fighters.length > 1 && !fighterAName && !fighterBName) {
            setFighterAName(fighters[0].fighterName);
            setFighterBName(fighters[1].fighterName);
        }
    }, [fighters, fighterAName, fighterBName]);

    const fighterA = fighters.find((fighter) => fighter.fighterName === fighterAName);
    const fighterB = fighters.find((fighter) => fighter.fighterName === fighterBName);

    const headToHead = matchupRows.find(
        (row) => row.fighterName === fighterAName && row.opponentName === fighterBName
    );

    const reverseHeadToHead = matchupRows.find(
        (row) => row.fighterName === fighterBName && row.opponentName === fighterAName
    );

    if (fighterResult.isLoading || matchupResult.isLoading) {
        return <div className="mk-loading">Loading compare arena...</div>;
    }

    if (fighterResult.error || matchupResult.error || fighterData?.status === "error" || matchupData?.status === "error") {
        return <div className="mk-error">Unable to load comparison data.</div>;
    }

    return (
        <section>
            <div className="mk-tab-hero">
                <span className="mk-eyebrow">Fighter A vs Fighter B</span>
                <h1>Compare Fighters</h1>
                <p>
                    Pick two fighters and compare live Fabric semantic model metrics side by side.
                </p>
            </div>

            <div className="mk-compare-selectors">
                <label>
                    <span>Fighter A</span>
                    <select className="mk-select" value={fighterAName} onChange={(event) => setFighterAName(event.target.value)}>
                        {fighters.map((fighter) => (
                            <option key={fighter.fighterName}>{fighter.fighterName}</option>
                        ))}
                    </select>
                </label>

                <div className="mk-versus">VS</div>

                <label>
                    <span>Fighter B</span>
                    <select className="mk-select" value={fighterBName} onChange={(event) => setFighterBName(event.target.value)}>
                        {fighters.map((fighter) => (
                            <option key={fighter.fighterName}>{fighter.fighterName}</option>
                        ))}
                    </select>
                </label>
            </div>

            {fighterA && fighterB ? (
                <>
                    <div className="mk-compare-grid">
                        <FighterCard3D fighter={fighterA} isSelected onSelect={() => undefined} />
                        <FighterCard3D fighter={fighterB} isSelected onSelect={() => undefined} />
                    </div>

                    <section className="mk-panel">
                        <div className="mk-section-header" style={{ marginTop: 0 }}>
                            <span>Stat Clash</span>
                            <h2>{fighterA.fighterName} vs {fighterB.fighterName}</h2>
                        </div>

                        <CompareStat label="Total Score" left={fighterA.totalScore} right={fighterB.totalScore} />
                        <CompareStat label="Total XP" left={fighterA.totalXP} right={fighterB.totalXP} />
                        <CompareStat label="Win Rate" left={fighterA.winRate} right={fighterB.winRate} format="percent" />
                        <CompareStat label="Total KOs" left={fighterA.totalKOs} right={fighterB.totalKOs} />
                        <CompareStat label="Fatalities" left={fighterA.fatalities} right={fighterB.fatalities} />
                        <CompareStat label="Damage Efficiency" left={fighterA.damageEfficiency} right={fighterB.damageEfficiency} format="decimal" />
                    </section>

                    <section className="mk-panel">
                        <div className="mk-section-header" style={{ marginTop: 0 }}>
                            <span>Head-to-Head Snapshot</span>
                            <h2>Matchup Intelligence</h2>
                        </div>

                        {headToHead || reverseHeadToHead ? (
                            <div className="mk-head-to-head">
                                {headToHead ? (
                                    <div>
                                        <strong>{headToHead.fighterName} attacking {headToHead.opponentName}</strong>
                                        <span>Matches: {formatNumber(headToHead.matchesPlayed)}</span>
                                        <span>Wins: {formatNumber(headToHead.wins)}</span>
                                        <span>Win Rate: {formatPercent(headToHead.winRate)}</span>
                                        <span>KOs: {formatNumber(headToHead.totalKOs)}</span>
                                    </div>
                                ) : null}

                                {reverseHeadToHead ? (
                                    <div>
                                        <strong>{reverseHeadToHead.fighterName} attacking {reverseHeadToHead.opponentName}</strong>
                                        <span>Matches: {formatNumber(reverseHeadToHead.matchesPlayed)}</span>
                                        <span>Wins: {formatNumber(reverseHeadToHead.wins)}</span>
                                        <span>Win Rate: {formatPercent(reverseHeadToHead.winRate)}</span>
                                        <span>KOs: {formatNumber(reverseHeadToHead.totalKOs)}</span>
                                    </div>
                                ) : null}
                            </div>
                        ) : (
                            <p className="mk-muted-text">
                                No direct matchup row found in the top matchup sample. The global comparison still works.
                            </p>
                        )}
                    </section>
                </>
            ) : null}
        </section>
    );
}
'@

# =====================================================
# MkAppShell
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "MkAppShell.tsx") -Content @'
import { useState } from "react";
import { AppNavigation, type AppTab } from "./AppNavigation";
import { HomeLanding } from "./HomeLanding";
import { DashboardTab } from "./DashboardTab";
import { FighterExplorer } from "./FighterExplorer";
import { CompareTab } from "./CompareTab";

export function MkAppShell() {
    const [activeTab, setActiveTab] = useState<AppTab>("home");

    return (
        <main className="mk-app">
            <AppNavigation activeTab={activeTab} onChange={setActiveTab} />

            {activeTab === "home" ? <HomeLanding onNavigate={setActiveTab} /> : null}
            {activeTab === "dashboard" ? <DashboardTab /> : null}
            {activeTab === "roster" ? <FighterExplorer /> : null}
            {activeTab === "compare" ? <CompareTab /> : null}
        </main>
    );
}
'@

# =====================================================
# CSS patch
# =====================================================

$cssMarker = "/* =====================================================`n   Step 10 - Home tabs slicers compare UI"
$currentCss = Get-Content -Path $StylesFile -Raw

if ($currentCss -notlike "*Step 10 - Home tabs slicers compare UI*") {
    Add-Content -Path $StylesFile -Value @'

/* =====================================================
   Step 10 - Home tabs slicers compare UI
   ===================================================== */

.mk-top-nav {
    position: sticky;
    top: 0;
    z-index: 20;
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 18px;
    margin-bottom: 24px;
    padding: 14px;
    border: 1px solid rgba(255, 111, 28, 0.24);
    border-radius: 24px;
    background: rgba(5, 3, 2, 0.72);
    backdrop-filter: blur(20px);
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
}

.mk-nav-brand {
    appearance: none;
    border: 0;
    background: transparent;
    color: var(--mk-text);
    display: flex;
    align-items: center;
    gap: 12px;
    cursor: pointer;
    text-align: left;
}

.mk-brand-mark {
    width: 52px;
    height: 52px;
    display: grid;
    place-items: center;
    border-radius: 16px;
    color: #190604;
    background: radial-gradient(circle, var(--mk-gold), var(--mk-orange));
    font-weight: 1000;
    box-shadow: 0 0 42px rgba(255, 90, 31, 0.44);
}

.mk-nav-brand strong,
.mk-nav-brand em {
    display: block;
}

.mk-nav-brand strong {
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

.mk-nav-brand em {
    color: var(--mk-muted);
    font-size: 12px;
    font-style: normal;
}

.mk-nav-tabs {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
    justify-content: flex-end;
}

.mk-nav-tabs button {
    appearance: none;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 16px;
    padding: 10px 14px;
    min-width: 138px;
    color: var(--mk-muted);
    background: rgba(255, 255, 255, 0.035);
    cursor: pointer;
    text-align: left;
    transition: transform 160ms ease, border-color 160ms ease, background 160ms ease, color 160ms ease;
}

.mk-nav-tabs button:hover,
.mk-nav-tabs button.is-active {
    color: var(--mk-text);
    transform: translateY(-2px);
    border-color: rgba(248, 184, 78, 0.55);
    background: rgba(255, 90, 31, 0.12);
}

.mk-nav-tabs strong,
.mk-nav-tabs span {
    display: block;
}

.mk-nav-tabs strong {
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 0.08em;
}

.mk-nav-tabs span {
    margin-top: 4px;
    font-size: 11px;
}

.mk-home {
    display: grid;
    gap: 24px;
}

.mk-home-hero,
.mk-tab-hero {
    position: relative;
    overflow: hidden;
    border: 1px solid rgba(255, 111, 28, 0.3);
    border-radius: 34px;
    background:
        radial-gradient(circle at 18% 20%, rgba(255, 90, 31, 0.28), transparent 32%),
        radial-gradient(circle at 82% 20%, rgba(215, 25, 32, 0.20), transparent 34%),
        linear-gradient(145deg, rgba(37, 17, 10, 0.96), rgba(5, 3, 2, 0.98));
    box-shadow:
        0 36px 100px rgba(0, 0, 0, 0.68),
        inset 0 1px 0 rgba(255, 255, 255, 0.08);
}

.mk-home-hero {
    min-height: 580px;
    display: grid;
    grid-template-columns: minmax(0, 1fr) 360px;
    gap: 32px;
    align-items: center;
    padding: 56px;
}

.mk-tab-hero {
    padding: 34px;
    margin-bottom: 24px;
}

.mk-tab-hero h1,
.mk-home-copy h1 {
    margin: 0;
    color: #fff4e6;
    text-transform: uppercase;
    letter-spacing: -0.07em;
    line-height: 0.9;
    text-shadow:
        0 0 26px rgba(255, 90, 31, 0.62),
        0 18px 48px rgba(0, 0, 0, 0.78);
}

.mk-home-copy h1 {
    font-size: clamp(64px, 10vw, 138px);
}

.mk-tab-hero h1 {
    font-size: clamp(42px, 6vw, 84px);
}

.mk-home-copy p,
.mk-tab-hero p {
    max-width: 760px;
    color: var(--mk-muted);
    font-size: 18px;
    line-height: 1.6;
}

.mk-home-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 14px;
    margin-top: 28px;
}

.mk-home-actions button {
    appearance: none;
    border: 1px solid rgba(248, 184, 78, 0.48);
    border-radius: 999px;
    padding: 14px 22px;
    color: #160504;
    background: linear-gradient(135deg, var(--mk-gold), var(--mk-orange));
    font-weight: 1000;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    cursor: pointer;
    box-shadow: 0 0 46px rgba(255, 90, 31, 0.28);
}

.mk-home-actions button + button {
    color: var(--mk-gold);
    background: rgba(0, 0, 0, 0.34);
}

.mk-home-emblem {
    min-height: 360px;
    display: grid;
    place-items: center;
    text-align: center;
    border-radius: 36px;
    background:
        radial-gradient(circle, rgba(248, 184, 78, 0.72), rgba(255, 90, 31, 0.32) 44%, rgba(0, 0, 0, 0.14) 74%),
        rgba(0, 0, 0, 0.26);
    border: 1px solid rgba(248, 184, 78, 0.34);
    box-shadow:
        0 0 90px rgba(255, 90, 31, 0.45),
        inset 0 0 44px rgba(255, 255, 255, 0.12);
    transform: perspective(900px) rotateY(-10deg) rotateX(4deg);
}

.mk-home-emblem span,
.mk-home-emblem strong,
.mk-home-emblem em {
    display: block;
}

.mk-home-emblem span {
    color: #160504;
    font-size: 46px;
    font-weight: 1000;
    letter-spacing: -0.04em;
}

.mk-home-emblem strong {
    color: #fff4e6;
    font-size: 130px;
    line-height: 0.9;
    text-shadow: 0 0 28px rgba(0, 0, 0, 0.58);
}

.mk-home-emblem em {
    color: #160504;
    font-style: normal;
    font-weight: 900;
    text-transform: uppercase;
}

.mk-home-card-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 18px;
}

.mk-home-card-grid article {
    padding: 24px;
    border-radius: 24px;
    background:
        radial-gradient(circle at top left, rgba(255, 90, 31, 0.16), transparent 36%),
        rgba(12, 7, 5, 0.82);
    border: 1px solid rgba(255, 111, 28, 0.22);
}

.mk-home-card-grid span {
    color: var(--mk-gold);
    font-weight: 1000;
}

.mk-home-card-grid h3 {
    margin: 10px 0 8px;
    text-transform: uppercase;
}

.mk-home-card-grid p {
    color: var(--mk-muted);
    line-height: 1.55;
}

.mk-filter-panel,
.mk-compare-selectors {
    display: grid;
    grid-template-columns: repeat(6, minmax(0, 1fr));
    gap: 14px;
    margin-bottom: 18px;
    padding: 16px;
    border-radius: 24px;
    background: rgba(0, 0, 0, 0.24);
    border: 1px solid rgba(255, 111, 28, 0.20);
}

.mk-filter-panel label,
.mk-compare-selectors label {
    display: grid;
    gap: 8px;
    color: var(--mk-muted);
    font-size: 11px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
}

.mk-input,
.mk-select {
    width: 100%;
    min-height: 44px;
    border: 1px solid rgba(248, 184, 78, 0.28);
    border-radius: 14px;
    padding: 0 12px;
    color: var(--mk-text);
    background: rgba(5, 3, 2, 0.82);
    outline: none;
}

.mk-input:focus,
.mk-select:focus {
    border-color: rgba(248, 184, 78, 0.72);
    box-shadow: 0 0 0 3px rgba(248, 184, 78, 0.12);
}

.mk-result-count {
    margin: 0 0 18px;
    color: var(--mk-muted);
}

.mk-result-count strong {
    color: var(--mk-gold);
}

.mk-compare-selectors {
    grid-template-columns: 1fr 100px 1fr;
    align-items: end;
}

.mk-versus {
    height: 52px;
    display: grid;
    place-items: center;
    border-radius: 16px;
    color: #160504;
    background: linear-gradient(135deg, var(--mk-gold), var(--mk-orange));
    font-weight: 1000;
    font-size: 22px;
    box-shadow: 0 0 42px rgba(255, 90, 31, 0.32);
}

.mk-compare-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(280px, 1fr));
    gap: 24px;
    margin-bottom: 24px;
}

.mk-comparison-row {
    display: grid;
    gap: 10px;
    margin-bottom: 16px;
}

.mk-comparison-values {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    gap: 12px;
}

.mk-comparison-values strong:last-child {
    text-align: right;
}

.mk-comparison-values span {
    color: var(--mk-gold);
    font-size: 11px;
    font-weight: 900;
    letter-spacing: 0.1em;
    text-transform: uppercase;
}

.mk-versus-meter {
    display: flex;
    height: 10px;
    overflow: hidden;
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.08);
}

.mk-versus-meter .left {
    background: linear-gradient(90deg, var(--mk-orange), var(--mk-gold));
}

.mk-versus-meter .right {
    margin-left: auto;
    background: linear-gradient(90deg, var(--mk-ice), var(--mk-purple));
}

.mk-head-to-head {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 18px;
}

.mk-head-to-head div {
    display: grid;
    gap: 8px;
    padding: 18px;
    border-radius: 18px;
    background: rgba(255, 255, 255, 0.045);
    border: 1px solid rgba(255, 255, 255, 0.08);
}

.mk-head-to-head strong {
    color: var(--mk-gold);
}

.mk-head-to-head span,
.mk-muted-text {
    color: var(--mk-muted);
}

@media (max-width: 1250px) {
    .mk-home-card-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .mk-filter-panel {
        grid-template-columns: repeat(3, minmax(0, 1fr));
    }
}

@media (max-width: 860px) {
    .mk-top-nav {
        position: static;
        align-items: stretch;
        flex-direction: column;
    }

    .mk-nav-tabs {
        justify-content: stretch;
    }

    .mk-nav-tabs button {
        min-width: calc(50% - 8px);
    }

    .mk-home-hero {
        grid-template-columns: 1fr;
        padding: 28px;
    }

    .mk-home-emblem {
        transform: none;
    }

    .mk-home-card-grid,
    .mk-filter-panel,
    .mk-compare-selectors,
    .mk-compare-grid,
    .mk-head-to-head {
        grid-template-columns: 1fr;
    }
}
'@
    Write-Host "APPENDED: Step 10 CSS"
}
else {
    Write-Host "Step 10 CSS already exists. Skipping CSS append."
}

Write-Host ""
Write-Host "========================================"
Write-Host "Step 10 home/tabs/slicers/compare applied."
Write-Host "========================================"
Write-Host "Next:"
Write-Host "cd $AppRoot"
Write-Host "npm run build:fabric"
