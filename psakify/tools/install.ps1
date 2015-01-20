# Runs every time a package is installed in a project

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

# Install the psake.bat file
$solutionFolder = Resolve-Path .
Copy-Item "$installPath\psake.bat" $solutionFolder
$psakePath = "$solutionFolder\psake.bat"
$psakifyPath = Resolve-Path $installPath -Relative
$content = Get-Content $psakePath |
	%{ $_ -replace "%PSAKIFY_PATH%", $psakifyPath } |
	%{ $_ -replace "%PROJECT_NAME%", $project.Name }
Set-Content $psakePath $content
Write-Host "Installed $psakePath"

# Make sure that the psakify file is set to build action "None"
$tasksItem = $project.ProjectItems.Item(".psakify.ps1")
$tasksItem.Properties.Item("BuildAction").Value = [int]0

# Make sure that the packages file is set to build action "None"
$packagesItem = $project.ProjectItems.Item("packages.config")
$packagesItem.Properties.Item("BuildAction").Value = [int]0
$project.Save()