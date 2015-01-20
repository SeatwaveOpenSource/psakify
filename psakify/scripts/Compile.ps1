task compile -depends clean {
	Convert-Project $config $basePath $projectName $outputPath $azureTargetProfile
	$ilMerge = Get-PackageInfo "$basePath\$projectName" "ILMerge"
	if ($ilMerge.Exists) {
		Merge-Application "$($ilMerge.Path)" $outputPath $projectName
	}
	Convert-ProjectTests $config $basePath $projectName $projectTests
}