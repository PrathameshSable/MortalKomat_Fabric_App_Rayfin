# =====================================================
# Step 12A - Import Multiple Fighter PNG Assets
# Mortal Kombat Arena Intelligence
# =====================================================
# Purpose:
# - Take many approved PNG/JPG/WEBP files per fighter
# - Copy them into public/assets/fighters/<fighter-slug>/gallery
# - Create a central manifest: public/assets/fighters/_fighter-assets.json
# - The React UI can then cycle these images on hover
#
# Recommended staging structure:
# C:\Projects\mk-arena-intelligence\incoming-assets\fighters\scorpion\K1_ScorpionRender_Hero-pose.png
# C:\Projects\mk-arena-intelligence\incoming-assets\fighters\scorpion\K1_ScorpionSeasonOfFire.png
# C:\Projects\mk-arena-intelligence\incoming-assets\fighters\sub-zero\...
# C:\Projects\mk-arena-intelligence\incoming-assets\branding\mk-logo.png
# =====================================================

param(
    [string] $ProjectRoot = "C:\Projects\mk-arena-intelligence",
    [string] $AppRoot = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence",
    [string] $IncomingAssetsRoot = "C:\Projects\mk-arena-intelligence\incoming-assets",
    [switch] $Overwrite
)

$ErrorActionPreference = "Stop"

$PublicAssets = Join-Path $AppRoot "public\assets"
$PublicFightersRoot = Join-Path $PublicAssets "fighters"
$PublicBrandingRoot = Join-Path $PublicAssets "branding"
$PublicUiRoot = Join-Path $PublicAssets "ui"

$IncomingFightersRoot = Join-Path $IncomingAssetsRoot "fighters"
$IncomingBrandingRoot = Join-Path $IncomingAssetsRoot "branding"

New-Item -Path $PublicFightersRoot -ItemType Directory -Force | Out-Null
New-Item -Path $PublicBrandingRoot -ItemType Directory -Force | Out-Null
New-Item -Path $PublicUiRoot -ItemType Directory -Force | Out-Null
New-Item -Path $IncomingFightersRoot -ItemType Directory -Force | Out-Null
New-Item -Path $IncomingBrandingRoot -ItemType Directory -Force | Out-Null

$fighters = @(
    @{ Slug="liu-kang"; Name="Liu Kang"; Aliases=@("liu-kang","liukang","liu_kang") },
    @{ Slug="scorpion"; Name="Scorpion"; Aliases=@("scorpion","mk95","icefirescorpion","bloodscorpion") },
    @{ Slug="sub-zero"; Name="Sub-Zero"; Aliases=@("sub-zero","subzero","sub_zero") },
    @{ Slug="raiden"; Name="Raiden"; Aliases=@("raiden") },
    @{ Slug="kung-lao"; Name="Kung Lao"; Aliases=@("kung-lao","kunglao","kung_lao") },
    @{ Slug="kitana"; Name="Kitana"; Aliases=@("kitana") },
    @{ Slug="mileena"; Name="Mileena"; Aliases=@("mileena") },
    @{ Slug="johnny-cage"; Name="Johnny Cage"; Aliases=@("johnny-cage","johnnycage","johnny_cage") },
    @{ Slug="kenshi-takahashi"; Name="Kenshi Takahashi"; Aliases=@("kenshi","kenshi-takahashi","kenshitakahashi") },
    @{ Slug="smoke"; Name="Smoke"; Aliases=@("smoke") },
    @{ Slug="rain"; Name="Rain"; Aliases=@("rain") },
    @{ Slug="li-mei"; Name="Li Mei"; Aliases=@("li-mei","limei","li_mei") },
    @{ Slug="tanya"; Name="Tanya"; Aliases=@("tanya") },
    @{ Slug="baraka"; Name="Baraka"; Aliases=@("baraka") },
    @{ Slug="geras"; Name="Geras"; Aliases=@("geras") },
    @{ Slug="reptile"; Name="Reptile"; Aliases=@("reptile") },
    @{ Slug="ashrah"; Name="Ashrah"; Aliases=@("ashrah") },
    @{ Slug="havik"; Name="Havik"; Aliases=@("havik") },
    @{ Slug="general-shao"; Name="General Shao"; Aliases=@("general-shao","generalshao","general_shao","shao") },
    @{ Slug="sindel"; Name="Sindel"; Aliases=@("sindel") },
    @{ Slug="reiko"; Name="Reiko"; Aliases=@("reiko") },
    @{ Slug="nitara"; Name="Nitara"; Aliases=@("nitara") },
    @{ Slug="shang-tsung"; Name="Shang Tsung"; Aliases=@("shang-tsung","shangtsung","shang_tsung") },
    @{ Slug="quan-chi"; Name="Quan Chi"; Aliases=@("quan-chi","quanchi","quan_chi") },
    @{ Slug="ermac"; Name="Ermac"; Aliases=@("ermac") },
    @{ Slug="takeda-takahashi"; Name="Takeda Takahashi"; Aliases=@("takeda","takeda-takahashi","takedatakahashi") },
    @{ Slug="omni-man"; Name="Omni-Man"; Aliases=@("omni-man","omniman","omni_man") },
    @{ Slug="peacemaker"; Name="Peacemaker"; Aliases=@("peacemaker") },
    @{ Slug="homelander"; Name="Homelander"; Aliases=@("homelander") },
    @{ Slug="cyrax"; Name="Cyrax"; Aliases=@("cyrax") },
    @{ Slug="sektor"; Name="Sektor"; Aliases=@("sektor") },
    @{ Slug="noob-saibot"; Name="Noob Saibot"; Aliases=@("noob-saibot","noobsaibot","noob_saibot","noob") },
    @{ Slug="ghostface"; Name="Ghostface"; Aliases=@("ghostface","ghost-face","ghost_face") },
    @{ Slug="conan-the-barbarian"; Name="Conan the Barbarian"; Aliases=@("conan","conan-the-barbarian","conanthebarbarian") },
    @{ Slug="t-1000-terminator"; Name="T-1000 Terminator"; Aliases=@("t-1000","t1000","terminator") }
)

