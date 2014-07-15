Set-StrictMode -Version Latest

if( Test-Path "_PreDeploy.ps1" )
{
    $extensionFile = Resolve-Path "_PreDeploy.ps1"
	& $extensionFile
}