# Define the base path where Blender installations are expected to be found
$blenderBasePath = "C:\Program Files\Blender Foundation"

# Get all Blender installation directories
$blenderDirs = Get-ChildItem -Path $blenderBasePath -Directory

foreach ($dir in $blenderDirs) {
    # Use regex to extract version number from directory names like 'Blender 4.3', 'Blender 3.6.1', etc.
    $versionMatch = [regex]::Match($dir.Name, '\d+(\.\d+)*')
    if ($versionMatch.Success) {
        $blenderVersion = $versionMatch.Value
        $pythonPath = "$($dir.FullName)\$blenderVersion\python\bin\python.exe"
        $sitePackagesPath = "$($dir.FullName)\$blenderVersion\python\lib\python*.*\site-packages\PySide6"

        # Check if the PySide6 directory exists
        if (-Not (Test-Path $sitePackagesPath)) {
            # PySide6 is not installed, proceed with installation
            Write-Host "Installing PySide6 for Blender version $blenderVersion..."
            & $pythonPath -m pip install PySide6
        } else {
            Write-Host "PySide6 is already installed for Blender version $blenderVersion."
        }
    } else {
        Write-Host "No valid version found in the directory name '$($dir.Name)'."
    }
}
