# =====================================================
# Step 7 - Create Rayfin Runtime DAX Query Files
# Mortal Kombat Arena Intelligence
# FIXED VERSION: Run this .ps1 file directly.
# Do not paste this script body line-by-line into PowerShell.
# =====================================================

$ErrorActionPreference = "Stop"

$RayfinAppFolder = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$QueryFolder = Join-Path $RayfinAppFolder "src\queries\kombat"

Write-Host "========================================"
Write-Host "Step 7 - Create Rayfin DAX query files"
Write-Host "========================================"
Write-Host "RayfinAppFolder: $RayfinAppFolder"
Write-Host "QueryFolder: $QueryFolder"
Write-Host ""

if (-not (Test-Path $RayfinAppFolder)) {
    throw "Rayfin app folder not found: $RayfinAppFolder"
}

New-Item -Path $QueryFolder -ItemType Directory -Force | Out-Null

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $folder = Split-Path -Parent $Path
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

# =====================================================
# 1. KPI SUMMARY
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "kpi-summary.dax") -Content @'
EVALUATE
ROW (
    "Total Matches", [Total Matches],
    "Matches Played", [Matches Played],
    "Wins", [Wins],
    "Losses", [Losses],
    "Win Rate", [Win Rate],
    "Total XP", [Total XP],
    "Average XP Per Match", [Average XP Per Match],
    "Total Score", [Total Score],
    "Average Score", [Average Score],
    "Total KOs", [Total KOs],
    "KO Rate", [KO Rate],
    "Fatalities", [Fatalities],
    "Brutalities", [Brutalities],
    "Perfect Rounds", [Perfect Rounds],
    "Damage Efficiency", [Damage Efficiency],
    "Combat Events", [Combat Events]
)
'@

Write-TextFile -Path (Join-Path $QueryFolder "kpi-summary.ts") -Content @'
import query from "./kpi-summary.dax?raw";

const connection = "kombatModel";

export function kpiSummaryQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 2. FIGHTER GRID
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "fighter-grid.dax") -Content @'
EVALUATE
TOPN (
    35,
    SUMMARIZECOLUMNS (
        dimfighter[FighterName],
        dimfighter[RosterGroup],
        dimfighter[Realm],
        dimfighter[Element],
        dimfighter[CombatStyle],
        dimfighter[Alignment],
        dimfighter[Difficulty],
        dimfighter[PrimaryColor],
        dimfighter[SecondaryColor],
        dimfighter[PortraitImagePath],
        dimfighter[FullBodyImagePath],
        dimfighter[CardBackgroundPath],
        dimfighter[Model3DPath],
        "Matches Played", [Matches Played],
        "Wins", [Wins],
        "Losses", [Losses],
        "Win Rate", [Win Rate],
        "Total XP", [Total XP],
        "Total Score", [Total Score],
        "Total KOs", [Total KOs],
        "Fatalities", [Fatalities],
        "Brutalities", [Brutalities],
        "Damage Efficiency", [Damage Efficiency],
        "Fighter Rank by Score", [Fighter Rank by Score]
    ),
    [Total Score],
    DESC
)
ORDER BY [Total Score] DESC
'@

Write-TextFile -Path (Join-Path $QueryFolder "fighter-grid.ts") -Content @'
import query from "./fighter-grid.dax?raw";

const connection = "kombatModel";

export function fighterGridQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 3. FIGHTER PROFILE SAMPLE DAX + DYNAMIC TS WRAPPER
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "fighter-profile.dax") -Content @'
EVALUATE
CALCULATETABLE (
    ROW (
        "Matches Played", [Matches Played],
        "Wins", [Wins],
        "Losses", [Losses],
        "Win Rate", [Win Rate],
        "Total XP", [Total XP],
        "Average XP Per Match", [Average XP Per Match],
        "Total Score", [Total Score],
        "Average Score", [Average Score],
        "Total KOs", [Total KOs],
        "KO Rate", [KO Rate],
        "Fatalities", [Fatalities],
        "Brutalities", [Brutalities],
        "Perfect Rounds", [Perfect Rounds],
        "Damage Efficiency", [Damage Efficiency],
        "Max Combo Hits", [Max Combo Hits],
        "Average Combo Hits", [Average Combo Hits],
        "Special Moves Landed", [Special Moves Landed],
        "Fighter Rank by Score", [Fighter Rank by Score],
        "Fighter Rank by XP", [Fighter Rank by XP],
        "Fighter Rank by Win Rate", [Fighter Rank by Win Rate]
    ),
    dimfighter[FighterName] = "Scorpion"
)
'@

Write-TextFile -Path (Join-Path $QueryFolder "fighter-profile.ts") -Content @'
const connection = "kombatModel";

function escapeDaxString(value: string) {
    return value.replace(/"/g, "\"\"");
}

