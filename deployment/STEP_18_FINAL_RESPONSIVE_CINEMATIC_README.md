# Step 18 - Final Responsive Cinematic UI Patch

## Fixes

- Light mode command center colors
- Home page cinematic background support
- Home page responsive fit
- Native white dropdown issue in compare page
- Compare page fighter image cutting
- Compare page unnecessary scroll
- Custom fighter picker dropdown
- Arena image background support

## Background image

Put your fourth image here:

```text
C:\Projects\mk-arena-intelligence\incoming-assets\backgrounds
```

Example:

```text
C:\Projects\mk-arena-intelligence\incoming-assets\backgrounds\HaviksCtiadel_Inactive_Center.png
```

The script copies the largest image from that folder into:

```text
public/assets/backgrounds/home-arena.png
```

The CSS then uses it as a cinematic background with animated pan, fire and ember overlays.

## Run

```powershell
cd C:\Projects\mk-arena-intelligence

.\deployment\18_final_responsive_cinematic_patch.ps1
```

Then:

```powershell
cd C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence

npm run build:fabric
npm run dev
```

Open via Fabric with:

```text
&devUri=http://localhost:5173
```
