# =====================================================
# Step 9 - Create Placeholder Fighter Assets
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$PublicAssets = Join-Path $AppRoot "public\assets"

$FightersRoot = Join-Path $PublicAssets "fighters"
$KameosRoot = Join-Path $PublicAssets "kameos"
$UiRoot = Join-Path $PublicAssets "ui"

New-Item -Path $FightersRoot -ItemType Directory -Force | Out-Null
New-Item -Path $KameosRoot -ItemType Directory -Force | Out-Null
New-Item -Path $UiRoot -ItemType Directory -Force | Out-Null

function Get-Initials {
    param([string]$Name)

    return (($Name -split " " | ForEach-Object { $_.Substring(0,1) }) -join "").Substring(0, [Math]::Min(2, (($Name -split " " | ForEach-Object { $_.Substring(0,1) }) -join "").Length)).ToUpper()
}

function Write-FighterSvg {
    param(
        [string]$Folder,
        [string]$FileName,
        [string]$Name,
        [string]$Element,
        [string]$Primary,
        [string]$Secondary,
        [string]$Type
    )

    $initials = Get-Initials -Name $Name
    $path = Join-Path $Folder $FileName

    if ($Type -eq "fullbody") {
        $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="900" height="1200" viewBox="0 0 900 1200">
  <defs>
    <radialGradient id="glow" cx="50%" cy="35%" r="60%">
      <stop offset="0%" stop-color="$Primary" stop-opacity="0.95"/>
      <stop offset="45%" stop-color="$Primary" stop-opacity="0.38"/>
      <stop offset="100%" stop-color="#050302" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="body" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="$Primary"/>
      <stop offset="45%" stop-color="$Secondary"/>
      <stop offset="100%" stop-color="#050302"/>
    </linearGradient>
    <filter id="blurGlow">
      <feGaussianBlur stdDeviation="18" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <filter id="shadow">
      <feDropShadow dx="0" dy="30" stdDeviation="22" flood-color="#000000" flood-opacity="0.82"/>
    </filter>
  </defs>

  <rect width="900" height="1200" fill="transparent"/>
  <ellipse cx="450" cy="560" rx="360" ry="470" fill="url(#glow)" filter="url(#blurGlow)"/>

  <g opacity="0.45">
    <path d="M130 1020 C260 950 640 950 770 1020" stroke="$Primary" stroke-width="4" fill="none"/>
    <path d="M170 980 C300 910 600 910 730 980" stroke="$Primary" stroke-width="2" fill="none"/>
    <path d="M210 940 C340 880 560 880 690 940" stroke="$Primary" stroke-width="2" fill="none"/>
  </g>

  <g filter="url(#shadow)">
    <path d="M450 130
             C555 130 635 210 635 320
             C635 390 600 450 545 485
             C650 535 710 645 710 790
             C710 935 620 1040 450 1040
             C280 1040 190 935 190 790
             C190 645 250 535 355 485
             C300 450 265 390 265 320
             C265 210 345 130 450 130Z"
          fill="url(#body)" opacity="0.92"/>

    <path d="M330 560 L210 830 L320 815 L410 585 Z" fill="#020202" opacity="0.62"/>
    <path d="M570 560 L690 830 L580 815 L490 585 Z" fill="#020202" opacity="0.62"/>
    <path d="M370 560 L330 1040 L430 1040 L455 620 Z" fill="#050302" opacity="0.70"/>
    <path d="M530 560 L570 1040 L470 1040 L445 620 Z" fill="#050302" opacity="0.70"/>

    <circle cx="450" cy="290" r="118" fill="#0b0503" opacity="0.78"/>
    <circle cx="410" cy="275" r="14" fill="$Primary"/>
    <circle cx="490" cy="275" r="14" fill="$Primary"/>

    <path d="M320 455 C410 500 490 500 580 455" stroke="$Primary" stroke-width="16" stroke-linecap="round" opacity="0.75"/>
    <path d="M275 680 C390 715 510 715 625 680" stroke="$Primary" stroke-width="9" stroke-linecap="round" opacity="0.55"/>
  </g>

  <g filter="url(#blurGlow)">
    <text x="450" y="1130"
          text-anchor="middle"
          font-family="Arial Black, Impact, sans-serif"
          font-size="86"
          fill="$Primary"
          opacity="0.96">$initials</text>
  </g>

  <text x="450" y="1182"
        text-anchor="middle"
        font-family="Arial, sans-serif"
        font-size="28"
        letter-spacing="6"
        fill="#fff4e6"
        opacity="0.72">$Element</text>
</svg>
"@
    }
    elseif ($Type -eq "portrait") {
        $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="600" height="600" viewBox="0 0 600 600">
  <defs>
    <radialGradient id="bg" cx="50%" cy="35%" r="60%">
      <stop offset="0%" stop-color="$Primary" stop-opacity="0.95"/>
      <stop offset="60%" stop-color="$Secondary" stop-opacity="0.78"/>
      <stop offset="100%" stop-color="#050302"/>
    </radialGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="9" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <rect width="600" height="600" rx="80" fill="url(#bg)"/>
  <circle cx="300" cy="255" r="128" fill="#070302" opacity="0.72"/>
  <circle cx="260" cy="235" r="16" fill="$Primary"/>
  <circle cx="340" cy="235" r="16" fill="$Primary"/>
  <path d="M210 390 C250 330 350 330 390 390 C390 485 210 485 210 390Z" fill="#090403" opacity="0.75"/>
  <text x="300" y="535" text-anchor="middle" font-family="Arial Black, Impact, sans-serif" font-size="90" fill="#fff4e6" filter="url(#glow)">$initials</text>
</svg>
"@
    }
    else {
        $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <radialGradient id="a" cx="30%" cy="20%" r="70%">
      <stop offset="0%" stop-color="$Primary" stop-opacity="0.45"/>
      <stop offset="50%" stop-color="$Secondary" stop-opacity="0.30"/>
      <stop offset="100%" stop-color="#050302"/>
    </radialGradient>
    <filter id="soft">
      <feGaussianBlur stdDeviation="12"/>
    </filter>
  </defs>
  <rect width="1600" height="900" fill="url(#a)"/>
  <g opacity="0.36" filter="url(#soft)">
    <circle cx="180" cy="180" r="160" fill="$Primary"/>
    <circle cx="1340" cy="210" r="240" fill="$Primary"/>
    <circle cx="840" cy="720" r="220" fill="$Secondary"/>
  </g>
  <g opacity="0.18">
    <path d="M0 720 C320 620 620 780 960 640 C1240 530 1400 610 1600 520" stroke="$Primary" stroke-width="8" fill="none"/>
    <path d="M0 790 C300 700 700 810 1050 690 C1300 600 1460 680 1600 610" stroke="#fff4e6" stroke-width="2" fill="none"/>
  </g>
  <text x="80" y="790" font-family="Arial Black, Impact, sans-serif" font-size="90" fill="#fff4e6" opacity="0.20">$Name</text>
</svg>
"@
    }

    Set-Content -Path $path -Value $svg -Encoding UTF8
}