export function fighterProfileQuery(fighterName: string) {
    const safeFighterName = escapeDaxString(fighterName);

    const query = `
EVALUATE
CALCULATETABLE (
    ROW (
        "Matches Played", [Matches Played],
        "Wins", [Wins],
        "Losses", [Losses],
        "Win Rate", [Win Rate],
        "Total XP", [Total XP],
        "Average XP Per Match", [Average XP Per Match],
        "Total Score", [Total Score],
        "Average Score", [Average Score],
        "Total KOs", [Total KOs],
        "KO Rate", [KO Rate],
        "Fatalities", [Fatalities],
        "Brutalities", [Brutalities],
        "Perfect Rounds", [Perfect Rounds],
        "Damage Efficiency", [Damage Efficiency],
        "Max Combo Hits", [Max Combo Hits],
        "Average Combo Hits", [Average Combo Hits],
        "Special Moves Landed", [Special Moves Landed],
        "Fighter Rank by Score", [Fighter Rank by Score],
        "Fighter Rank by XP", [Fighter Rank by XP],
        "Fighter Rank by Win Rate", [Fighter Rank by Win Rate]
    ),
    dimfighter[FighterName] = "${safeFighterName}"
)
`;

    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 4. XP TREND
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "xp-trend.dax") -Content @'
EVALUATE
SUMMARIZECOLUMNS (
    dimdate[Date],
    dimdate[Year],
    dimdate[MonthNo],
    dimdate[MonthName],
    "Total XP", [Total XP],
    "Total Score", [Total Score],
    "Total KOs", [Total KOs],
    "Fatalities", [Fatalities],
    "Matches Played", [Matches Played]
)
ORDER BY dimdate[Date]
'@

Write-TextFile -Path (Join-Path $QueryFolder "xp-trend.ts") -Content @'
import query from "./xp-trend.dax?raw";

const connection = "kombatModel";

export function xpTrendQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 5. ARENA INSIGHTS
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "arena-insights.dax") -Content @'
EVALUATE
SUMMARIZECOLUMNS (
    dimarena[ArenaName],
    dimarena[Realm],
    dimarena[ArenaHazard],
    dimarena[LightingTheme],
    "Matches Played", [Matches Played],
    "Win Rate", [Win Rate],
    "Total KOs", [Total KOs],
    "Fatalities", [Fatalities],
    "Average Score", [Average Score],
    "Damage Efficiency", [Damage Efficiency]
)
ORDER BY [Matches Played] DESC
'@

Write-TextFile -Path (Join-Path $QueryFolder "arena-insights.ts") -Content @'
import query from "./arena-insights.dax?raw";

const connection = "kombatModel";

export function arenaInsightsQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 6. KAMEO INSIGHTS
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "kameo-insights.dax") -Content @'
EVALUATE
TOPN (
    21,
    SUMMARIZECOLUMNS (
        dimkameofighter[KameoFighterName],
        dimkameofighter[KameoGroup],
        dimkameofighter[Element],
        dimkameofighter[AssistStyle],
        dimkameofighter[PortraitImagePath],
        "Kameo Matches", [Kameo Matches],
        "Kameo Wins", [Kameo Wins],
        "Kameo Win Rate", [Kameo Win Rate],
        "Total KOs", [Total KOs],
        "Total Score", [Total Score]
    ),
    [Kameo Win Rate],
    DESC
)
ORDER BY [Kameo Win Rate] DESC
'@

Write-TextFile -Path (Join-Path $QueryFolder "kameo-insights.ts") -Content @'
import query from "./kameo-insights.dax?raw";

const connection = "kombatModel";

export function kameoInsightsQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 7. MATCHUP MATRIX
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "matchup-matrix.dax") -Content @'
EVALUATE
TOPN (
    250,
    SUMMARIZECOLUMNS (
        dimfighter[FighterName],
        dimopponentfighter[OpponentFighterName],
        "Matches Played", [Matches Played],
        "Wins", [Wins],
        "Losses", [Losses],
        "Win Rate", [Win Rate],
        "Total KOs", [Total KOs],
        "Damage Efficiency", [Damage Efficiency]
    ),
    [Matches Played],
    DESC
)
ORDER BY [Matches Played] DESC
'@

Write-TextFile -Path (Join-Path $QueryFolder "matchup-matrix.ts") -Content @'
import query from "./matchup-matrix.dax?raw";

const connection = "kombatModel";

export function matchupMatrixQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 8. MOVE / EVENT INSIGHTS
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "move-insights.dax") -Content @'
EVALUATE
TOPN (
    25,
    SUMMARIZECOLUMNS (
        dimmove[MoveName],
        dimmove[MoveType],
        dimmove[Element],
        dimmove[IsFinisher],
        "Combat Events", [Combat Events],
        "Event Damage", [Event Damage],
        "Event XP", [Event XP],
        "Event Score", [Event Score],
        "Event KOs", [Event KOs],
        "Event Fatalities", [Event Fatalities],
        "Event Brutalities", [Event Brutalities]
    ),
    [Combat Events],
    DESC
)
ORDER BY [Combat Events] DESC
'@

Write-TextFile -Path (Join-Path $QueryFolder "move-insights.ts") -Content @'
import query from "./move-insights.dax?raw";

const connection = "kombatModel";

export function moveInsightsQuery() {
    return {
        connection,
        query,
    };
}
'@

# =====================================================
# 9. INDEX EXPORT FILE
# =====================================================

Write-TextFile -Path (Join-Path $QueryFolder "index.ts") -Content @'
export { kpiSummaryQuery } from "./kpi-summary";
export { fighterGridQuery } from "./fighter-grid";
export { fighterProfileQuery } from "./fighter-profile";
export { xpTrendQuery } from "./xp-trend";
export { arenaInsightsQuery } from "./arena-insights";
export { kameoInsightsQuery } from "./kameo-insights";
export { matchupMatrixQuery } from "./matchup-matrix";
export { moveInsightsQuery } from "./move-insights";
'@

Write-Host ""
Write-Host "Created query files:"
Get-ChildItem $QueryFolder | Sort-Object Name | Select-Object Name, Length

Write-Host ""
Write-Host "========================================"
Write-Host "Step 7 query files created successfully."
Write-Host "========================================"
