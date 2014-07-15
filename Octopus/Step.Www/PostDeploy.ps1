Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1

if( Test-Path "_PostDeploy.ps1" )
{
    $extensionFile = Resolve-Path "_PostDeploy.ps1"
	& $extensionFile
}

$packageLocation = pwd

$expectedConfig = "$OctopusEnvironmentName-Web.config"

rm "Web.config"
cp $expectedConfig "Web.config"




foreach($url in $WarmUpUrls.split(';'))
{
	$count = 0;
	while ($count -le 10)
	{
		$count += 1;
		$status = Test-Url($url)
		if ($status -eq "OK")
		{
			Write-Host "$url Attempt $count - $status"
			break;
		}
		else
		{
			Write-Host "$url Attempt $count - $status"
		}

		Start-Sleep -s 3
	} 
}



Purge-PastDeployment $packageLocation