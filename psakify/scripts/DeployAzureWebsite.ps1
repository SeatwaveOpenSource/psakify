task deployazurewebsite {
	$projectFile = "$basePath\$projectName\$projectName.csproj"

	if (!$azurePassword) {
		$azurePassword = Read-Host "Password"
	}

	exec { msbuild $projectFile /p:DeployOnBuild=true /p:PublishProfile=$azurePublishProfile /p:VisualStudioVersion=12.0 /p:Password=$azurePassword /p:AllowUntrustedCertificate=true }
}