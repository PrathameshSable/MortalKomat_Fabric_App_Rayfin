Write-Host "========================================"
Write-Host "MK Arena Intelligence - Step 1 Check"
Write-Host "========================================"
Write-Host ""

Write-Host "1. Current folder:"
Get-Location
Write-Host ""

Write-Host "2. PowerShell version:"
$PSVersionTable.PSVersion
Write-Host ""

Write-Host "3. VS Code CLI:"
try {
    code --version
} catch {
    Write-Host "VS Code CLI not found. You may need to install VS Code or enable 'code' command."
}
Write-Host ""

Write-Host "4. Node.js version:"
try {
    node -v
} catch {
    Write-Host "Node.js not found."
}
Write-Host ""

Write-Host "5. npm version:"
try {
    npm -v
} catch {
    Write-Host "npm not found."
}
Write-Host ""

Write-Host "6. Git version:"
try {
    git --version
} catch {
    Write-Host "Git not found."
}
Write-Host ""

Write-Host "7. Azure CLI version:"
try {
    az version
} catch {
    Write-Host "Azure CLI not found."
}
Write-Host ""

Write-Host "8. Rayfin CLI help through npx:"
try {
    rayfin --help
} catch {
    Write-Host "Rayfin CLI could not run through npx."
}
Write-Host ""

Write-Host "========================================"
Write-Host "Step 1 local tool check completed."
Write-Host "========================================"
