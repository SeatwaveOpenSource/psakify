task octopack -depends test {
	"OctoPacking $projectName"
	
	$octopusToolsPath = Get-RequiredPackagePath ".nuget" "OctopusTools"
	$packageVersion = (Get-Date).ToString("yyyy.MM.dd.HHmmss")
	if (![string]::IsNullOrEmpty($prereleaseVersion)) {
		$packageVersion = "$packageVersion-dev"
	}
	exec { & $octopusToolsPath\Octo.exe pack --basePath=$outputPath --outFolder=$buildsPath --id=$projectName --version=$packageVersion }
		
	$octopusPackage = Get-ChildItem("$buildsPath\$projectName*.nupkg")
	if (!$octopusPackageSource) {
		$octopusPackageSource = Read-Host "Please enter Octopus package source"
	}
	if (!$octopusPackageSourceApiKey) {
		$octopusPackageSourceApiKey = Read-Host "Please enter Octopus package source API key"
	}
	Push-Package $basePath $octopusPackage $octopusPackageSource $octopusPackageSourceApiKey
}