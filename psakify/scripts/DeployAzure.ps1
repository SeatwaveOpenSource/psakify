task deployazure {	
	function Set-AzurePublishSettings() {
		if (!$azureSubscription) {
			$azureSubscription = Read-Host "Subscription (case-sensitive)"
		}

		if (!$azureStorageAccount) {
			$azureStorageAccount = Read-Host "Storage account name"
		}

		if (!$azureServiceName) {
			$azureServiceName = Read-Host "Cloud service name"
		}

		if(!$azurePublishSettingsFile) {
			[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
			$fd = New-Object System.Windows.Forms.OpenFileDialog
			$fd.MultiSelect = $false
			$fd.Filter = "Azure publish settings (*.publishsettings)|*.publishsettings"
			$fd.ShowDialog()
			$azurePublishSettingsFile = $fd.FileName
		}
		
		"Importing Publish Settings File"
		Import-AzurePublishSettingsFile $azurePublishSettingsFile
		"Setting Azure Subscription"
		Set-AzureSubscription -SubscriptionName $azureSubscription -CurrentStorageAccount $azureStorageAccount
	}

	function Send-Package() {
		$containerName = "mydeployments"
		$blob = "$azureServiceName.package.$(get-date -f yyyy_MM_dd_hh_ss).cspkg"
		
		$containerState = Get-AzureStorageContainer -Name $containerName -ea 0
		if ($containerState -eq $null) {
			New-AzureStorageContainer -Name $containerName | Out-Null
		}

		Set-AzureStorageBlobContent -File $azurePackageFile -Container $containerName -Blob $blob -Force| Out-Null
		$blobState = Get-AzureStorageBlob -blob $blob -Container $containerName

		return $blobState.ICloudBlob.uri.AbsoluteUri
	}

	function New-Deployment($packageUrl) {
		"Creating New Deployment: In progress"

		$opstat = New-AzureDeployment -Slot $azureSlot -Package $packageUrl -Configuration $azureConfigFile -ServiceName $azureServiceName
 
		$completeDeployment = Get-AzureDeployment -ServiceName $azureServiceName -Slot $azureSlot
		$completeDeploymentId = $completeDeployment.DeploymentId
 
		"Creating New Deployment: Complete, Deployment Id: $completeDeploymentId"
	}
 
	function Set-Deployment($packageUrl) {
		"Upgrading Deployment: In progress"
 
		$setdeployment = Set-AzureDeployment -Upgrade -Slot $azureSlot -Package $packageUrl -Configuration $azureConfigFile -ServiceName $azureServiceName -Force
 
		$completeDeployment = Get-AzureDeployment -ServiceName $azureServiceName -Slot $azureSlot
		$completeDeploymentId = $completeDeployment.DeploymentId
 
		"Upgrading Deployment: Complete, Deployment Id: $completeDeploymentId"
	}

	"Running Azure Imports"
	if (Test-Path "C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\Azure.psd1") {
		Import-Module "C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\Azure.psd1"
	}
	else {
		Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
	}

	"Configuring publish settings"
	Set-AzurePublishSettings
	
	"Upload the deployment package"
	$packageUrl = Send-Package
	"Package uploaded to $packageUrl"
		
	"Checking Azure Deployment for $azureServiceName in $azureSlot"
	$deployment = Get-AzureDeployment -ServiceName $azureServiceName -Slot $azureSlot -ErrorAction silentlycontinue
	$azureConfigFile = "$outputPath\app.publish\ServiceConfiguration.$azureTargetProfile.cscfg"
	if ($deployment.Name -eq $null) {
		"No deployment was detected. Creating a new deployment."
		New-Deployment $packageUrl
	} else {
		"Deployment exists in $azureServiceName. Upgrading deployment."
		Set-Deployment $packageUrl
	}

	if ($azureSwapAfterDeploy) {
		"Swapping deployments"
		Move-AzureDeployment -ServiceName $azureServiceName
	}
}
