task npminstall {
	"Restoring node packages"
	Set-Location "$basePath\$projectName"
	exec { npm install }
	exec { npm install -g grunt-cli }
}