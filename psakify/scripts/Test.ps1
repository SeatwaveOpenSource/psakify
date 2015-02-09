task test -depends compile {
	if ($projectTests.Count -eq 0) {
		"Found no tests"
	}
	
	New-Item $buildsPath -Type directory -Force | Out-Null
	Set-Location $basePath
	foreach ($projectTest in $projectTests) {
		foreach ($type in $projectTest.Types) {
			switch ($type.Name) {
				"MSpec" {
					exec { & $($type.RunnerExecutable) --html $buildsPath $basePath\$($projectTest.Path)\bin\$config\$($projectTest.Name).dll }
					continue
				} 
				"NUnit" {
					exec { & $($type.RunnerExecutable) /xml:$buildsPath\nunit.xml /nologo $basePath\$($projectTest.Path)\bin\$config\$($projectTest.Name).dll }
					continue
				}
				"SpecFlow" {
					try {
						$configurations = @(Get-SolutionConfigurations "$projectName.sln") | Where { (Get-IsLocalTest $_ $projectTest.Path) -ne $true }
						if (!$browserStackKey) {
							$browserStackKey = Read-Host "Please enter your BrowserStack key"
						}
						$params = $browserStackKey, "-forcelocal"
							
						if($browserStackProxyHost -ne "" -and $browserStackProxyPort -ne 0) {
							$params += "-proxyHost $browserStackProxyHost"
							$params += "-proxyPort $browserStackProxyPort"
							
							$configurations | foreach {
								Set-ConfigValue "proxy" "$($browserStackProxyHost):$browserStackProxyPort" "$($projectTest.Path)/bin/$_/$($projectTest.Name).dll.config"
							}
						}
						Start-Process "$basePath\$($projectTest.Path)\bin\$($configurations[0])\browserstacklocal.exe" $params
						
						$configurations | foreach {
							Start-Job -ScriptBlock {
								param($psakePath, $type, $buildsPath, $configuration, $basePath, $projectTest)
								
								Set-Location $basePath
								Import-Module "$psakePath\tools\psake.psm1";
								try {
									exec { & $type.RunnerExecutable /labels /out=$buildsPath\nunit_$configuration.txt /xml:$buildsPath\nunit_$configuration.xml /nologo /config:$configuration $basePath\$($projectTest.Path)\bin\$configuration\$($projectTest.Name).dll }
								}
								finally {
									exec { & $type.SpecflowExecutable nunitexecutionreport $basePath\$($projectTest.Path)\$($projectTest.File) /out:$buildsPath\specresult_$configuration.html /xmlTestResult:$buildsPath\nunit_$configuration.xml /testOutput:$buildsPath\nunit_$configuration.txt }
								}
								
							} -ArgumentList $PsakePath, $type, $buildsPath, $_,  $basePath, $projectTest 
						}
						Get-Job | Wait-Job
						Get-Job | Receive-Job
					}
					finally {
						New-SpecFlowReport $configurations $buildsPath
						Stop-Process -processname "browserstacklocal"
					}
					continue
				} 
				"Chutzpah" {
					exec { & $($type.RunnerExecutable) $basePath\$($projectTest.Path)\js\runner.js }
					continue
				} 
			}
		}
	}
}