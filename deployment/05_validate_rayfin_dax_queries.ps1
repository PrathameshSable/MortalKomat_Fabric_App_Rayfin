# =====================================================
# Step 7 - Validate Rayfin DAX Query Files
# Mortal Kombat Arena Intelligence
# WORKING VERSION
# =====================================================

$ErrorActionPreference = "Continue"

$RayfinAppFolder = "C:\Projects\mk-arena-intelligence\mortal-kombat-arena-intelligence"
$QueryFolder = Join-Path $RayfinAppFolder "src\queries\kombat"
$ConnectionAlias = "kombatModel"

Write-Host "========================================"
Write-Host "Step 7 - Validate Rayfin DAX query files"
Write-Host "========================================"
Write-Host "RayfinAppFolder: $RayfinAppFolder"
Write-Host "QueryFolder: $QueryFolder"
Write-Host "ConnectionAlias: $ConnectionAlias"
Write-Host ""

if (-not (Test-Path $RayfinAppFolder)) {
    throw "Rayfin app folder not found: $RayfinAppFolder"
}

if (-not (Test-Path $QueryFolder)) {
    throw "Query folder not found: $QueryFolder"
}

Set-Location $RayfinAppFolder

Write-Host "Current folder:"
Get-Location
Write-Host ""

$queries = @(
    "kpi-summary.dax",
    "fighter-grid.dax",
    "fighter-profile.dax",
    "xp-trend.dax",
    "arena-insights.dax",
    "kameo-insights.dax",
    "matchup-matrix.dax",
    "move-insights.dax"
)

foreach ($queryFile in $queries) {
    $queryPath = Join-Path $QueryFolder $queryFile

    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host "Validating: $queryFile"
    Write-Host "----------------------------------------"

    if (-not (Test-Path $queryPath)) {
        Write-Host "MISSING: $queryPath" -ForegroundColor Red
        continue
    }

    $daxRaw = Get-Content -Path $queryPath -Raw

    $dax = $daxRaw `
        -replace [char]0xFEFF, "" `
        -replace "\r?\n", " " `
        -replace "\s+", " "

    $dax = $dax.Trim()

    Write-Host "Query preview:"
    Write-Host $dax.Substring(0, [Math]::Min(160, $dax.Length))
    Write-Host ""

    $rawOutput = & npx --no-install fabric-app-data query $ConnectionAlias --query $dax 2>&1
    $outputText = ($rawOutput | Out-String).Trim()

    try {
        $json = $outputText | ConvertFrom-Json

        if ($json.status -eq "success") {
            $rowCount = 0

            if ($null -ne $json.table -and $null -ne $json.table.rows) {
                $rowCount = $json.table.rows.Count
            }

            Write-Host "SUCCESS: $queryFile | Rows returned: $rowCount" -ForegroundColor Green
        }
        else {
            Write-Host "FAILED: $queryFile" -ForegroundColor Red
            Write-Host "Message: $($json.error.message)"
            Write-Host "Code: $($json.error.code)"
        }
    }
    catch {
        Write-Host "FAILED TO PARSE CLI OUTPUT FOR: $queryFile" -ForegroundColor Red
        Write-Host $outputText
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Step 7 validation completed."
Write-Host "Each query should show SUCCESS."
Write-Host "========================================"
