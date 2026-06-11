Write-Host "========================================"
Write-Host "MK Arena Intelligence - Local Tool Check"
Write-Host "========================================"
Write-Host ""

Write-Host "Current folder:"
Write-Host (Get-Location)
Write-Host ""

Write-Host "PowerShell:"
Write-Host $PSVersionTable.PSVersion
Write-Host ""

Write-Host "Node.js:"
node -v
Write-Host ""

Write-Host "npm:"
npm -v
Write-Host ""

Write-Host "Git:"
git --version
Write-Host ""

Write-Host "Azure CLI:"
$azVersion = az version | ConvertFrom-Json
Write-Host $azVersion.'azure-cli'
Write-Host ""

Write-Host "Rayfin CLI:"
rayfin --version
Write-Host ""

Write-Host "Azure account:"
az account show --query "{tenantId:tenantId, subscription:name, user:user.name}" -o table
Write-Host ""

Write-Host "========================================"
Write-Host "Validation complete."
Write-Host "========================================"
