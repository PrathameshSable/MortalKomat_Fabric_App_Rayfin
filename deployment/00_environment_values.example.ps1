# Mortal Kombat Arena Intelligence - Environment Values
# Copy this file to `00_environment_values.ps1` and fill in YOUR values.

$TenantId = "<your Entra tenant id>"
$WorkspaceId = "<your Fabric workspace id>"
$SemanticModelId = "<your semantic model item id>"

$ProjectRoot = "<local path to this repo>"
$RayfinAppFolder = "$ProjectRoot\mortal-kombat-arena-intelligence"

# This is the semantic model URL that opens correctly in your browser.
$SemanticModelUrl = "https://app.powerbi.com/onelake/details/$WorkspaceId/dataset/$SemanticModelId"

Write-Host "TenantId: $TenantId"
Write-Host "WorkspaceId: $WorkspaceId"
Write-Host "SemanticModelId: $SemanticModelId"
Write-Host "ProjectRoot: $ProjectRoot"
Write-Host "RayfinAppFolder: $RayfinAppFolder"
Write-Host "SemanticModelUrl: $SemanticModelUrl"