$fighters = @(
    @{ Name="Liu Kang"; Slug="liu-kang"; Element="Fire"; Primary="#ff5a1f"; Secondary="#180805" },
    @{ Name="Scorpion"; Slug="scorpion"; Element="Fire"; Primary="#f8b84e"; Secondary="#1b1006" },
    @{ Name="Sub-Zero"; Slug="sub-zero"; Element="Ice"; Primary="#62c8ff"; Secondary="#06131c" },
    @{ Name="Raiden"; Slug="raiden"; Element="Lightning"; Primary="#aeeaff"; Secondary="#0a1720" },
    @{ Name="Kung Lao"; Slug="kung-lao"; Element="Steel"; Primary="#d8d8d8"; Secondary="#141414" },
    @{ Name="Kitana"; Slug="kitana"; Element="Air"; Primary="#4fc3ff"; Secondary="#071627" },
    @{ Name="Mileena"; Slug="mileena"; Element="Chaos"; Primary="#ff4fb8"; Secondary="#210616" },
    @{ Name="Johnny Cage"; Slug="johnny-cage"; Element="Hollywood"; Primary="#f2d16b"; Secondary="#111111" },
    @{ Name="Kenshi Takahashi"; Slug="kenshi-takahashi"; Element="Spirit"; Primary="#d71920"; Secondary="#160606" },
    @{ Name="Smoke"; Slug="smoke"; Element="Smoke"; Primary="#9aa3ad"; Secondary="#090b0e" },
    @{ Name="Rain"; Slug="rain"; Element="Water"; Primary="#7c3cff"; Secondary="#10051c" },
    @{ Name="Li Mei"; Slug="li-mei"; Element="Energy"; Primary="#c678ff"; Secondary="#17081f" },
    @{ Name="Tanya"; Slug="tanya"; Element="Light"; Primary="#ffd966"; Secondary="#1d1605" },
    @{ Name="Baraka"; Slug="baraka"; Element="Tarkat"; Primary="#d9b38c"; Secondary="#180d06" },
    @{ Name="Geras"; Slug="geras"; Element="Sand"; Primary="#d6b16a"; Secondary="#14100a" },
    @{ Name="Reptile"; Slug="reptile"; Element="Acid"; Primary="#39ff88"; Secondary="#03120a" },
    @{ Name="Ashrah"; Slug="ashrah"; Element="Light"; Primary="#f2f2e6"; Secondary="#15110a" },
    @{ Name="Havik"; Slug="havik"; Element="Khaos"; Primary="#c44747"; Secondary="#120506" },
    @{ Name="General Shao"; Slug="general-shao"; Element="War"; Primary="#8b0000"; Secondary="#170707" },
    @{ Name="Sindel"; Slug="sindel"; Element="Sonic"; Primary="#b26cff"; Secondary="#15081e" },
    @{ Name="Reiko"; Slug="reiko"; Element="War"; Primary="#9b1b30"; Secondary="#100508" },
    @{ Name="Nitara"; Slug="nitara"; Element="Blood"; Primary="#b00020"; Secondary="#150406" },
    @{ Name="Shang Tsung"; Slug="shang-tsung"; Element="Sorcery"; Primary="#16a34a"; Secondary="#031208" },
    @{ Name="Quan Chi"; Slug="quan-chi"; Element="Necromancy"; Primary="#e9e4cf"; Secondary="#11100b" },
    @{ Name="Ermac"; Slug="ermac"; Element="Soul"; Primary="#16a34a"; Secondary="#06140a" },
    @{ Name="Takeda Takahashi"; Slug="takeda-takahashi"; Element="Tech"; Primary="#f97316"; Secondary="#150a04" },
    @{ Name="Omni-Man"; Slug="omni-man"; Element="Power"; Primary="#e11d48"; Secondary="#0f172a" },
    @{ Name="Peacemaker"; Slug="peacemaker"; Element="Weapons"; Primary="#2563eb"; Secondary="#111827" },
    @{ Name="Homelander"; Slug="homelander"; Element="Laser"; Primary="#ef4444"; Secondary="#1d4ed8" },
    @{ Name="Cyrax"; Slug="cyrax"; Element="Tech"; Primary="#facc15"; Secondary="#111111" },
    @{ Name="Sektor"; Slug="sektor"; Element="Tech"; Primary="#dc2626"; Secondary="#111111" },
    @{ Name="Noob Saibot"; Slug="noob-saibot"; Element="Shadow"; Primary="#111827"; Secondary="#000000" },
    @{ Name="Ghostface"; Slug="ghostface"; Element="Horror"; Primary="#f8fafc"; Secondary="#030712" },
    @{ Name="Conan the Barbarian"; Slug="conan-the-barbarian"; Element="Steel"; Primary="#a16207"; Secondary="#120a04" },
    @{ Name="T-1000 Terminator"; Slug="t-1000-terminator"; Element="Liquid Metal"; Primary="#c0c0c0"; Secondary="#111827" }
)

