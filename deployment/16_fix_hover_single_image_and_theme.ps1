# =====================================================
# Step 13 - Fix Hover Image Fallback + Add Theme Support
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
Backup-File (Join-Path $ComponentsFolder "AppNavigation.tsx")
Backup-File (Join-Path $ComponentsFolder "MkAppShell.tsx")
Backup-File (Join-Path $ComponentsFolder "HomeLanding.tsx")
Backup-File $StylesFile

# =====================================================
# FighterShowcaseVisual.tsx
# Fix:
# - Does not disappear when only 1 image exists
# - Does not cycle if there is only 1 valid image
# - Falls back safely to SVG or initials
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

        const preferred =
            mode === "profile"
                ? [assets?.hero ?? "", assets?.portrait ?? "", ...gallery]
                : [assets?.hero ?? "", ...gallery];

        return unique([
            ...preferred,
            imagePath ?? "",
            toSvgFallback(imagePath),
        ]).filter((src) => !failedSources.has(src));
    }, [assets, imagePath, failedSources, mode]);

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
        }, 900);

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
# AppNavigation.tsx
# Add dark/light theme toggle
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "AppNavigation.tsx") -Content @'
export type AppTab = "home" | "dashboard" | "roster" | "compare";
export type AppTheme = "dark" | "light";

type AppNavigationProps = {
    activeTab: AppTab;
    activeTheme: AppTheme;
    onChange: (tab: AppTab) => void;
    onToggleTheme: () => void;
};

const navItems: Array<{ id: AppTab; label: string; description: string }> = [
    { id: "home", label: "Home", description: "Enter the arena" },
    { id: "dashboard", label: "Command Center", description: "Executive KPIs" },
    { id: "roster", label: "Roster", description: "Choose your fighter" },
    { id: "compare", label: "Compare", description: "Fighter vs fighter" },
];

export function AppNavigation({
    activeTab,
    activeTheme,
    onChange,
    onToggleTheme,
}: AppNavigationProps) {
    return (
        <header className="mk-top-nav">
            <button type="button" className="mk-nav-brand" onClick={() => onChange("home")}>
                <img
                    src="/assets/branding/mk-logo.png"
                    alt="Mortal Kombat"
                    className="mk-brand-logo"
                    onError={(event) => {
                        event.currentTarget.style.display = "none";
                    }}
                />

                <span className="mk-brand-text">
                    <strong>Arena Intelligence</strong>
                    <em>Microsoft Fabric + Rayfin</em>
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

            <button type="button" className="mk-theme-toggle" onClick={onToggleTheme}>
                {activeTheme === "dark" ? "Light Mode" : "Dark Mode"}
            </button>
        </header>
    );
}
'@

# =====================================================
# MkAppShell.tsx
# Theme state and data-theme attribute
# =====================================================

Write-TextFile -Path (Join-Path $ComponentsFolder "MkAppShell.tsx") -Content @'
import { useState } from "react";
import { AppNavigation, type AppTab, type AppTheme } from "./AppNavigation";
import { HomeLanding } from "./HomeLanding";
import { DashboardTab } from "./DashboardTab";
import { FighterExplorer } from "./FighterExplorer";
import { CompareTab } from "./CompareTab";

export function MkAppShell() {
    const [activeTab, setActiveTab] = useState<AppTab>("home");
    const [activeTheme, setActiveTheme] = useState<AppTheme>("dark");

    const toggleTheme = () => {
        setActiveTheme((current) => (current === "dark" ? "light" : "dark"));
    };

    return (
        <main
            className={`mk-app ${activeTab === "home" ? "mk-app--home" : ""}`}
            data-theme={activeTheme}
        >
            <AppNavigation
                activeTab={activeTab}
                activeTheme={activeTheme}
                onChange={setActiveTab}
                onToggleTheme={toggleTheme}
            />

            {activeTab === "home" ? <HomeLanding onNavigate={setActiveTab} /> : null}
            {activeTab === "dashboard" ? <DashboardTab /> : null}
            {activeTab === "roster" ? <FighterExplorer /> : null}
            {activeTab === "compare" ? <CompareTab /> : null}
        </main>
    );
}
'@

# =====================================================
# HomeLanding.tsx
# Compact no-scroll home with cinematic fire
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

            <div className="mk-home-card-grid mk-home-card-grid-fit">
                <article>
                    <span>01</span>
                    <h3>Semantic Model</h3>
                    <p>Live KPIs and ranks from Fabric.</p>
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
                    <p>Hover cards to cycle images.</p>
                </article>
            </div>
        </section>
    );
}
'@

# =====================================================
# CSS patch
# =====================================================

Add-Content -Path $StylesFile -Value @'

/* =====================================================
   Step 13 - Home fit, fire animation, hover fix, light/dark theme
   ===================================================== */

