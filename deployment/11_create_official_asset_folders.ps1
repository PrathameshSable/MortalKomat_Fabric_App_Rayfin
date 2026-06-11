# =====================================================
# Step 11.1 - Create Official Asset Folder Structure
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

$AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$PublicAssets = Join-Path $AppRoot "public\assets"

$BrandingRoot = Join-Path $PublicAssets "branding"
$FightersRoot = Join-Path $PublicAssets "fighters"
$KameosRoot = Join-Path $PublicAssets "kameos"
$ArenasRoot = Join-Path $PublicAssets "arenas"
$UiRoot = Join-Path $PublicAssets "ui"

New-Item -Path $BrandingRoot -ItemType Directory -Force | Out-Null
New-Item -Path $FightersRoot -ItemType Directory -Force | Out-Null
New-Item -Path $KameosRoot -ItemType Directory -Force | Out-Null
New-Item -Path $ArenasRoot -ItemType Directory -Force | Out-Null
New-Item -Path $UiRoot -ItemType Directory -Force | Out-Null

$fighters = @(
    "liu-kang","scorpion","sub-zero","raiden","kung-lao","kitana","mileena","johnny-cage",
    "kenshi-takahashi","smoke","rain","li-mei","tanya","baraka","geras","reptile","ashrah",
    "havik","general-shao","sindel","reiko","nitara","shang-tsung","quan-chi","ermac",
    "takeda-takahashi","omni-man","peacemaker","homelander","cyrax","sektor","noob-saibot",
    "ghostface","conan-the-barbarian","t-1000-terminator"
)

$kameos = @(
    "sub-zero","shujinko","scorpion","motaro","kung-lao","cyrax","frost","goro","jax","kano",
    "darrius","sareena","sektor","sonya","stryker","tremor","khameleon","janet-cage",
    "mavado","ferra","madam-bo"
)

foreach ($fighter in $fighters) {
    $folder = Join-Path $FightersRoot $fighter
    New-Item -Path $folder -ItemType Directory -Force | Out-Null

    New-Item -Path (Join-Path $folder "fullbody.webp") -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $folder "portrait.webp") -ItemType File -Force | Out-Null
    New-Item -Path (Join-Path $folder "background.webp") -ItemType File -Force | Out-Null
}

foreach ($kameo in $kameos) {
    $folder = Join-Path $KameosRoot $kameo
    New-Item -Path $folder -ItemType Directory -Force | Out-Null

    New-Item -Path (Join-Path $folder "portrait.webp") -ItemType File -Force | Out-Null
}

Write-Host "Official asset folder structure created."
Write-Host "Branding: $BrandingRoot"
Write-Host "Fighters: $FightersRoot"
Write-Host "Kameos: $KameosRoot"
Write-Host "Arenas: $ArenasRoot"
Write-Host "UI: $UiRoot"