$kameos = @(
    @{ Name="Sub-Zero"; Slug="sub-zero"; Element="Ice"; Primary="#62c8ff"; Secondary="#06131c" },
    @{ Name="Shujinko"; Slug="shujinko"; Element="Mimic"; Primary="#c2b280"; Secondary="#1c1608" },
    @{ Name="Scorpion"; Slug="scorpion"; Element="Fire"; Primary="#f8b84e"; Secondary="#1b1006" },
    @{ Name="Motaro"; Slug="motaro"; Element="Teleport"; Primary="#8b5cf6"; Secondary="#12051c" },
    @{ Name="Kung Lao"; Slug="kung-lao"; Element="Hat"; Primary="#d8d8d8"; Secondary="#141414" },
    @{ Name="Cyrax"; Slug="cyrax"; Element="Tech"; Primary="#facc15"; Secondary="#111111" },
    @{ Name="Frost"; Slug="frost"; Element="Ice"; Primary="#60a5fa"; Secondary="#071627" },
    @{ Name="Goro"; Slug="goro"; Element="Power"; Primary="#a16207"; Secondary="#170707" },
    @{ Name="Jax"; Slug="jax"; Element="Power"; Primary="#9ca3af"; Secondary="#111827" },
    @{ Name="Kano"; Slug="kano"; Element="Tech"; Primary="#ef4444"; Secondary="#111827" },
    @{ Name="Darrius"; Slug="darrius"; Element="Martial"; Primary="#f97316"; Secondary="#120704" },
    @{ Name="Sareena"; Slug="sareena"; Element="Demon"; Primary="#dc2626"; Secondary="#130606" },
    @{ Name="Sektor"; Slug="sektor"; Element="Tech"; Primary="#b91c1c"; Secondary="#111111" },
    @{ Name="Sonya"; Slug="sonya"; Element="Military"; Primary="#22c55e"; Secondary="#051407" },
    @{ Name="Stryker"; Slug="stryker"; Element="Police"; Primary="#334155"; Secondary="#030712" },
    @{ Name="Tremor"; Slug="tremor"; Element="Earth"; Primary="#92400e"; Secondary="#120a04" },
    @{ Name="Khameleon"; Slug="khameleon"; Element="Adapt"; Primary="#22c55e"; Secondary="#03120a" },
    @{ Name="Janet Cage"; Slug="janet-cage"; Element="Hollywood"; Primary="#facc15"; Secondary="#111111" },
    @{ Name="Mavado"; Slug="mavado"; Element="Rope"; Primary="#1f2937"; Secondary="#030712" },
    @{ Name="Ferra"; Slug="ferra"; Element="Brute"; Primary="#7c2d12"; Secondary="#120604" },
    @{ Name="Madam Bo"; Slug="madam-bo"; Element="Khaos"; Primary="#f472b6"; Secondary="#1f0714" }
)