.mk-app[data-theme="light"] {
    --mk-bg: #fff7ed;
    --mk-bg-2: #fee2c6;
    --mk-panel: rgba(255, 255, 255, 0.82);
    --mk-panel-strong: rgba(255, 255, 255, 0.94);
    --mk-border: rgba(180, 83, 9, 0.26);
    --mk-text: #26130c;
    --mk-muted: #7c5a48;
    --mk-gold: #b45309;
    --mk-red: #b91c1c;
    --mk-orange: #ea580c;
    --mk-ice: #0369a1;
    --mk-green: #047857;
    --mk-purple: #7e22ce;

    background:
        radial-gradient(circle at 15% 10%, rgba(234, 88, 12, 0.14), transparent 32%),
        radial-gradient(circle at 88% 8%, rgba(185, 28, 28, 0.10), transparent 28%),
        linear-gradient(135deg, #fff7ed 0%, #ffedd5 45%, #fef3c7 100%);
}

.mk-theme-toggle {
    appearance: none;
    border: 1px solid rgba(248, 184, 78, 0.42);
    border-radius: 999px;
    padding: 11px 15px;
    color: var(--mk-gold);
    background: rgba(0, 0, 0, 0.24);
    font-weight: 900;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    cursor: pointer;
    white-space: nowrap;
}

.mk-app[data-theme="light"] .mk-theme-toggle {
    background: rgba(255, 255, 255, 0.72);
}

.mk-app--home {
    min-height: 100vh;
    overflow: hidden;
}

.mk-home-cinematic {
    position: relative;
    height: calc(100vh - 110px);
    min-height: 610px;
    overflow: hidden;
    display: grid;
    grid-template-rows: minmax(0, 1fr) auto;
    gap: 12px;
}

.mk-home-hero-fit {
    min-height: 0;
    height: 100%;
    grid-template-columns: minmax(0, 1fr) 300px;
    padding: clamp(24px, 3vw, 42px);
    z-index: 1;
}

.mk-home-hero-fit .mk-home-copy h1 {
    font-size: clamp(50px, 8vw, 112px);
}

.mk-home-hero-fit .mk-home-copy p {
    font-size: 17px;
    max-width: 650px;
}

.mk-home-card-grid-fit {
    position: relative;
    z-index: 2;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 12px;
}

.mk-home-card-grid-fit article {
    min-height: 96px;
    padding: 14px;
}

.mk-home-card-grid-fit h3 {
    margin: 4px 0 4px;
    font-size: 15px;
}

.mk-home-card-grid-fit p {
    margin: 0;
    font-size: 12px;
}

.mk-fire-layer {
    position: absolute;
    inset: auto -10% -26% -10%;
    height: 45%;
    pointer-events: none;
    z-index: 0;
    background:
        radial-gradient(circle at 12% 100%, rgba(255, 90, 31, 0.42), transparent 30%),
        radial-gradient(circle at 32% 100%, rgba(248, 184, 78, 0.32), transparent 32%),
        radial-gradient(circle at 58% 100%, rgba(215, 25, 32, 0.34), transparent 35%),
        radial-gradient(circle at 84% 100%, rgba(255, 90, 31, 0.38), transparent 28%);
    filter: blur(11px);
    animation: mk-live-fire 2.7s ease-in-out infinite alternate;
}

.mk-ember-field {
    position: absolute;
    inset: 0;
    pointer-events: none;
    z-index: 0;
    background:
        radial-gradient(circle at 12% 70%, rgba(248, 184, 78, 0.22) 0 2px, transparent 3px),
        radial-gradient(circle at 32% 38%, rgba(255, 90, 31, 0.18) 0 2px, transparent 3px),
        radial-gradient(circle at 72% 24%, rgba(248, 184, 78, 0.18) 0 2px, transparent 3px),
        radial-gradient(circle at 86% 66%, rgba(215, 25, 32, 0.18) 0 2px, transparent 3px);
    animation: mk-embers 8s linear infinite;
}

@keyframes mk-live-fire {
    from {
        transform: translateY(22px) scaleX(1);
        opacity: 0.68;
    }
    to {
        transform: translateY(-4px) scaleX(1.04);
        opacity: 1;
    }
}

@keyframes mk-embers {
    from {
        transform: translateY(35px);
        opacity: 0.45;
    }
    to {
        transform: translateY(-20px);
        opacity: 0.85;
    }
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

.mk-app[data-theme="light"] .mk-panel,
.mk-app[data-theme="light"] .mk-kpi-card,
.mk-app[data-theme="light"] .mk-fighter-card,
.mk-app[data-theme="light"] .mk-home-card-grid article {
    background:
        radial-gradient(circle at top left, rgba(234, 88, 12, 0.10), transparent 34%),
        rgba(255, 255, 255, 0.82);
    color: var(--mk-text);
}

@media (max-width: 1100px) {
    .mk-app--home {
        overflow: auto;
    }

    .mk-home-cinematic {
        height: auto;
        min-height: 0;
    }

    .mk-home-hero-fit {
        grid-template-columns: 1fr;
        height: auto;
    }

    .mk-home-card-grid-fit {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .mk-top-nav {
        position: static;
    }
}

@media (max-width: 760px) {
    .mk-home-card-grid-fit {
        grid-template-columns: 1fr;
    }
}
'@

Write-Host "Step 13 patch applied."