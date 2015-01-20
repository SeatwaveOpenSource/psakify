# Runs every time a package is uninstalled

param($installPath, $toolsPath, $package, $project)

# $installPath is the path to the folder where the package is installed.
# $toolsPath is the path to the tools directory in the folder where the package is installed.
# $package is a reference to the package object.
# $project is a reference to the project the package was installed to.

@"

========================
psakify - Convention based build automation using psake
========================
"@ | Write-Host

# Remove the psake.bat file
$solutionFolder = Resolve-Path .
Remove-Item "$solutionFolder\psake.bat"
Write-Host "Removed $solutionFolder\psake.bat"