foreach ($fighter in $fighters) {
    $folder = Join-Path $FightersRoot $fighter.Slug
    New-Item -Path $folder -ItemType Directory -Force | Out-Null

    Write-FighterSvg -Folder $folder -FileName "fullbody.svg" -Name $fighter.Name -Element $fighter.Element -Primary $fighter.Primary -Secondary $fighter.Secondary -Type "fullbody"
    Write-FighterSvg -Folder $folder -FileName "portrait.svg" -Name $fighter.Name -Element $fighter.Element -Primary $fighter.Primary -Secondary $fighter.Secondary -Type "portrait"
    Write-FighterSvg -Folder $folder -FileName "background.svg" -Name $fighter.Name -Element $fighter.Element -Primary $fighter.Primary -Secondary $fighter.Secondary -Type "background"
}

foreach ($kameo in $kameos) {
    $folder = Join-Path $KameosRoot $kameo.Slug
    New-Item -Path $folder -ItemType Directory -Force | Out-Null

    Write-FighterSvg -Folder $folder -FileName "portrait.svg" -Name $kameo.Name -Element $kameo.Element -Primary $kameo.Primary -Secondary $kameo.Secondary -Type "portrait"
}

Set-Content -Path (Join-Path $UiRoot "ember-particles.svg") -Value @"
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <rect width="1600" height="900" fill="transparent"/>
  <g fill="#ff5a1f" opacity="0.55">
    <circle cx="120" cy="220" r="5"/>
    <circle cx="340" cy="520" r="3"/>
    <circle cx="720" cy="160" r="4"/>
    <circle cx="980" cy="430" r="6"/>
    <circle cx="1300" cy="260" r="4"/>
    <circle cx="1480" cy="720" r="5"/>
  </g>
</svg>
"@ -Encoding UTF8

Set-Content -Path (Join-Path $UiRoot "smoke-overlay.svg") -Value @"
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <filter id="blur"><feGaussianBlur stdDeviation="35"/></filter>
  </defs>
  <rect width="1600" height="900" fill="transparent"/>
  <g filter="url(#blur)" opacity="0.22">
    <ellipse cx="300" cy="650" rx="320" ry="90" fill="#fff4e6"/>
    <ellipse cx="820" cy="720" rx="460" ry="110" fill="#b9a798"/>
    <ellipse cx="1250" cy="610" rx="300" ry="80" fill="#fff4e6"/>
  </g>
</svg>
"@ -Encoding UTF8

Write-Host "Placeholder fighter assets created."
Write-Host "Fighters folder: $FightersRoot"
Write-Host "Kameos folder: $KameosRoot"
Write-Host "UI folder: $UiRoot"