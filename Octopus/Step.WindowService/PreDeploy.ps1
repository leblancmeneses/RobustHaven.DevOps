Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1

if( Test-Path "_PreDeploy.ps1" )
{
    $extensionFile = Resolve-Path "_PreDeploy.ps1"
	& $extensionFile
	Remove-Item $extensionFile -ErrorAction SilentlyContinue 
}