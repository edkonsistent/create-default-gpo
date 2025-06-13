# Export-GPO.ps1
# Backs up selected domain GPOs into individual subfolders inside GPO_Backup_YYYYMMDD

# Ensure GPMC module is available
if (-not (Get-Command Backup-GPO -ErrorAction SilentlyContinue)) {
    Write-Error "The GroupPolicy module is not available. Please install RSAT: Group Policy Management Tools."
    exit 1
}

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Create dated output folder
$dateStr = (Get-Date).ToString("yyyyMMdd")
$backupRoot = Join-Path $scriptDir "GPO_Backup_$dateStr"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

# Get all GPOs in the domain
$gpos = Get-GPO -All | Sort-Object DisplayName

if (-not $gpos) {
    Write-Host "No GPOs found in the domain."
    exit 1
}

# Let user select GPOs via Out-GridView (multi-select enabled)
try {
    $selected = $gpos |
        Select-Object DisplayName, Id |
        Out-GridView -Title "Select GPOs to Back Up (hold Ctrl or Shift to select multiple)" -OutputMode Multiple
} catch {
    Write-Error "Out-GridView is not available. Run this in Windows PowerShell with GUI support."
    exit 1
}

if (-not $selected) {
    Write-Host "No GPOs selected. Exiting."
    exit 0
}

# Function to sanitize folder names
function Sanitize-Name {
    param ($name)
    return ($name -replace '[\\/:*?"<>|]', '_')
}

# Back up each selected GPO to its own subfolder
foreach ($gpo in $selected) {
    $safeName = Sanitize-Name $gpo.DisplayName
    $gpoFolder = Join-Path $backupRoot $safeName
    New-Item -ItemType Directory -Path $gpoFolder -Force | Out-Null

    Write-Host "Backing up GPO: $($gpo.DisplayName) to $gpoFolder"
    try {
        Backup-GPO -Name $gpo.DisplayName -Path $gpoFolder -ErrorAction Stop
    } catch {
        Write-Warning "Failed to back up '$($gpo.DisplayName)': $_"
    }
}

Write-Host "`nBackup complete. GPOs saved to: $backupRoot"
