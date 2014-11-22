param($installPath, $toolsPath, $package, $project)

# Load Module
Import-Module (Join-Path $toolsPath ContentPackageExt.psm1) -ArgumentList $installPath, $toolsPath, $package, $project -Force

# Request Commands
Get-Command -Module ContentPackageExt

# Add contents from tools folder
addToolsContents

# Remove default content folder
removeDefaultContents
