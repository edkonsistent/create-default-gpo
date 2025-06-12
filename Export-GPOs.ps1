# Export-GPOs.ps1

Import-Module GroupPolicy

# Setup paths
$timestamp = Get-Date -Format "yyyy-MM-dd"
$exportRoot = Join-Path $PSScriptRoot "Exported-GPOs-$timestamp"
$lgpoExe = Join-Path $PSScriptRoot "LGPO.exe"

# Check for LGPO.exe
if (-not (Test-Path $lgpoExe)) {
    Write-Host ""
    Write-Host "ERROR: LGPO.exe not found in script directory." -ForegroundColor Red
    Write-Host "Please download it from:" -ForegroundColor Yellow
    Write-Host "  https://repository.konsistent.co/repository/packages/Utilities/LGPO/LGPO.exe"
    Write-Host "Then place it next to this script and re-run."
    exit 1
}

# Sanitize GPO name for folder usage
function Get-SafeFolderName {
    param ($name)
    return ($name -replace '[\\/:*?"<>|]', '_')
}

# Create export root folder
New-Item -Path $exportRoot -ItemType Directory -Force | Out-Null
Write-Host ""
Write-Host "Export folder created: $exportRoot"

# Track export results
$exportedCount = 0
$failedCount = 0

# Export all GPOs
Get-GPO -All | ForEach-Object {
    $gpo = $_
    $safeName = Get-SafeFolderName $gpo.DisplayName
    $backupPath = Join-Path $exportRoot $safeName

    Write-Host "Backing up GPO: $($gpo.DisplayName)"

    try {
        # Create target folder for GPO
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

        # Export using Backup-GPO
        Backup-GPO -Name $gpo.DisplayName -Path $backupPath -ErrorAction Stop

        # Export local policy (LGPO)
        Start-Process -FilePath $lgpoExe -ArgumentList "/b `"$backupPath`"" -NoNewWindow -Wait

        $exportedCount++
    }
    catch {
        Write-Host "Failed to export: $($gpo.DisplayName) - $($_.Exception.Message)" -ForegroundColor Red
        $failedCount++
    }
}

# Summary
Write-Host ""
if ($exportedCount -gt 0) {
    Write-Host "$exportedCount GPO(s) successfully exported to: $exportRoot" -ForegroundColor Green
} else {
    Write-Host "No GPOs were successfully exported." -ForegroundColor Red
}

if ($failedCount -gt 0) {
    Write-Host "$failedCount GPO(s) failed to export." -ForegroundColor Yellow
}
