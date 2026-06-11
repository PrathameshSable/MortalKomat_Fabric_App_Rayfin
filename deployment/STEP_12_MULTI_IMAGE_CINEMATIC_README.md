# Step 12 - Multi-image Fighter Gallery and Cinematic UI

## What this adds

- Import multiple PNG files per fighter
- Create `/public/assets/fighters/<fighter>/gallery`
- Create a central `/public/assets/fighters/_fighter-assets.json`
- Cycle images on fighter-card hover
- Smaller fighter cards
- No-scroll cinematic home page on desktop
- Fire/glow effects
- KPI card icons
- Premium 3D fighter-card effects

## Recommended staging folder

Put your approved assets here:

```text
C:\Projects\mk-arena-intelligence\incoming-assets\fighters\scorpion\K1_ScorpionRender_Hero-pose.png
C:\Projects\mk-arena-intelligence\incoming-assets\fighters\scorpion\K1_ScorpionSeasonOfFire.png
C:\Projects\mk-arena-intelligence\incoming-assets\fighters\sub-zero\...
```

Put branding here:

```text
C:\Projects\mk-arena-intelligence\incoming-assets\branding\mk-logo.png
C:\Projects\mk-arena-intelligence\incoming-assets\branding\mk-dragon-emblem.png
```

## Run scripts

```powershell
cd C:\Projects\mk-arena-intelligence

.\deployment\14_import_multi_image_fighter_assets.ps1 -Overwrite

.\deployment\15_apply_cinematic_gallery_ui.ps1
```

Then:

```powershell
cd C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence

npm run build:fabric

npm run dev
```

Open through Fabric with:

```text
&devUri=http://localhost:5173
```

## Expected result

- Hover a fighter card to cycle through available PNG files.
- Home page should look more cinematic and fit better on desktop.
- KPI cards have icons.
- Fighter cards are smaller and more dynamic.
