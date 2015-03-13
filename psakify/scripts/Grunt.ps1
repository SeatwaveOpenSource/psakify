task grunt -depends npminstall {
	Set-Location "$basePath\$projectName"
	exec { grunt build --environment=$gruntEnvironment }
}