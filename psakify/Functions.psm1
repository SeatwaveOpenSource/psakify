function Get-PackagesPath {
    $repositoryPath = .nuget\NuGet.exe config RepositoryPath -AsPath
    if ($repositoryPath -eq "WARNING: Key 'RepositoryPath' not found.") {
		$packagesPath = ".\packages"
	}
    else {
		$packagesPath = Resolve-Path $repositoryPath -Relative
	}
    return $packagesPath
}

function Get-RequiredPackagePath($path, $packageName) {
	$package = Get-PackageInfo $path $packageName
	if (!$package.Exists) {
		throw "$packageName is required in $path, but it is not installed. Please install $packageName in $path"
	}
	return $package.Path
}

function Remove-Directory($path) {
	Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-AssemblyFileVersion($assemblyInfoFile) {
	$line = Get-Content $assemblyInfoFile | Where { $_.Contains("AssemblyFileVersion") }
	if (!$line) {
		$line = Get-Content $assemblyInfoFile | Where { $_.Contains("AssemblyVersion") }
		if (!$line) {
			throw "Couldn't find an AssemblyFileVersion or AssemblyVersion attribute"
		}
	}
	return $line.Split('"')[1]
}

function Set-Version($projectPath, $version) {
	$assemblyInfoFile = "$projectPath\Properties\AssemblyInfo.cs"
	if ($version) {
		if ((Test-Path $assemblyInfoFile)) {
			Write-Host "Updating $assemblyInfoFile"
			$newAssemblyVersion = 'AssemblyVersion("' + $version + '")'
			$newAssemblyFileVersion = 'AssemblyFileVersion("' + $version + '")'
			$newFileContent = Get-Content $assemblyInfoFile |
				%{ $_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyVersion } |
				%{ $_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyFileVersion }
			Set-Content $assemblyInfoFile $newFileContent
		}
	}
	else {
		Write-Host "Getting version from $assemblyInfoFile"
		$version = Get-AssemblyFileVersion $assemblyInfoFile
	}
	return $version
}

function Resolve-PackageVersion($prereleaseVersion) {
	if (![string]::IsNullOrEmpty($prereleaseVersion)) {
		$version = ([string]$input).Split('-')[0]
		$date = Get-Date
		$parsed = $prereleaseVersion.Replace("{date}", $date.ToString("yyMMddHHmm"))
		return "$version-$parsed"
	}
	else {
		return $input
	}
}

function Import-Scripts() {
	param([String[]] $scripts)
	foreach($script in $scripts) {
		Include "$PSScriptRoot\scripts\$script.ps1"
	}
	if ($env:TEAMCITY_VERSION) {
		FormatTaskName "##teamcity[blockOpened name='{0}']"
		
		TaskTearDown {
			"##teamcity[blockClosed name='$($psake.context.currentTaskName)']"
		}
	}
}

function Get-TestProjectsFromSolution($solution, $basePath) {
	$projects = @()
	if (Test-Path $solution) {
		Get-Content $solution |
		Select-String 'Project\(' |
		ForEach-Object {
			$projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };
			if($projectParts[2].EndsWith(".csproj") -and $projectParts[1].EndsWith("Tests")) {
				$file = $projectParts[2].Split("\")[-1]
				$path = $projectParts[2].Replace("\$file", "")
				
				$projects += New-Object PSObject -Property @{
					Name = $projectParts[1];
					File = $file;
					Path = $path;
					Types = @(Get-TestTypesForPath $path $basePath); # Must be wrapped in @() otherwise might not return an array
				}	
			}
		}
	}
	return $projects
}

function Get-SolutionConfigurations($solution) {
	Get-Content $solution |
	Where-Object {$_ -match "(?<config>\w+)\|"} |
	%{ $($Matches['config'])} |
	Select -uniq
}

function Get-TestTypesForPath($path, $basePath) {
	$types = @()
	$mspec = Get-PackageInfo $path "Machine.Specifications"
	if($mspec.Exists) {
		if($mspec.Number -ge 90) {
			$mspecRunnerPath = Get-RequiredPackagePath ".nuget" "Machine.Specifications.Runner.Console"
		}
		else {
			$mspecRunnerPath = $mspec.Path
		}
		
		$types += New-Object PSObject -Property @{
			Name = "MSpec";
			RunnerExecutable = "$mspecRunnerPath\tools\mspec-clr4.exe";
		}
	}
	
	$nunit = Get-PackageInfo $path "NUnit"
	if ($nunit.Exists) {
		$nunitRunnerPath = Get-RequiredPackagePath ".nuget" "NUnit.Runners"
		
		$specflow = Get-PackageInfo $path "SpecFlow"
		if ($specflow.Exists) {
			New-Item "$($specflow.Path)\tools\specflow.exe.config" -Type file -Force -Value "<?xml version=""1.0"" encoding=""utf-8"" ?> <configuration> <startup> <supportedRuntime version=""v4.0.30319"" /> </startup> </configuration>" | Out-Null
			$types += New-Object PSObject -Property @{
				Name = "SpecFlow";
				RunnerExecutable = "$nunitRunnerPath\tools\nunit-console.exe";
				SpecflowExecutable = "$($specflow.Path)\tools\specflow.exe";
			}
		}
		else {
			$types += New-Object PSObject -Property @{
				Name = "NUnit";
				RunnerExecutable = "$nunitRunnerPath\tools\nunit-console.exe";
			}
		}
	}
	
	if (Test-Path $basePath\$path\js\runner.js) {
		$chutzpahPath = Get-RequiredPackagePath ".nuget" "Chutzpah"
		$types += New-Object PSObject -Property @{
			Name = "Chutzpah"; 
			RunnerExecutable = "$chutzpahPath\tools\chutzpah.console.exe";
		}
	}
	return $types
}

function Get-PackageInfo($path, $packageName) {
	if (!(Test-Path "$path\packages.config")) {
		return New-Object PSObject -Property @{
			Exists = $false;
		}
	}

	[xml]$packagesXml = Get-Content "$path\packages.config"
	$package = $packagesXml.packages.package | Where { $_.id -eq $packageName }
	if (!$package) {
		return New-Object PSObject -Property @{
			Exists = $false;
		}
	}

	$versionComponents = $package.version.Split('.')
    [array]::Reverse($versionComponents)
		
	$numericalVersion = 0
	$modifier = 1
		
	foreach ($component in $versionComponents) {
		$numericalVersion = $numericalVersion + ([int]$component * $modifier)
		$modifier = $modifier * 10
	}
		
	return New-Object PSObject -Property @{
		Exists = $true;
		Version = $package.version;
		Number = $numericalVersion;
		Name = $package.id;
		Path = "$PackagesPath\$($package.id).$($package.version)"
	}
}

function Get-ValueOrDefault($value, $default) {
	if ($value -or $value -eq "") {
		return $value
	}
	else {
		return $default
	}
}

function Get-IsLocalTest($configuration, $path) {
	[xml](Get-Content "$path/app.$configuration.config") |
	Select-Xml "//configuration/appSettings/add[@key='local']" |
	%{ $_.Node.Attributes["value"].Value } |
	Select -First 1
}

function Set-ConfigValue($key, $value, $path) {
	$xml = [xml](Get-Content $path)
	$node = $xml.Configuration.appSettings.Role | Where { $_.key -eq $key }
    $node.Value = $value
	$xml.Save($path)
}

function Update-CacheBust($projectPath, $cacheFiles, $cacheBusterPattern) {
	$cacheFiles.Split(";") | foreach {
		Write-Host "Replacing the cache busters in $_"
		(Get-Content $projectPath\$_) -replace $cacheBusterPattern, (Get-Date).ToFileTime() | Set-Content $projectPath\$_
	}
}

function Merge-Application($ilMergePath, $outputPath, $projectName) {
	Write-Host "Merging application executables and assemblies"
	$exeNames = Get-ChildItem -Path "$outputPath\*" -Filter *.exe | ForEach-Object { """" + $_.FullName + """" }
	$assemblyNames = Get-ChildItem -Path "$outputPath\*" -Filter *.dll | ForEach-Object { """" + $_.FullName + """" }
	
	$assemblyNamesArgument = [System.String]::Join(" ", $assemblyNames)
	$exeNamesArgument = [System.String]::Join(" ", $exeNames)
	
	$appFileName = "$outputPath\$projectName.exe"
	
	Invoke-Expression "$ilMergePath\tools\ILMerge.exe /t:exe /targetPlatform:""v4"" /out:$appFileName $exeNamesArgument $assemblyNamesArgument"
	
	Get-ChildItem -Path "$outputPath\*" -Exclude *.exe,*.config | foreach { $_.Delete() }
}

function Get-ProjectName($projectFile) {
	$projectName = (Split-Path $projectFile -Leaf)
	$projectName = $projectName.Substring(0, $projectName.LastIndexOf("."))
	return $projectName
}

function Get-ProjectFile($basePath, $projectName) {
	$projectFile = "$basePath\$projectName.Cloud\$projectName.Cloud.ccproj"
	if (!(Test-Path $projectFile)) {
		$projectFile = "$basePath\$projectName\$projectName.csproj"
	}
	return $projectFile
}

function Get-OutputPath($basePath, $buildsPath, $projectName) {
	$projectFile = Get-ProjectFile $basePath $projectName
	$projectName = Get-ProjectName $projectFile
	$outputPath = "$buildsPath\$projectName"
	return $outputPath
}

function Convert-Project($config, $basePath, $projectName, $outputPath, $azureTargetProfile) {
	$projectFile = Get-ProjectFile $basePath $projectName
	$isCloudProject = $projectFile.EndsWith("ccproj")
	$isWebProject = (((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path $projectFile) -ne $null) -and ((Select-String -pattern "<OutputType>WinExe</OutputType>" -path $projectFile) -eq $null))
	$isWinProject = (((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path $projectFile) -eq $null) -and ((Select-String -pattern "<OutputType>WinExe</OutputType>" -path $projectFile) -ne $null))
	$isExeProject = (((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path $projectFile) -eq $null) -and ((Select-String -pattern "<OutputType>Exe</OutputType>" -path $projectFile) -ne $null))
	
	$projectName = Get-ProjectName $projectFile
	if ($isCloudProject) {
		"Compiling $projectName to $outputPath"
		exec { msbuild $projectFile /p:Configuration=$config /nologo /p:DebugType=None /p:Platform=AnyCpu /t:publish /p:OutputPath=$outputPath\ /p:TargetProfile=$azureTargetProfile /verbosity:quiet }
	}
	elseif ($isWebProject) {
		"Compiling $projectName to $outputPath"
		exec { msbuild $projectFile /p:Configuration=$config /nologo /p:DebugType=None /p:Platform=AnyCpu /p:WebProjectOutputDir=$outputPath /p:OutDir=$outputPath\bin /verbosity:quiet }
	}
	elseif ($isWinProject -or $isExeProject) {
		"Compiling $projectName to $outputPath"
		exec { msbuild $projectFile /p:Configuration=$config /nologo /p:DebugType=None /p:Platform=AnyCpu /p:OutDir=$outputPath /verbosity:quiet }
	}
	elseif (!$projectName.EndsWith("Tests")) {
		"Compiling $projectName"
		exec { msbuild $projectFile /p:Configuration=$config /nologo /p:Platform=AnyCpu /verbosity:quiet }
	}
}

function Convert-ProjectTests($config, $basePath, $projectName, $projectTests) {
	if ($projectTests.Length -gt 0) {
		foreach ($projectTest in $projectTests) {
			"Compiling $($projectTest.Name)"
			$projectFile = "$basePath\$($projectTest.Path)\$($projectTest.File)"
			if (Test-Path $projectFile) {
				if(@($projectTest.Types | ?{$_.Name -eq "specflow"}).Length -gt 0) {
					@(Get-SolutionConfigurations "$projectName.sln") | Where { (Get-IsLocalTest $_ $projectTest.Path) -ne $true } | foreach {
						exec { msbuild $projectFile /p:Configuration=$_ /nologo /verbosity:quiet }
					}
				}
				else {
					exec { msbuild $projectFile /p:Configuration=$config /nologo /verbosity:quiet }
				}
			}
		}
	}
}

function Push-Package($basePath, $package, $nugetPackageSource, $nugetPackageSourceApiKey) {
	if (![string]::IsNullOrEmpty($nugetPackageSourceApiKey) -and $nugetPackageSourceApiKey -ne "LoadFromNuGetConfig") {
		exec { & .nuget\NuGet.exe push $package -Source $nugetPackageSource -ApiKey $nugetPackageSourceApiKey }
	}
	else {
		exec { & .nuget\NuGet.exe push $package -Source $nugetPackageSource }
	}
}

function New-SpecFlowReport($configurations, $buildsPath) {
	$template = [IO.File]::ReadAllText("$PSScriptRoot\specflow_report_template.html");
	
	$links = "";
	$configurations | foreach {
		$links = $links + "<li data-configuration='$_'>$_</li>"
	}
	
	$output = $template -replace "%links%", $links
	
	New-Item $buildsPath\specresult.html -Type file -Force -Value $output | Out-Null
}