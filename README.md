# psakify

This package provides PowerShell scripts to automatically compile, test, package and deploy your code based on a set of conventions. It is based on *psake* and consists of
a set of *psake* tasks written in Powershell. There is a predefined psake properties block and a number of predefined tasks as well as some useful functions which you can
use to help create your own custom tasks.

This package also has some soft dependencies on other packages, depending on which build features you use:

* **Machine.Specifications.Runner.Console**: if you have any tests using Machine.Specifications version 0.9.0 or higher
* **NUnit.Runners**: if you have any tests using NUnit
* **Chutzpah**: if you have a \js\runner.js file in your test project
* **ILMerge**: if you have ILMerge installed for a project, it will be used after compiling to merge the output assemblies of that project
* **7-Zip**: if you use the create7zip task
* **OctopusTools**: if you use the octopack task

## Project layout

The following is a description of a standard project layout:

    root  
        projectName.sln
        psake.bat // contains the runner that will execute the tasks. Created when installing NuGet package (do not modify)
        tasks.ps1 // contains the imported tasks and your own custom tasks
        .\builds
        .\projectName
            projectName.csproj
		.\projectName.Cloud
			projectName.Cloud.ccproj
        .\projectName.Tests
            projectName.Tests.csproj

## Installation

You can get it from [NuGet](https://www.nuget.org/packages/psakify). You need to install the package into the main project of the solution.
See [Notes on installing solution level NuGet packages](#notes) for details.

The package will install two files:

* psake.bat: This file, added to the solution folder, is the runner. You can run this with the task name(s) (eg: psake compile[, ...]). Do not modify this file.
* .psakify.ps1: This file, added to the main project, by default imports all the predefined tasks. You can remove the ones you don't need and you can also add your own tasks,
as well as any inline initialization. To override a task, remove it from the imports and redefine it. Upon updating, this file will be overwritten. Any customizations you
had made would then need to be merged back in. This file has a build action of "None" so that Visual Studio excludes it from build output and it's name starts with a dot
so that NuGet will ignore it when creating a NuGet package.

## Execution
The psake.bat file is the launcher, and is responsible for checking if NuGet.exe exists in the .nuget folder and downloading it if necessary, restoring NuGet packages,
loading the BuildAutomation functions module, assigning global variables, invoking *psake* with the given arguments, and propogating the build status via the exit code.
To specify a specific MSBuild framework version for *psake*, you can set the **PSAKE_FRAMEWORK** environment variable.

## Tasks
The following *psake* tasks are available: (For a list of variables used in the explanations, see below)

### <a name="clean">Clean</a>
Deletes all files below the $buildsPath and all bin and obj folders below $basePath

### <a name="compile">Compile</a>
Compile the main project and all test projects against the chosen $config. (Exception: in the case of a SpecFlow project, it will find all available
configurations and compile it against every configuration. See [Test](#test) for more info). If it finds ILMerge installed in the main project, it runs
[Merge-Application](#merge-application) on the output assemblies of the main project.

Depends on [Clean](#clean)

### Create7zip
Creates a zip file of everything inside the $outputPath.

Requires 7zip to be installed and added to the Path variable

### DeployAzure
Deploys an Azure web or worker role.

Requirements:  

* Azure Powershell CmdLets need to be installed. Check the following directories for a file called "Azure.psd1":  
  * C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\
  * C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\
* The following variables need to be defined either via the command-line, through environment variables or entered when prompted:
  * $azureSubscription
  * $azureStorageAccount
  * $azureServiceName: Name of the cloud service you're deploying
  * $azurePublishSettingsFile: The .pubSettings-file you can download from Azure

### DeployAzureWebsite
Deploys an Azure website

Requirements:

* $azurePublishProfile
* $azurePassword

### Grunt
Executes grunt inside the $basePath\$projectName

Depends on [NpmInstall](#npminstall)

### <a name="npminstall">NpmInstall</a>
Restores node packages inside $basePath\$projectName

Requires Node to be installed

### OctoPack
Creates an Octopus NuGet package and pushes it to the repository.

* The following variables need to be either defined via the command-line, through environment variables or entered when prompted:
  * $octopusPackageSource: Url of your feed
  * $octopusPackageSourceApiKey

Depends on [Test](#test)

### Pack
Creates a NuGet package from $basePath\$projectName\$projectName.csproj

The version will be read from $basePath\$projectName\Properties\AssemblyInfo.cs
If the version is overridden, it will overwrite the value in the AssemblyInfo.cs file

### Push
Pushes all NuGet packages (*.nupkg) found in the $buildsPath.

* Requires the following variables to be passed in or entered when prompted:
  * $nugetPackageSourceBackupPath
  * $nugetPackageSource
  * $nugetPackageSourceApiKey

* Additionally if a package is found with the name "*.symbols.nupkg" it will push it to a symbol source server. For this, the following variables are necessary:
  * $nugetSymbolsPackageSource
  * $nugetSymbolsPackageSourceApiKey

### ReplaceCacheBust
Replaces the text "cacheBuster" in a set of files with the current time stamp.

Requirements:

* $cacheFiles: The list of files to look for the string "cacheBuster"

### <a name="test">Test</a>
Executes tests

This task can execute four types of test.
These are the types of test that can be executed:

* NUnit: when NUnit is found in in the packages.config
* MSpec: when MSpec if found in the packages.config
* Chutzpah: when the file runner.js is found in the directory project\js
* SpecFlow with Selenium: when SpecFlow and NUnit are found in the packages.config

Depends on [Compile](#compile)

#### NUnit
Runs the NUnit runner and outputs nunit.xml to the $buildsPath

#### MSpec
Runs the MSpec runner and outputs the html-file to the $buildsPath

#### ChutzPah
Runs the ChutzPah runner and outputs to the console

#### SpecFlow with Selenium
Executes the unit tests via BrowserStack.com and generates reports in the builds folder. It will generate one html-file with links to the HTML-report of each configuration.

Note: this will run the tests in parallel for each configuration you have defined for the project, except for those where "isLocal=true" in the app.config-file.
For more information on how to use config transforms to execute the tests on different environments see
[Running SpecFlow Acceptance Tests in parallel on BrowserStack](http://www.kenneth-truyers.net/2015/01/03/running-specflow-acceptance-tests-in-parallel-on-browserstack/)

Requirements:

* $browserStackKey: Your API key from BrowserStack automate
* $browserStackProxyHost: Host name of the proxy (optional)
* $browserStackProxyPort: Port of the proxy (optional)

## Functions
The package includes the following functions, which are used by the predefined tasks, but can also be used for your own custom tasks:

* Get-PackagesPath: Gets the configured NuGet packages path relative to the current directory. Invoked by runner on startup and assinged to global variable $PackagesPath
* Get-RequiredPackagePath: Given a folder and package name, it returns the path to the package. An error is thrown if the package is not installed
* Remove-Directory: Recursively deletes a path silently 
* Get-AssemblyFileVersion: Accepts a path to an AssemblyInfo.cs and gets the version
* Set-Version: Accepts a project path and a version. If no version is specified, it will read it from AssemblyInfo.cs otherwise it will write it to AssemblyInfo.cs
* Resolve-PackageVersion: Accepts a string, if not empty just returns it, else it will create a time stamped version
* Import-Scripts: Accepts an array of predefined scripts. The list of available scripts is:
  * properties
  * clean
  * compile
  * create7zip
  * deployazure
  * deployazurewebsite
  * grunt
  * npminstall
  * octopack
  * pack
  * push
  * replacecachebust
  * test
* <a name="get-testprojectsfromsolution">Get-TestProjectsFromSolution</a>: Given a solution file and base path, it finds all projects that end with "Tests" and returns an
array of objects with the following structure:
  * Name: project name
  * File: name of the .csproj-file
  * Path: folder of the .csproj-file
  * Types: list of test types, an array with the following structure:
    * Name: either NUnit, SpecFlow, Chutzpah or MSpec
    * RunnerExecutable: path to the file that can execute the tests
    * SpecflowExecutable: path to the SpecFlow executable (if Name is SpecFlow)
* Get-TestTypesForPath: Returns all the the test types for a specific path (see previous)
* Get-SolutionConfigurations: Parses a .sln-file and returns all available configurations
* Get-TestTypesForPath: Given a project folder and base path, it returns an array with the following structure:
  * Name: either NUnit, SpecFlow, Chutzpah or MSpec
  * RunnerExecutable: path to the file that can execute the tests
  * SpecflowExecutable: path to the SpecFlow executable (if Name is SpecFlow)
* Get-PackageInfo: Given a folder and package name, it returns an object with the following properties:
  * Exists
  * Version
  * Number: numerical representation of the version
  * Name
  * Path
* Get-ValueOrDefault: Returns the value if it's not null, otherwise the default
* Get-IsLocalTest: Given a path and a configuration, it checks whether the variable IsLocal is true in the app.config
* Set-ConfigValue: Given a path to an app|web .config, sets the given value for the given key
* Update-CacheBust: Given a project path, list of files and a cache buster pattern, replaces matched pattern with the current time stamp
* <a name="merge-application">Merge-Application</a>: Uses ILMerge to combine the assemblies into a single executable
* Get-ProjectName: Given the path to the .csproj, extracts the name of the project
* Get-ProjectFile: Given the basePath and projectName, returns the path to the projectName.Cloud.ccproj, if there is one, otherwise returns the path to the projectName.csproj
* Get-OutputPath: Resolves an output path for a given project
* Convert-Project: Compiles a project
* Convert-ProjectTests: Compiles all test projects
* Push-Package: Pushes a package to the specified source
* New-SpecFlowReport: Creates a new HTML-file in the builds folder with links to every SpecFlow report generated by the tests.

## Globals
The following globals are defined by the runner:

* $PsakePath: Set to the path of the *psake* package
* $PackagesPath: Set to the configured NuGet packages path

Note: These cannot be modified.

## Conventions and overrides
The following *psake* properties define the conventions:

* $basePath: The current directory
* $buildsPath: $basePath\builds
* $projectName: Name of the solution-file in the current directory without the .sln extensions
* $outputPath:
  * $buildspath\$projectName.Cloud\$projectName in case of an Azure cloud project
  * $buildspath\$projectName\$projectName in case of a .csproj project
* $projectTests: An array of objects returned from [Get-TestProjectsFromSolution](#get-testprojectsfromsolution)
* $config: Release
* $version: The version in the AssemblyInfo.cs
* $prereleaseVersion: dev{date} - "{date}" will be replaced by the current time stamp
* $octopusPackageSourceApiKey: LoadFromNuGetConfig - signifies that the key should be read from NuGet.Config
* $nugetPackageSourceApiKey: LoadFromNuGetConfig - signifies that the key should be read from NuGet.Config
* $nugetSymbolsPackageSourceApiKey: LoadFromNuGetConfig - signifies that the key should be read from NuGet.Config
* $browserStackProxyPort: 0
* $azurePublishProfile: $basePath\$projectName\Properties\PublishProfiles\$projectName.pubxml
* $azurePackageFile: $outputPath\app.publish\$projectName.Cloud.cspkg

The following *psake* properties are defined with no default value:

* $cacheFiles: A list of files in which to replace cache busters. This should be a string with files separated by ";"
* $octopusPackageSource: A NuGet package source for Octopus packages
* $nugetPackageSource: A NuGet package source for NuGet packages
* $nugetSymbolsPackageSource: A NuGet package source for NuGet symbols packages
* $nugetPackageSourceBackupPath: This is used to back up packages on the file system and so that the push task can check whether or not a package is new and needs to be pushed
* $browserStackProxyHost: The host name of the BrowserStack proxy
* $browserStackKey: The BrowserStack key
* $azurePassword: The password used to publish an Azure website
* $azureTargetProfile: The name of the Azure cloud service configuration to use when building
* $azureSubscription: The Azure subscription name
* $azureStorageAccount: The Azure storage account
* $azureServiceName: The Azure cloud service name
* $azurePublishSettingsFile: An Azure publish settings file
* $azureSlot: The Azure slot to deply into
* $azureSwapAfterDeploy: Whether or not to swap Azure deployments after deploying

These *psake* properties can be overridden in two ways:

* Via the command line:  
psake {task} -properties @{'variable'='{value}'}
* Via environment variables:  
You can add environment variables in the following form:
		
		PSAKE_{PROPERTY_NAME}

A handy way to configure default values for these properties, while still allowing them to be overridden
from the command line is to write the following code before importing the properties script:

		$env:PSAKE_{PROPERTY_NAME} = Get-ValueOrDefault $env:PSAKE_{PROPERTY_NAME} "Default value"

# <a name="notes">Notes on installing solution level NuGet packages</a>

Due to a bug in the Visual Studio Package Manager extension, solution level packages with dependencies are considered to be project level packages and show up as such in the
Package Manager UI. This results in the following:

 * You can install the package if you select at least one of the project checkboxes
 * You can't update the package because it shows greyed out project checkboxes which are unchecked
 * You can't uninstall the package because it shows a manage button instead of an uninstall button

NuGet also has a bug which results in it thinking that a solution level package is installed for all solutions which happen to share the same NuGet repository (the packages
folder). This can happen if you have configured a shared NuGet repository for all of your solutions by setting it in a NuGet.Config file. This is because NuGet looks in the
shared NuGet repository to find packages and then assumes that every package there is installed in the current solution. What NuGet should do is look in the solution level
packages.config file (in the .nuget folder) to determine what packages are installed for the current solution. When a shared NuGet repository is configured, NuGet command
line will refuse to install a package if it is already in the repository (it returns an error saying that the package is already installed). The Visual Studio Package Manager
extension will not show the package on the "Installed" tab, but on the "Online" tab it will show the package as already installed and not display the install button.

>One workaround for this problem is to first delete the package from the shared repository before opening the Visual Studio Package Manager extension, which will then show
the package as not installed on the "Online" tab and it will display the install button. Although unfortunately because Visual Studio retains an open file handle on a package
after installing, you will find that if you are working on mutliple solutions you are not always able to delete the package from the repository, and will need to close
Visual Studio completely in order to release the file handle in order to do so.

>Another workaround for this problem is to hand edit the solution level packages.config file (in the .nuget folder) and manually add the required package xml element, and
then open the Package Manager Console in Visual Studio which causes it to run the init.ps1 file in the tools folder of all packages found in the shared NuGet repository.
However, Visual Studio will only do this once per running instance, so if you need to do it again you will have to close Visual Studio completely and open another instance.

What's more is that these workarounds will only help to install the package. They don't help with the problem that when uninstalling the package for one solution, it removes
the package folder from the shared NuGet repository resulting in other solutions needing to restore it again. Furthermore, updating packages that you have installed using
either of these workarounds is also impossible using the Visual Studio Package Manager extension.

To support updating and uninstalling which is sadly not yet fully supported for solution level packages, this package has been designed to be a project level package instead
of a solution level package. However, it still takes a dependency on *psake* which is a solution level package, so the above problem remains for *pake*. This is still
enough of a problem to cause significant headaches when managing packages for many solutions sharing the same NuGet repository. All of this is a bit nasty to say the least,
and neither of the above workarounds provide much respite, so in order for all of the features of the Visual Studio Package Manager extension to remain functional,
unfortunately the recommended practice is to forgo having a shared NuGet repository.