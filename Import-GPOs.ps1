# Check for Administrator rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting."
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms

# Prompt for GPO backup root folder
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select the folder containing GPO backup folders"
$folderBrowser.ShowNewFolderButton = $false
$null = $folderBrowser.ShowDialog()

if (-not $folderBrowser.SelectedPath -or -not (Test-Path $folderBrowser.SelectedPath)) {
    Write-Error "No folder selected or path invalid. Exiting."
    exit 1
}

$importRoot = $folderBrowser.SelectedPath

# Find subfolders with manifest.xml
$gpoFolders = Get-ChildItem -Path $importRoot -Directory | ForEach-Object {
    $manifestPath = Join-Path $_.FullName 'manifest.xml'
    $migPath = Join-Path $_.FullName "$($_.Name).migtable"

    if (Test-Path $manifestPath) {
        [PSCustomObject]@{
            GPOName     = $_.Name
            Path        = $_.FullName
            HasMigTable = Test-Path $migPath
            MigPath     = $migPath
        }
    }
} | Where-Object { $_ -ne $null }

if (-not $gpoFolders) {
    Write-Error "No GPO backup folders found (with manifest.xml) in: $importRoot"
    exit 1
}

# GUI for selection
$selected = $gpoFolders | Out-GridView -Title "Select GPOs to import (Ctrl or Shift to multi-select)" -OutputMode Multiple

if (-not $selected) {
    Write-Host "No GPOs selected. Exiting."
    exit 0
}

foreach ($gpo in $selected) {
    $targetName = $gpo.GPOName
    $path = $gpo.Path

    # Try to create GPO if it doesn't exist
    $gpoExists = Get-GPO -Name $targetName -ErrorAction SilentlyContinue
    if (-not $gpoExists) {
        Write-Host "Creating new GPO: $targetName"
        try {
            New-GPO -Name $targetName -ErrorAction Stop | Out-Null
        } catch {
            Write-Warning "Failed to create GPO '$targetName': $_"
            continue
        }
    } else {
        Write-Host "GPO already exists: $targetName"
    }

    # Prepare import
    $importParams = @{
        BackupGpoName = $targetName
        Path          = $path
        TargetName    = $targetName
    }

    if ($gpo.HasMigTable) {
        $importParams['MigrationTable'] = $gpo.MigPath
        Write-Host "Importing '$targetName' with migration table"
    } else {
        Write-Host "Importing '$targetName' without migration table"
    }

    try {
        Import-GPO @importParams -ErrorAction Stop
        Write-Host "Successfully imported: $targetName"
    } catch {
        Write-Warning "Failed to import GPO '$targetName': $_"
    }
}

Write-Host ""
Write-Host "All selected GPOs processed from: $importRoot"
