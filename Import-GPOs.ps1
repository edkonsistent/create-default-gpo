# Import-GPOs.ps1

param (
    [string]$GpoContainerPath
)

Import-Module GroupPolicy

# Show usage help if no path was given
if (-not $GpoContainerPath) {
    Write-Host ""
    Write-Host "ERROR: No GPO folder path specified." -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\Import-GPOs.ps1 <PathToExportedGPOs>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\Import-GPOs.ps1 `"C:\Exports\Exported-GPOs-2025-06-12`""
    exit 1
}

# Check for LGPO.exe next to script
$lgpoExe = Join-Path $PSScriptRoot "LGPO.exe"
if (-not (Test-Path $lgpoExe)) {
    Write-Host ""
    Write-Host "ERROR: LGPO.exe not found in script directory." -ForegroundColor Red
    Write-Host "Please download it from: https://repository.konsistent.co/repository/packages/Utilities/LGPO/LGPO.exe"
    Write-Host "Then place it next to this script and re-run."
    exit 1
}

# Validate GPO container path
if (-not (Test-Path $GpoContainerPath)) {
    Write-Host ""
    Write-Host "ERROR: Specified folder does not exist: $GpoContainerPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Importing GPOs from: $GpoContainerPath"

# Get all subfolders (each representing a GPO)
$gpoFolders = Get-ChildItem -Path $GpoContainerPath -Directory

foreach ($folder in $gpoFolders) {
    $gpoName = $folder.Name

    try {
        # Ensure the GPO exists
        if (-not (Get-GPO -Name $gpoName -ErrorAction SilentlyContinue)) {
            Write-Host "Creating GPO: $gpoName"
            New-GPO -Name $gpoName | Out-Null
        } else {
            Write-Host "GPO already exists: $gpoName"
        }

        # Import domain policy settings
        Write-Host "Importing domain GPO: $gpoName"
        Import-GPO -Path $folder.FullName -TargetName $gpoName -CreateIfNeeded -ErrorAction Stop

        # Import local policy content using LGPO
        Start-Process -FilePath $lgpoExe -ArgumentList "/g `"$folder.FullName`"" -NoNewWindow -Wait
    }
    catch {
        Write-Host "Failed to import: $gpoName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "All GPOs imported from: $GpoContainerPath"
