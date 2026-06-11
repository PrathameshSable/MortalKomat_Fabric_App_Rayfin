# =====================================================
# Step 8 Patch - Fix Fighter Profile UI Interactions
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$ComponentsFolder = Join-Path $AppRoot "src\components\kombat"
$StylesFile = Join-Path $AppRoot "src\styles\mk-theme.css"

Write-Host "========================================"
Write-Host "Fixing fighter profile UI interactions"
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

function Backup-File {
    param (
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
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "WROTE: $Path"
}

# =====================================================
# Backups
# =====================================================

Backup-File (Join-Path $ComponentsFolder "FighterCard3D.tsx")
Backup-File (Join-Path $ComponentsFolder "FighterProfilePanel.tsx")
Backup-File (Join-Path $ComponentsFolder "FighterGrid.tsx")
Backup-File $StylesFile

# =====================================================
# FighterCard3D.tsx
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterCard3D.tsx") -Content @'
import { useState } from "react";
import type { CSSProperties } from "react";
import type { FighterRow } from "./types";

type FighterCard3DProps = {
    fighter: FighterRow;
    isSelected?: boolean;
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

export function FighterCard3D({ fighter, isSelected = false, onSelect }: FighterCard3DProps) {
    const [imageFailed, setImageFailed] = useState(false);

    const style = {
        "--fighter-primary": fighter.primaryColor || "#ff5a1f",
        "--fighter-secondary": fighter.secondaryColor || "#120705",
    } as CSSProperties;

    const showImage = Boolean(fighter.fullBodyImagePath) && !imageFailed;

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
                {showImage ? (
                    <img
                        src={fighter.fullBodyImagePath}
                        alt={fighter.fighterName}
                        className="mk-fighter-card__image"
                        loading="lazy"
                        onError={() => setImageFailed(true)}
                    />
                ) : (
                    <div className="mk-fighter-card__fallback">
                        {initials(fighter.fighterName)}
                    </div>
                )}
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

# =====================================================
# FighterProfilePanel.tsx
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterProfilePanel.tsx") -Content @'
import { useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterProfileQuery } from "@/queries/kombat";
import type { FighterRow } from "./types";

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
    const [imageFailed, setImageFailed] = useState(false);

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
                    {fighter.fullBodyImagePath && !imageFailed ? (
                        <img
                            src={fighter.fullBodyImagePath}
                            alt={fighter.fighterName}
                            onError={() => setImageFailed(true)}
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

            <div className="mk-profile-hint">
                Select any other fighter card below to switch profile.
            </div>
        </section>
    );
}
'@

# =====================================================
# FighterGrid.tsx
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "FighterGrid.tsx") -Content @'
import { useEffect, useMemo, useRef, useState } from "react";
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

    useEffect(() => {
        if (selectedFighter && profileRef.current) {
            profileRef.current.scrollIntoView({
                behavior: "smooth",
                block: "start",
            });
        }
    }, [selectedFighter?.fighterName]);

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
                <div ref={profileRef} className="mk-profile-shell">
                    <FighterProfilePanel
                        key={selectedFighter.fighterName}
                        fighter={selectedFighter}
                        onClose={() => setSelectedFighter(null)}
                    />
                </div>
            ) : null}

            <div className="mk-fighter-grid">
                {fighters.map((fighter) => (
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
# CSS PATCH
# =====================================================

Add-Content -Path $StylesFile -Value @'

/* =====================================================
   Step 8 Patch - Fighter profile interaction fixes
   ===================================================== */

.mk-profile-shell {
    scroll-margin-top: 24px;
    margin-bottom: 24px;
}

.mk-profile-panel {
    position: relative;
    z-index: 1;
}

.mk-profile-toolbar {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 18px;
    margin-bottom: 22px;
}

.mk-profile-toolbar h2 {
    margin: 0;
    font-size: 38px;
    line-height: 1;
    text-transform: uppercase;
    letter-spacing: -0.04em;
}

.mk-profile-toolbar p {
    margin: 10px 0 0;
    color: var(--mk-muted);
}

.mk-profile-close {
    appearance: none;
    border: 1px solid rgba(248, 184, 78, 0.42);
    border-radius: 999px;
    padding: 10px 16px;
    color: var(--mk-gold);
    background: rgba(0, 0, 0, 0.36);
    font-weight: 800;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    cursor: pointer;
    transition: transform 160ms ease, background 160ms ease, border-color 160ms ease;
}

.mk-profile-close:hover {
    transform: translateY(-2px);
    background: rgba(255, 90, 31, 0.16);
    border-color: rgba(248, 184, 78, 0.78);
}

.mk-profile-hint {
    margin-top: 18px;
    color: var(--mk-muted);
    font-size: 13px;
}

.mk-fighter-card.is-selected {
    border-color: rgba(248, 184, 78, 0.9);
    box-shadow:
        0 30px 90px rgba(0, 0, 0, 0.72),
        0 0 56px color-mix(in srgb, var(--fighter-primary) 44%, transparent),
        inset 0 1px 0 rgba(255, 255, 255, 0.12);
}

.mk-fighter-card:focus-visible,
.mk-profile-close:focus-visible {
    outline: 3px solid rgba(248, 184, 78, 0.78);
    outline-offset: 4px;
}

@media (max-width: 860px) {
    .mk-profile-toolbar {
        flex-direction: column;
    }
}
'@

Write-Host ""
Write-Host "========================================"
Write-Host "Fighter profile interaction patch applied."
Write-Host "========================================"
Write-Host "Next:"
Write-Host "cd $AppRoot"
Write-Host "npm run build:fabric"