# Runs the first time a package is installed in a solution, and every time the solution is opened.

param($installPath, $toolsPath, $package, $project)

# $installPath is the path to the folder where the package is installed.
# $toolsPath is the path to the tools directory in the folder where the package is installed.
# $package is a reference to the package object.
# $project is null in init.ps1

@"

========================
psakify - Convention based build automation using psake
========================
"@ | Write-Host

# Import the psakify module so that it is available in the Package Manager Console for development
Import-Module "$installPath\Functions.psm1"