function Normalize-Name {
    param([string] $Value)

    return ($Value.ToLowerInvariant() -replace "[^a-z0-9]+", "")
}

function Safe-FileName {
    param([string] $Value)

    $name = [IO.Path]::GetFileNameWithoutExtension($Value)
    $ext = [IO.Path]::GetExtension($Value).ToLowerInvariant()
    $safeName = ($name -replace "[^a-zA-Z0-9._-]+", "-").Trim("-")

    if ([string]::IsNullOrWhiteSpace($safeName)) {
        $safeName = [guid]::NewGuid().ToString("N")
    }

    return "$safeName$ext"
}

function Get-FighterForFile {
    param(
        [IO.FileInfo] $File,
        [array] $Fighters
    )

    $relativeFolderText = Normalize-Name -Value $File.DirectoryName
    $fileText = Normalize-Name -Value $File.Name
    $combined = "$relativeFolderText $fileText"

    foreach ($fighter in $Fighters) {
        foreach ($alias in $fighter.Aliases) {
            $normalAlias = Normalize-Name -Value $alias
            if ($combined.Contains($normalAlias)) {
                return $fighter
            }
        }
    }

    return $null
}

function Select-BestAsset {
    param(
        [array] $Files,
        [string] $Mode
    )

    if ($Files.Count -eq 0) {
        return $null
    }

    $patterns = switch ($Mode) {
        "hero" { @("hero","hero-pose","render","action","action-pose","stpat","mk95","fullbody") }
        "portrait" { @("portrait","head","profile","stat","stpat") }
        "background" { @("season","background","outburst","fire","ice","blood","stage") }
        default { @("render") }
    }

    $matched = $Files | Where-Object {
        $name = $_.Name.ToLowerInvariant()
        foreach ($pattern in $patterns) {
            if ($name.Contains($pattern)) { return $true }
        }
        return $false
    }

    if ($matched.Count -gt 0) {
        return $matched | Sort-Object Length -Descending | Select-Object -First 1
    }

    return $Files | Sort-Object Length -Descending | Select-Object -First 1
}

Write-Host "========================================"
Write-Host "Step 12A - Import multi-image fighter assets"
Write-Host "========================================"
Write-Host "IncomingAssetsRoot: $IncomingAssetsRoot"
Write-Host "IncomingFightersRoot: $IncomingFightersRoot"
Write-Host "PublicFightersRoot: $PublicFightersRoot"
Write-Host ""

# Copy branding if present.
if (Test-Path $IncomingBrandingRoot) {
    $brandingFiles = Get-ChildItem -Path $IncomingBrandingRoot -File -Include *.png,*.jpg,*.jpeg,*.webp,*.svg -Recurse

    foreach ($file in $brandingFiles) {
        $destination = Join-Path $PublicBrandingRoot $file.Name
        if ($Overwrite -or -not (Test-Path $destination)) {
            Copy-Item $file.FullName $destination -Force
            Write-Host "BRANDING: $($file.Name) -> $destination"
        }
    }

    # Helpful auto-map for common filenames.
    $allBranding = Get-ChildItem -Path $PublicBrandingRoot -File -ErrorAction SilentlyContinue

    $logoCandidate = $allBranding | Where-Object { $_.Name.ToLowerInvariant() -match "logo|mk" } | Sort-Object Length -Descending | Select-Object -First 1
    if ($logoCandidate -and -not (Test-Path (Join-Path $PublicBrandingRoot "mk-logo.png"))) {
        Copy-Item $logoCandidate.FullName (Join-Path $PublicBrandingRoot "mk-logo.png") -Force
    }

    $dragonCandidate = $allBranding | Where-Object { $_.Name.ToLowerInvariant() -match "dragon|emblem" } | Sort-Object Length -Descending | Select-Object -First 1
    if ($dragonCandidate -and -not (Test-Path (Join-Path $PublicBrandingRoot "mk-dragon-emblem.png"))) {
        Copy-Item $dragonCandidate.FullName (Join-Path $PublicBrandingRoot "mk-dragon-emblem.png") -Force
    }
}

