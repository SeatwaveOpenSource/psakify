task create7zip {
	"7-Zipping files in $outputPath"

	$7zipPath = Get-RequiredPackagePath ".nuget" "7-Zip.CommandLine"	
	$outputFile = "$outputPath.7z"
	$include = "-ir!$outputPath\*"
	exec { & $7zipPath\tools\7za.exe u -t7z $outputFile $include -mx9 }
}