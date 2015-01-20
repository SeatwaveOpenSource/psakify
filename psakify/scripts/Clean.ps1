task clean {
	if (Test-Path $buildsPath) {
		"Cleaning builds folder"
		Remove-Item $buildsPath\* -Recurse
	}
	"Cleaning bin folders"
	Remove-Directory "$basePath\*\bin"
	"Cleaning obj folders"
	Remove-Directory "$basePath\*\obj"
}