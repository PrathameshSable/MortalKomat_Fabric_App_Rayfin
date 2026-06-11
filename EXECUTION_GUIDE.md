# Execution Guide — fork to running app

This guide takes you from forking the repo to a working deployment of **MK Arena
Intelligence** in your own Microsoft Fabric workspace. Expect 30–60 minutes the first
time, most of it in the one-time Fabric data setup.

---

## 1. Prerequisites

| Requirement | Notes |
|---|---|
| **Microsoft Fabric workspace** | On a Fabric capacity (a [Fabric trial](https://learn.microsoft.com/fabric/get-started/fabric-trial) works). You need permission to create items in the workspace. |
| **Node.js 20+** | `node -v` to check. |
| **Git** | Plus a GitHub account if you're forking. |
| **A browser signed into Fabric** | The app renders inside the Fabric portal — that's where you'll test it. |

No global CLI installs are needed — the Rayfin CLI and Fabric tooling run via `npx`
from the project's own dev-dependencies.

## 2. Fork and clone

```bash
# fork https://github.com/PrathameshSable/MortalKomat_Fabric_App_Rayfin on GitHub, then:
git clone https://github.com/<your-username>/MortalKomat_Fabric_App_Rayfin.git
cd MortalKomat_Fabric_App_Rayfin/mortal-kombat-arena-intelligence
npm install
```

## 3. Set up the data (one-time, in Fabric)

The app queries a Power BI **semantic model** through the connection alias
`kombatModel`. You need a model in your workspace that exposes the tables and measures
below. The repo's `semantic-model/dax-query-view/01_define_measures_for_model.dax`
contains the measure definitions; `fabric-notebooks/` is the placeholder location for
the lakehouse table-builder notebook.

**Expected model schema** (what the app's queries in `src/queries/kombat/*.dax` reference):

| Table | Columns used by the app |
|---|---|
| `dimfighter` | FighterName, RosterGroup, Realm, Element, CombatStyle, Alignment, Difficulty, PrimaryColor, SecondaryColor, PortraitImagePath, FullBodyImagePath, CardBackgroundPath, Model3DPath |
| `dimarena` | ArenaName, Realm, ArenaHazard, LightingTheme |
| `dimkameofighter` | KameoFighterName, KameoGroup, Element, AssistStyle, PortraitImagePath |
| `dimopponentfighter` | OpponentFighterName |
| *(fact table)* | match-level facts the measures aggregate |

**Measures referenced:** `[Total Matches]`, `[Matches Played]`, `[Wins]`, `[Losses]`,
`[Win Rate]`, `[Total XP]`, `[Average XP Per Match]`, `[Total Score]`, `[Average Score]`,
`[Total KOs]`, `[KO Rate]`, `[Fatalities]`, `[Brutalities]`, `[Perfect Rounds]`,
`[Damage Efficiency]`, `[Combat Events]`, `[Kameo Matches]`, `[Kameo Wins]`,
`[Kameo Win Rate]`, `[Fighter Rank by Score]`.

Steps:

1. In your Fabric workspace, create a **Lakehouse** and load the dim/fact tables
   (any data matching the schema above works — the fun is in the theming, the app
   doesn't care if the numbers are synthetic).
2. Create a **semantic model** from those tables (the lakehouse's default model or a
   custom one).
3. Open the model's **DAX query view** and run
   `semantic-model/dax-query-view/01_define_measures_for_model.dax` to define the
   measures, then save them to the model.
4. Note the model's **workspace id** and **item id** — both are GUIDs visible in the
   model's URL: `…/groups/<workspaceId>/datasets/<itemId>/…`

> 💡 The fighter/arena/kameo **names** in your data should match the asset folder slugs
> under `public/assets/fighters/<slug>/` (e.g. `Johnny Cage` → `johnny-cage`) so images
> resolve. `PortraitImagePath` / `FullBodyImagePath` columns can also point directly at
> asset paths.

## 4. Point the app at your model

Personal tenant/workspace configuration is **not** committed to this repo — you create
it from the `.example` templates:

```bash
# inside mortal-kombat-arena-intelligence/
cp fabric.yaml.example fabric.yaml
cp rayfin/rayfin.yml.example rayfin/rayfin.yml
```

Then edit `fabric.yaml` with your own ids:

```yaml
activeProfile: default
profiles:
  default:
    semanticModels:
      kombatModel:
        workspaceId: <YOUR workspace guid>
        itemId: <YOUR semantic model guid>
```

Then regenerate the typed connection file:

```bash
npx fabric-app-data generate -o src/fabric.generated.ts
```

## 5. Add the artwork (optional but recommended)

Artwork and the landing video are **not distributed** with this repo (Mortal Kombat
art is Warner Bros. / NetherRealm property). The app runs fine without it — every
visual has an SVG/initials fallback — but for the full effect, follow the
step-by-step placement guide in
[`public/assets/README.md`](mortal-kombat-arena-intelligence/public/assets/README.md):

- fighter renders → `public/assets/fighters/<slug>/gallery/image-01.webp`
  (or drop originals in `incoming-assets/fighters/<slug>/` and run
  `node tools/optimize-fighter-assets.mjs`)
- home backdrop + landing video → `public/assets/backgrounds/`
- logo → `public/assets/branding/`

## 6. Create your Rayfin item and deploy

```bash
npx rayfin login     # sign in with the account that owns the workspace
npx rayfin up        # builds (npm run build:fabric) and deploys
```

`rayfin up` creates a **Rayfin item** in your workspace, uploads the static build, and
writes your environment to `rayfin/.env` + `rayfin/.deployments.json` (both gitignored —
see `rayfin/.env.example`). The command prints:

- the **Fabric portal link** to your deployed app, and
- a public **hosting URL**.

## 7. Local development loop

```bash
npm run dev           # starts Vite on http://localhost:5173
npm run test:fabric   # opens the Fabric portal wired to your dev server
```

> ⚠️ **The app will not render at `localhost:5173` directly** — Rayfin data apps must
> run inside the Fabric portal (you'll see *"Can't open this app outside Fabric"*).
> Always go through `npm run test:fabric` (or your deployed portal link).

Other scripts:

```bash
npm test              # vitest unit tests
npm run lint          # eslint
npm run build         # production build into dist/
```

To ship changes: `npx rayfin up -y`.

## 8. How the code is organized

| Path | Purpose |
|---|---|
| `src/components/kombat/MkAppShell.tsx` | Tab shell + framer-motion page transitions |
| `src/components/kombat/HomeLanding.tsx` | Kombat Spotlight home (video, top-5 stage, ticker) |
| `src/components/kombat/DashboardTab.tsx` | Command Center (KPI strip, slicers, tables) |
| `src/components/kombat/FighterExplorer.tsx` | Character-select grid + profile pane + matchups |
| `src/components/kombat/CompareTab.tsx` | VS screen with Tale of the Tape |
| `src/queries/kombat/*.dax` | Every DAX query the app runs (edit these to change the data) |
| `src/hooks/use-semantic-model-query.ts` | The query hook (SDK caching, error handling) |
| `src/styles/mk-spotlight.css` | The fixed 1280×720 canvas design system |
| `public/design-preview.html` | Standalone design mock — open in any browser, no Fabric |

**The 1280×720 rule:** the Fabric app canvas is a fixed viewport. Every page is a
`height: 100%` grid that must fit with no page scrolling — if you add content, give it
an internally-scrolling panel (`.mk-scroll`) rather than letting the page grow.

## 9. Customizing

- **Different theme/universe:** swap the images under `public/assets/`, the landing
  video at `public/assets/backgrounds/landing-video.mp4`, and the color tokens at the
  top of `src/styles/mk-theme.css` (`--mk-*` variables).
- **Different data:** keep the table/measure names and the app works unchanged; or
  edit the `.dax` files in `src/queries/kombat/` and adjust the row-index mappers
  (`fighterRowMapper.ts`, the `row[n]` indexes in components) to match.
- **More pages:** add a tab id in `AppNavigation.tsx`, render it in `MkAppShell.tsx`,
  and follow the fixed-canvas grid pattern of an existing page.

## 10. Troubleshooting

| Symptom | Fix |
|---|---|
| *"Can't open this app outside Fabric"* | Expected outside the portal. Use `npm run test:fabric` or the portal deep link from `rayfin up`. |
| Tables/KPIs stuck on "Loading…" | The model connection failed: re-check `fabric.yaml` ids, re-run `npx fabric-app-data generate`, confirm your account can read the model. |
| Query errors mentioning a measure name | A measure from §3 is missing in your model — re-run the measures script. |
| Fighter tiles show initials instead of art | The fighter's name doesn't map to an asset folder slug — rename the folder under `public/assets/fighters/` or fix the image-path columns. |
| `rayfin up` auth errors | `npx rayfin logout` then `npx rayfin login`; make sure the account has rights to create items in the workspace. |
| Blank video on Home | The browser blocked autoplay — the arena poster image shows instead; the app is otherwise unaffected. |

---

*Fan-made demo for learning Microsoft Fabric + Rayfin. Mortal Kombat characters and
artwork © Warner Bros. Entertainment / NetherRealm Studios — included for demonstration
only.*
