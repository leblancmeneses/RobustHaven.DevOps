Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1

$packageLocation = pwd


if([System.Convert]::ToBoolean($IsAfterSuccessRemoveBackups))
{
	Write-Host "Deleting $BackupLocation\$DevEnvironment\*.bak"
	Remove-Item "$BackupLocation\$DevEnvironment\*.bak" -Force -Recurse
}

if([System.Convert]::ToBoolean($IsAfterSuccessRemoveRestoreUpdates))
{
	Write-Host "Deleting $RestoreUpdatesLocation\$DevEnvironment\*.bak"
	Remove-Item "$RestoreUpdatesLocation\$DevEnvironment\*.bak" -Force -Recurse
}

Purge-PastDeployment $packageLocation
