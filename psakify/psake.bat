@echo off
IF "%PSAKE_FRAMEWORK%"=="" SET PSAKE_FRAMEWORK=4.5.1x64
powershell -NoProfile -ExecutionPolicy Unrestricted -Command ^
$ErrorActionPreference = 'Stop'; ^
if (!(Test-Path ".nuget\NuGet.exe")) ^
{ ^
	Write-Host "Downloading NuGet.exe"; ^
	(New-Object system.net.WebClient).DownloadFile('https://www.nuget.org/nuget.exe', '.nuget\NuGet.exe'); ^
} ^
Write-Host "Restoring NuGet packages"; ^
.nuget\NuGet.exe restore; ^
Import-Module %PSAKIFY_PATH%\Functions.psm1; ^
$PackagesPath = Get-PackagesPath; ^
$PsakePath = Get-RequiredPackagePath ".nuget" "psake"; ^
Import-Module "$PsakePath\tools\psake.psm1"; ^
Invoke-psake .\%PROJECT_NAME%\.psakify.ps1 -nologo -framework %PSAKE_FRAMEWORK% %*; ^
if (!$psake.build_success) { exit 1 };
IF NOT "%TEAMCITY_VERSION%"=="" (EXIT %ERRORLEVEL%) ELSE echo Command exited with code %ERRORLEVEL%