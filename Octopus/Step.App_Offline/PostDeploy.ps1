Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1

# set $WebPackageName = "Dashboard" inside octopus portal - application to bring down with app offline file
# set $Tenant = "IR|RH" inside octopus portal - used to show app offline image for specific company

$packageLocation = pwd
$packageVersion = [System.IO.Path]::GetFileName($packageLocation)
$appOfflineFile = "$packageLocation\App_Offline.htm"

(Get-Content $appOfflineFile) | Foreach-Object {
	$_ -replace '\$\(Tenant\)', $Tenant
	} | Set-Content $appOfflineFile

if ((Test-Path -path "..\..\$WebPackageName"))
{
	cd "..\..\$WebPackageName"


	$myWebAppRootFolder = pwd
	
	# current folders sorted by filename desc.
	$versionFolders = @( Get-ChildItem | 
				Sort-Object LastWriteTime -Descending)


	# most current deployment first
	# break after execution as we only want to apply app_offline to previous deployment.
	for($i=0 ; $i -lt $versionFolders.Count; $i++)
	{
		cp $appOfflineFile ("$myWebAppRootFolder\{0}\App_Offline.htm" -f $versionFolders[$i].Name)
		break;
	}
}


cd $packageLocation


Invoke-ElevatedCommand  {
	param(
	    [string]$WebAppName 
	)

	Import-Module WebAdministration

	Write-Host "Will get the application pool of: IIS:\Sites\$WebAppName and try to restart"
	$appPoolName = Get-ItemProperty "IIS:\Sites\$WebAppName" ApplicationPool 
	Restart-WebAppPool "$($appPoolName.applicationPool)" 
	Write-Host "restart of apppool succeeded."

} -ArgumentList @("$WebPackageName")


Purge-PastDeployment $packageLocation
