# Assets — place your artwork here

This repository does **not** distribute the Mortal Kombat artwork or the landing
video (characters and art are Warner Bros. / NetherRealm Studios property). The app
is fully functional without them — every visual has an automatic SVG/initials
fallback — but it looks dramatically better with art in place.

Use artwork you have the rights to use (your own renders, licensed art, or assets
for private/personal use only).

---

## Folder structure the app expects

```
public/assets/
├── branding/
│   ├── mk-logo.webp          ← nav + favicon logo
│   └── mk-logo.png           ← fallback logo
├── backgrounds/
│   ├── home-arena.png        ← home stage backdrop / video poster
│   └── landing-video.mp4     ← home landing video (muted loop)
├── fighters/
│   └── <fighter-slug>/
│       ├── gallery/
│       │   ├── image-01.webp ← primary render (used everywhere)
│       │   └── image-02.webp ← secondary render (hover cycling)
│       ├── portrait.svg      ← generated fallback (already committed)
│       ├── fullbody.svg      ← generated fallback (already committed)
│       └── background.svg    ← generated fallback (already committed)
├── kameos/<kameo-slug>/      ← optional, see README in each folder
├── arenas/<arena-slug>/      ← optional, see README in each folder
└── skins/<fighter-slug>/     ← optional, see README in each folder
```

**Slug rule:** lowercase, hyphenated fighter name — `Johnny Cage` → `johnny-cage`,
`Sub-Zero` → `sub-zero`, `T-1000` → `t-1000-terminator`. The slug must match the
`FighterName` in your semantic model for images to resolve.

---

## Step-by-step: adding fighter art

### Option A — let the optimizer do the work (recommended)

1. Create `incoming-assets/fighters/<fighter-slug>/` at the repo root (this folder
   is gitignored — your originals never get committed).
2. Drop any number of `.png` / `.jpg` / `.webp` renders in. Transparent-background
   full-body renders look best. Files with `hero`, `render`, `action` or `pose` in
   the name are preferred automatically.
3. From `mortal-kombat-arena-intelligence/`, run:

   ```bash
   node tools/optimize-fighter-assets.mjs
   ```

   This picks the best images per fighter, resizes to max 900×1200, converts to
   WebP (quality 68) and writes them to `public/assets/fighters/<slug>/gallery/`.

   Tunable via env vars: `MAX_IMAGES_PER_FIGHTER` (default 3), `WEBP_QUALITY` (68),
   `MAX_WIDTH` (900), `MAX_HEIGHT` (1200).

### Option B — place files manually

Put `image-01.webp` (and optionally `image-02.webp`) directly into
`public/assets/fighters/<slug>/gallery/`. Keep them under ~200 KB each.

---

## Step-by-step: home page media

1. **Backdrop:** save a dark, moody arena image as `backgrounds/home-arena.png`
   (≈1920×1080). It doubles as the video poster.
2. **Landing video:** save an H.264 `.mp4` as `backgrounds/landing-video.mp4`.
   Keep it short (5–15 s loop) and small (3–5 MB) — it autoplays muted behind the
   home stage and loops forever.
3. **Logo:** save your logo as `branding/mk-logo.webp` (+ a `.png` copy). ~200×200
   with transparency works well.

---

## Verifying

- Open `public/design-preview.html` in any browser — it uses the same asset paths,
  no Fabric required.
- Or run the app (`npm run dev` + `npm run test:fabric`) — any fighter without art
  shows its SVG/initials fallback, so missing files never break the UI.
