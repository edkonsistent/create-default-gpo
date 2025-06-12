# Export-GPOs.ps1
Import-Module GroupPolicy

# Display usage instructions
Write-Host "`nThis script exports selected GPOs from your domain."
Write-Host "Backups will be saved into a folder next to this script."
Write-Host "If LGPO.exe is needed, download it from:"
Write-Host "  https://repository.konsistent.co/repository/packages/Utilities/LGPO/LGPO.exe`n"

# Setup export directory
$timestamp = Get-Date -Format "yyyy-MM-dd"
$exportRoot = Join-Path $PSScriptRoot "Exported-GPOs-$timestamp"
New-Item -ItemType Directory -Path $exportRoot -Force | Out-Null
Write-Host "Export folder created: $exportRoot`n"

# Get all GPOs
$allGpos = Get-GPO -All
if (-not $allGpos) {
    Write-Host "No GPOs found in the domain. Exiting."
    exit 1
}

# Selectively include GPOs
$selectedGpos = @()
Write-Host "Select GPOs to export. Type 'y' or press ENTER to include, or 'n' to skip:`n"
foreach ($gpo in $allGpos) {
    $input = Read-Host "Include GPO: $($gpo.DisplayName)? [Y/n]"
    if ($input -eq '' -or $input -match '^(y|Y)$') {
        $selectedGpos += $gpo
    }
}

if ($selectedGpos.Count -eq 0) {
    Write-Host "`nNo GPOs selected. Exiting."
    exit 0
}

# Backup each selected GPO
foreach ($gpo in $selectedGpos) {
    try {
        Write-Host "`nBacking up GPO: $($gpo.DisplayName)"
        $null = Backup-GPO -Name $gpo.DisplayName -Path $exportRoot -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to export $($gpo.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nExport completed. You can now re-import using Import-GPO against this folder:"
Write-Host "$exportRoot"
