Set-Location ..\
properties {
	$basePath = Get-ValueOrDefault $env:PSAKE_BASE_PATH (Resolve-Path .)
	$buildsPath = Get-ValueOrDefault $env:PSAKE_BUILDS_PATH "$basePath\builds"
	$projectName = Get-ValueOrDefault $env:PSAKE_PROJECT_NAME (Get-ChildItem "*.sln").Name.Replace(".sln", "")
	$outputPath = Get-ValueOrDefault $env:PSAKE_OUTPUT_PATH (Get-OutputPath $basePath $buildsPath $projectName)
	$projectTests = @(Get-TestProjectsFromSolution "$projectName.sln" $basePath) # Must be wrapped in @() otherwise might not return an array
	$config = Get-ValueOrDefault $env:PSAKE_CONFIG "Release"
	$version = Set-Version "$basePath\$projectName" $env:PSAKE_VERSION
	$prereleaseVersion = Get-ValueOrDefault $env:PSAKE_PRERELEASE_VERSION "dev{date}"
	$cacheFiles = $env:PSAKE_CACHE_FILES
	$octopusPackageSource = $env:PSAKE_OCTOPUS_PACKAGE_SOURCE
	$octopusPackageSourceApiKey = Get-ValueOrDefault $env:PSAKE_OCTOPUS_PACKAGE_SOURCE_API_KEY "LoadFromNuGetConfig"
	$nugetPackageSource = $env:PSAKE_NUGET_PACKAGE_SOURCE
	$nugetPackageSourceApiKey = Get-ValueOrDefault $env:PSAKE_NUGET_PACKAGE_SOURCE_API_KEY "LoadFromNuGetConfig"
	$nugetSymbolsPackageSource = $env:PSAKE_NUGET_SYMBOLS_PACKAGE_SOURCE
	$nugetSymbolsPackageSourceApiKey = Get-ValueOrDefault $env:PSAKE_NUGET_SYMBOLS_PACKAGE_SOURCE_API_KEY "LoadFromNuGetConfig"
	$nugetPackageSourceBackupPath = $env:PSAKE_NUGET_PACKAGE_SOURCE_BACKUP_PATH
	$browserStackProxyHost = $env:PSAKE_BROWSERSTACK_PROXY_HOST
	$browserStackProxyPort = Get-ValueOrDefault $env:PSAKE_BROWSERSTACK_PROXY_PORT 0
	$browserStackKey = $env:PSAKE_BROWSERSTACK_KEY
	$azurePassword = $env:PSAKE_AZURE_PASSWORD
	$azurePublishProfile = Get-ValueOrDefault $env:PSAKE_AZURE_PUBLISH_PROFILE "$basePath\$projectName\Properties\PublishProfiles\$projectName.pubxml"
	$azurePackageFile = Get-ValueOrDefault $env:PSAKE_AZURE_PACKAGE_FILE "$outputPath\app.publish\$projectName.Cloud.cspkg"
	$azureTargetProfile = $env:PSAKE_AZURE_TARGET_PROFILE
	$azureSubscription = $env:PSAKE_AZURE_SUBSCRIPTION
	$azureStorageAccount = $env:PSAKE_AZURE_STORAGE_ACCOUNT
	$azureServiceName = $env:PSAKE_AZURE_SERVICE_NAME
	$azurePublishSettingsFile = $env:PSAKE_AZURE_PUBLISH_SETTINGS_FILE
	$azureSlot = $env:PSAKE_AZURE_SLOT
	$azureSwapAfterDeploy = $env:PSAKE_AZURE_SWAP_AFTER_DEPLOY
	$gruntEnvironment = $env:PSAKE_GRUNT_ENVIRONMENT
}