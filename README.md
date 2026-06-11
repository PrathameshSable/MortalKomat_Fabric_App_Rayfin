# MK Arena Intelligence — a Microsoft Fabric + Rayfin Data App

A cinematic, Mortal Kombat–themed analytics app built entirely on **Microsoft Fabric**:
a Power BI **semantic model** serves live DAX queries to a **React 19** front end through
the **Rayfin** data-app platform, deployed as a Fabric workspace item and rendered inside
the Fabric portal on a fixed **1280 × 720 app canvas**.

> 🎮 35 fighters · 15,000 matches · live KPIs, rankings, head-to-head matchups and a
> fighter-vs-fighter Tale of the Tape — every number on screen is a DAX query against
> the semantic model.

---

## The four screens

| Tab | What it does |
|---|---|
| **Home** | "Kombat Spotlight" — a landing video plays behind an auto-cycling stage featuring the top-5 fighters by Total Score (live query), each with a signature-color nameplate, a clickable leaderboard rail, and a broadcast-style KPI ticker. |
| **Command Center** | Executive KPI strip with count-up animation, slicers (realm, minimum matches, kameo search) that filter the arena & kameo tables client-side, internally-scrolling tables with sticky headers. |
| **Roster** | A game-style character-select grid — all 35 fighters on one screen. Hover zooms a tile; selecting slides in a profile pane with full stats plus head-to-head intel: **whom this fighter defeats most** and **whom they're defeated by most** (from the matchup-matrix query). Click a rival to jump to their profile. |
| **Compare** | Single-screen VS layout — two fighters full-height, animated "Tale of the Tape" between them, gold glow on each metric's winner. |

## Architecture

```
Fabric Lakehouse (dim/fact tables)
        │
        ▼
Power BI Semantic Model  ←  DAX measures (semantic-model/, tmdl/)
        │   connection alias: kombatModel (fabric.yaml)
        ▼
React app (Vite + TS)  ←  src/queries/kombat/*.dax  via useSemanticModelQuery
        │
        ▼
Rayfin item in your Fabric workspace  ←  `npx rayfin up`
(static hosting + Fabric-authenticated data plane)
```

**Stack:** React 19 · TypeScript · Vite 7 · framer-motion · `@microsoft/fabric-app-data` ·
`@microsoft/rayfin-*` · Anton + Saira typography · hand-rolled CSS theme (no UI framework).

## Repository layout

```
mortal-kombat-arena-intelligence/   the app itself (see EXECUTION_GUIDE.md)
  src/components/kombat/            all UI components (shell, home, dashboard, roster, compare)
  src/queries/kombat/               one .dax file per data need + thin TS wrappers
  src/hooks/use-semantic-model-query.ts   the Fabric query hook
  src/styles/                       mk-theme.css (base) + mk-spotlight.css (1280×720 canvas system)
  public/assets/                    asset folder structure + placement guide (artwork NOT included — bring your own)
  public/design-preview.html        standalone HTML design mock (no Fabric needed — just open it)
  fabric.yaml.example               semantic-model connection template (copy to fabric.yaml with YOUR ids)
  rayfin/rayfin.yml.example         Rayfin app manifest template (copy to rayfin/rayfin.yml)
deployment/                         PowerShell scripts used while building the project
semantic-model/                     DAX measure definitions for the model
tmdl/                               TMDL scripts for measure formatting
fabric-notebooks/                   placeholders for the lakehouse table-builder notebook
```

## Quick start

Full fork-to-running instructions live in **[EXECUTION_GUIDE.md](EXECUTION_GUIDE.md)**. The short version:

```bash
git clone https://github.com/PrathameshSable/MortalKomat_Fabric_App_Rayfin.git
cd MortalKomat_Fabric_App_Rayfin/mortal-kombat-arena-intelligence
npm install

# point fabric.yaml at YOUR semantic model, then:
npx fabric-app-data generate -o src/fabric.generated.ts
npx rayfin login
npx rayfin up          # creates the Rayfin item in your workspace + deploys
npm run dev            # local dev server (renders inside the Fabric portal)
npm run test:fabric    # opens the portal pointed at your dev server
```

> ⚠️ Rayfin data apps **only render inside the Microsoft Fabric portal**. Opening
> `localhost:5173` directly shows a "Can't open this app outside Fabric" guard — that's
> expected. Use `npm run test:fabric` for the dev loop.

## Design notes

- The Fabric app canvas is a fixed **1280 × 720** viewport — the entire UI is designed
  to that frame with **zero page scrolling** (only tables and the roster profile pane
  scroll internally). `src/styles/mk-spotlight.css` is the canvas design system.
- `public/design-preview.html` is the standalone design mock used to iterate on the UI
  before wiring it to live data — open it in any browser, no Fabric required.

## Disclaimers

- This is a **fan-made demo project for learning Microsoft Fabric + Rayfin**. Mortal
  Kombat characters and names are the property of Warner Bros. Entertainment /
  NetherRealm Studios; no affiliation or endorsement is implied. **Artwork and video
  are not distributed with this repo** — bring your own (see
  [public/assets/README.md](mortal-kombat-arena-intelligence/public/assets/README.md));
  the app renders SVG fallbacks for any missing art.
- Personal tenant/workspace configuration is also excluded — copy the committed
  `*.example` files and fill in your own ids (see the guide).
- Code is MIT-licensed (see [LICENSE](mortal-kombat-arena-intelligence/LICENSE), derived
  from Microsoft's Fabric app starter template).
