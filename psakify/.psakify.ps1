Import-Scripts properties, clean, push

task default -depends pack

task copyreadme {
	Get-Content $basePath\README.md | Set-Content $projectName\readme.txt
}

task pack -depends clean, copyreadme {
	"Packing $projectName.nuspec"
	New-Item $buildsPath -Type directory -Force | Out-Null

	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & .nuget\NuGet.exe pack $basePath\$projectName\$projectName.nuspec -OutputDirectory $buildsPath -Properties Version=$packageVersion -NoPackageAnalysis }
}