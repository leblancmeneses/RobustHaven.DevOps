Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1

Remove-Item "PreDeploy.ps1" -ErrorAction SilentlyContinue 
if( Test-Path "_Deploy.ps1" )
{
    $extensionFile = Resolve-Path "_Deploy.ps1"
	& $extensionFile
	Remove-Item $extensionFile -ErrorAction SilentlyContinue 
}


$service = Get-Service $ServiceName -ErrorAction SilentlyContinue
$fullPath = Resolve-Path $ServiceExecutable



Write-Host "rm $ServiceConfiguration"
rm "$ServiceConfiguration"

$expectedConfig = "$OctopusEnvironmentName-App.config"
Write-Host "mv $expectedConfig $ServiceConfiguration"
mv $expectedConfig "$ServiceConfiguration"

Write-Host "removing configs specific to other environments"
foreach($config in @(Get-ChildItem *-App.config))
{
	if($config -NotMatch $expectedConfig)
	{
		rm $config
	}
}



if (! $service)
{
	if( Test-Path "_WithCustomInstall.ps1" )
	{
		$extensionFile = Resolve-Path "_WithCustomInstall.ps1"
		& $extensionFile
		Remove-Item $extensionFile -ErrorAction SilentlyContinue 
	}
	else
	{
		Write-Host "The service will be installed"
		Invoke-ElevatedCommand {
			param(
				[string]$ServiceName,
				[string]$fullPath,
				[string]$Account,
				[string]$Password
			)
			New-Service -Name $ServiceName -BinaryPathName $fullPath -StartupType Automatic
		} -ArgumentList @("$ServiceName","$fullPath", "$Account", "$Password")
				
		$searchString = "Name='"+$ServiceName+"'"
		$service = gwmi win32_service -filter $searchString
		# Account must be specified as Domain\Username
		# User must have log on as service rights assigned, otherwise service will not start with error: The service did not start due logon failure.
		$service.Change($null,$null,$null,$null,$null,$null,$Account,$Password,$null,$null,$null)  
	}
}
else
{
	if( Test-Path "_WithCustomReconfigure.ps1" )
	{
		$extensionFile = Resolve-Path "_WithCustomReconfigure.ps1"
		& $extensionFile
		Remove-Item $extensionFile -ErrorAction SilentlyContinue 
	}
	else
	{
		Write-Host "The service will be stopped and reconfigured"
		Invoke-ElevatedCommand {
			param(
				[string]$ServiceName,
				[string]$fullPath 
			)
	    	Stop-Service $ServiceName -Force
	    	& "sc.exe" config "$ServiceName" binPath= $fullPath start= auto | Write-Host
		} -ArgumentList @("$ServiceName","$fullPath")
	}
}

Start-Service $ServiceName
