Set-StrictMode -Version Latest

if( Test-Path "_Deploy.ps1" )
{
    $extensionFile = Resolve-Path "_Deploy.ps1"
	& $extensionFile
}
