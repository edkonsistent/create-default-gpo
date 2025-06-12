<#
.SYNOPSIS
    Imports GPOs from a folder created by Export-GPOs.ps1

.DESCRIPTION
    Reads each subfolder in the specified backup folder, extracts DisplayName from the XML, and imports GPOs into the domain.

.PARAMETER ImportFolder
    The root folder containing subfolders with backup.xml

.EXAMPLE
    .\Import-GPOs.ps1 "C:\Path\To\Exported-GPOs"
#>

param (
    [string]$ImportFolder
)

# Usage
if (-not $ImportFolder) {
    Write-Host "`nUSAGE: Import-GPOs.ps1 <PathToExportedGPOsFolder>" -ForegroundColor Yellow
    Write-Host "Example: .\Import-GPOs.ps1 'C:\Exported-GPOs-2025-06-12'"
    exit 1
}

if (-not (Test-Path $ImportFolder)) {
    Write-Host "`nERROR: Folder not found: $ImportFolder" -ForegroundColor Red
    exit 1
}

Write-Host "`nImporting GPOs from: $ImportFolder`n"

$gpoFolders = Get-ChildItem -Path $ImportFolder -Directory
if ($gpoFolders.Count -eq 0) {
    Write-Host "No GPO folders found in: $ImportFolder" -ForegroundColor Yellow
    exit 0
}

foreach ($folder in $gpoFolders) {
    $backupXmlPath = Join-Path $folder.FullName "backup.xml"

    if (-not (Test-Path $backupXmlPath)) {
        Write-Host "Skipping: $($folder.Name) — backup.xml not found." -ForegroundColor Yellow
        continue
    }

    try {
        [xml]$xml = Get-Content $backupXmlPath
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $nsMgr.AddNamespace("bkp", "http://www.microsoft.com/GroupPolicy/GPOOperations")

        $displayNameNode = $xml.SelectSingleNode("//bkp:GroupPolicyCoreSettings/bkp:DisplayName", $nsMgr)
        if (-not $displayNameNode -or $displayNameNode.InnerText.Trim() -eq "") {
            Write-Host "Skipping: $($folder.Name) — DisplayName not found in XML." -ForegroundColor Yellow
            continue
        }

        $displayName = $displayNameNode.InnerText.Trim()
        $userInput = Read-Host "Import GPO: '$displayName'? [Y/n]"
        if ($userInput -ne "" -and $userInput -notmatch "^(y|Y)$") {
            Write-Host "Skipped: $displayName" -ForegroundColor Yellow
            continue
        }

        if (-not (Get-GPO -Name $displayName -ErrorAction SilentlyContinue)) {
            Write-Host "Creating GPO: $displayName"
            New-GPO -Name $displayName | Out-Null
        } else {
            Write-Host "GPO already exists: $displayName — overwriting."
        }

        Import-GPO -BackupGpoName $displayName -Path $ImportFolder -TargetName $displayName -CreateIfNeeded -ErrorAction Stop
        Write-Host "Imported: $displayName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to import '$displayName': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll imports complete."