# Import fighter images.
$sourceImages = Get-ChildItem -Path $IncomingFightersRoot -File -Include *.png,*.jpg,*.jpeg,*.webp -Recurse -ErrorAction SilentlyContinue

if ($sourceImages.Count -eq 0) {
    Write-Host "No source images found under: $IncomingFightersRoot"
    Write-Host "Create folders like incoming-assets\fighters\scorpion and place PNG files there."
}

$manifest = @{}
$unmatched = @()

foreach ($fighter in $fighters) {
    $slug = $fighter.Slug
    $targetFolder = Join-Path $PublicFightersRoot $slug
    $galleryFolder = Join-Path $targetFolder "gallery"

    New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
    New-Item -Path $galleryFolder -ItemType Directory -Force | Out-Null

    $manifest[$slug] = [ordered]@{
        slug = $slug
        name = $fighter.Name
        hero = $null
        portrait = $null
        background = $null
        gallery = @()
    }
}

foreach ($file in $sourceImages) {
    $fighter = Get-FighterForFile -File $file -Fighters $fighters

    if ($null -eq $fighter) {
        $unmatched += $file.FullName
        continue
    }

    $slug = $fighter.Slug
    $galleryFolder = Join-Path $PublicFightersRoot "$slug\gallery"
    $safeName = Safe-FileName -Value $file.Name
    $destination = Join-Path $galleryFolder $safeName

    if ($Overwrite -or -not (Test-Path $destination)) {
        Copy-Item $file.FullName $destination -Force
    }

    $webPath = "/assets/fighters/$slug/gallery/$safeName"
    if (-not ($manifest[$slug].gallery -contains $webPath)) {
        $manifest[$slug].gallery += $webPath
    }
}

# Select hero/portrait/background for each fighter.
foreach ($fighter in $fighters) {
    $slug = $fighter.Slug
    $galleryFolder = Join-Path $PublicFightersRoot "$slug\gallery"
    $targetFolder = Join-Path $PublicFightersRoot $slug

    $files = @(Get-ChildItem -Path $galleryFolder -File -Include *.png,*.jpg,*.jpeg,*.webp -ErrorAction SilentlyContinue)

    if ($files.Count -eq 0) {
        continue
    }

    $hero = Select-BestAsset -Files $files -Mode "hero"
    $portrait = Select-BestAsset -Files $files -Mode "portrait"
    $background = Select-BestAsset -Files $files -Mode "background"

    if ($hero) {
        $dest = Join-Path $targetFolder ("fullbody" + $hero.Extension.ToLowerInvariant())
        Copy-Item $hero.FullName $dest -Force
        $manifest[$slug].hero = "/assets/fighters/$slug/" + [IO.Path]::GetFileName($dest)
    }

    if ($portrait) {
        $dest = Join-Path $targetFolder ("portrait" + $portrait.Extension.ToLowerInvariant())
        Copy-Item $portrait.FullName $dest -Force
        $manifest[$slug].portrait = "/assets/fighters/$slug/" + [IO.Path]::GetFileName($dest)
    }

    if ($background) {
        $dest = Join-Path $targetFolder ("background" + $background.Extension.ToLowerInvariant())
        Copy-Item $background.FullName $dest -Force
        $manifest[$slug].background = "/assets/fighters/$slug/" + [IO.Path]::GetFileName($dest)
    }
}

$manifestPath = Join-Path $PublicFightersRoot "_fighter-assets.json"
$manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8

$reportRows = foreach ($fighter in $fighters) {
    $slug = $fighter.Slug
    [pscustomobject]@{
        Fighter = $fighter.Name
        Slug = $slug
        GalleryCount = $manifest[$slug].gallery.Count
        Hero = $manifest[$slug].hero
        Portrait = $manifest[$slug].portrait
        Background = $manifest[$slug].background
    }
}

$reportPath = Join-Path $PublicFightersRoot "_fighter-assets-report.csv"
$reportRows | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8

if ($unmatched.Count -gt 0) {
    $unmatchedPath = Join-Path $PublicFightersRoot "_unmatched-assets.txt"
    $unmatched | Set-Content -Path $unmatchedPath -Encoding UTF8
    Write-Host ""
    Write-Host "Unmatched files were written to: $unmatchedPath"
}

Write-Host ""
Write-Host "Manifest written:"
Write-Host $manifestPath
Write-Host ""
Write-Host "Report written:"
Write-Host $reportPath
Write-Host ""
Write-Host "Summary:"
$reportRows | Format-Table Fighter, Slug, GalleryCount, Hero -AutoSize
