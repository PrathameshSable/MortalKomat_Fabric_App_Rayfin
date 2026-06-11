# Step 10 - Home Page, Navigation, Slicers and Fighter Compare

## What this step adds

This patch adds:

- Home landing page
- Top navigation
- Dashboard / Command Center tab
- Roster tab with slicers
- Fighter A vs Fighter B compare tab
- Fighter stat comparison bars
- Head-to-head matchup snapshot

## Where to copy the script

Copy:

```text
10_create_home_navigation_compare_ui.ps1
```

to:

```text
C:\Projects\mk-arena-intelligence\deployment
```

## How to run

```powershell
cd C:\Projects\mk-arena-intelligence

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\deployment\10_create_home_navigation_compare_ui.ps1
```

Then build:

```powershell
cd C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence

npm run build:fabric
```

Then test:

```powershell
npm run dev
```

Open through Fabric using:

```text
&devUri=http://localhost:5173
```

## Expected result

You should see:

- Home page
- Navigation tabs
- Enter the Arena CTA
- Choose Your Fighter CTA
- Command Center tab
- Roster tab with slicers
- Compare tab with Fighter A vs Fighter B dropdowns
