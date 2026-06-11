# =====================================================
# Step 5 - Create or Validate Rayfin App Shell
# Mortal Kombat Arena Intelligence
# =====================================================

$ErrorActionPreference = "Stop"

# -------------------------------
# Environment values
# -------------------------------
$ProjectRoot = "C:\Projects\mk-arena-intelligence"
$AppFolderName = "mortal-kombat-arena-intelligence"
$AppPath = Join-Path $ProjectRoot $AppFolderName

# Fabric workspace DISPLAY name
$WorkspaceName = "MK Rayfin Demo"

Write-Host "========================================"
Write-Host "Step 5 - Rayfin App Shell Setup"
Write-Host "========================================"
Write-Host "ProjectRoot: $ProjectRoot"
Write-Host "AppFolderName: $AppFolderName"
Write-Host "AppPath: $AppPath"
Write-Host "WorkspaceName: $WorkspaceName"
Write-Host ""

# -------------------------------
# Validate workspace name
# -------------------------------
$WorkspaceName = $WorkspaceName.Trim()

if ([string]::IsNullOrWhiteSpace($WorkspaceName)) {
    throw "WorkspaceName is blank. Please set `$WorkspaceName to your actual Fabric workspace display name."
}

# -------------------------------
# Confirm tools
# -------------------------------
Write-Host "Checking Node.js..."
node -v

Write-Host "Checking npm..."
npm -v

Write-Host "Checking Rayfin CLI..."
rayfin --version

Write-Host "Checking Azure account..."
az account show --query "{tenantId:tenantId, subscription:name, user:user.name}" -o table

# -------------------------------
# Ensure project root exists
# -------------------------------
if (-not (Test-Path $ProjectRoot)) {
    New-Item -Path $ProjectRoot -ItemType Directory -Force | Out-Null
}

Set-Location $ProjectRoot

# -------------------------------
# Create Rayfin app if missing
# -------------------------------
if (-not (Test-Path $AppPath)) {
    Write-Host ""
    Write-Host "Rayfin app folder does not exist. Creating app..."
    Write-Host ""

    npm create @microsoft/rayfin@latest -- "$AppFolderName" --template dataapp --workspace "$WorkspaceName"
}
else {
    Write-Host ""
    Write-Host "Rayfin app folder already exists. Skipping scaffold step."
    Write-Host ""
}

# -------------------------------
# Move into app folder
# -------------------------------
Set-Location $AppPath

Write-Host ""
Write-Host "Current app folder:"
Get-Location
Write-Host ""

# -------------------------------
# Validate key files
# -------------------------------
if (-not (Test-Path ".\package.json")) {
    throw "package.json not found. Rayfin app scaffold may have failed."
}

if (-not (Test-Path ".\src")) {
    throw "src folder not found. Rayfin app scaffold may have failed."
}

if (-not (Test-Path ".\rayfin")) {
    throw "rayfin folder not found. Rayfin app scaffold may have failed."
}

Write-Host "Core Rayfin app files found."
Write-Host ""

# -------------------------------
# Install dependencies
# -------------------------------
Write-Host "Installing npm dependencies..."
npm install

# -------------------------------
# Show scripts
# -------------------------------
Write-Host ""
Write-Host "package.json scripts:"
npm pkg get scripts

# -------------------------------
# Check build:fabric script
# -------------------------------
Write-Host ""
Write-Host "Checking whether build:fabric script exists..."

$scriptsJson = npm pkg get scripts | ConvertFrom-Json

if ($null -eq $scriptsJson.'build:fabric') {
    Write-Host "WARNING: build:fabric script was not found."
    Write-Host "We will not run build:fabric in Step 5."
}
else {
    Write-Host "build:fabric script found:"
    Write-Host $scriptsJson.'build:fabric'

    Write-Host ""
    Write-Host "Running npm run build:fabric..."
    npm run build:fabric
}

# -------------------------------
# Check dist folder
# -------------------------------
Write-Host ""
Write-Host "Checking dist folder..."

if (Test-Path ".\dist") {
    Write-Host "dist folder exists."
}
else {
    Write-Host "dist folder not found yet. This is okay if build:fabric was skipped or failed before semantic model connection."
}

Write-Host ""
Write-Host "========================================"
Write-Host "Step 5 completed."
Write-Host "========================================"
Write-Host "Rayfin app path:"
Write-Host $AppPath
