Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1

Remove-Item "Deploy.ps1" -ErrorAction SilentlyContinue 
if( Test-Path "_PostDeploy.ps1" )
{
    $extensionFile = Resolve-Path "_PostDeploy.ps1"
	& $extensionFile
	Remove-Item $extensionFile -ErrorAction SilentlyContinue 
}

$packageLocation = pwd


Purge-PastDeployment $packageLocation