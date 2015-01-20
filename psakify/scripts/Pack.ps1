task pack -depends test {
	"Packing $projectName.csproj"
	New-Item $buildsPath -Type directory -Force | Out-Null
		
	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & .nuget\NuGet.exe pack $basePath\$projectName\$projectName.csproj -Properties Configuration=$config -OutputDirectory $buildsPath -Symbols -Version $packageVersion }
}
