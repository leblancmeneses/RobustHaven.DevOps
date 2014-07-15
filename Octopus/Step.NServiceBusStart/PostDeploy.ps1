Set-StrictMode -Version Latest

# These variables should be set via the Octopus web portal:
#	$Distributors                               - Comma seperated string
#	$Processors                                 - Comma seperated string
# 

Import-Module .\OctopusDeployment.psm1

$packageLocation = pwd

Write-Host 'Starting NServiceBusDistributor'
foreach($distributor in $Distributors.split(",",[StringSplitOptions]'RemoveEmptyEntries'))
{
    $service = Get-Service $distributor -ErrorAction SilentlyContinue
    if ($service)
    {
		Write-Host $distributor
		Invoke-ElevatedCommand  {
			param(
				[string]$distributor
			)
        	Start-Service $distributor
		} -ArgumentList @("$distributor")
    }
}

Write-Host 'Starting Processors'
foreach($processor in $Processors.split(",",[StringSplitOptions]'RemoveEmptyEntries'))
{
    $service = Get-Service $processor -ErrorAction SilentlyContinue
    if ($service)
    {
		Write-Host $processor
		Invoke-ElevatedCommand {
			param(
				[string]$processor
			)
        	Start-Service $processor
		} -ArgumentList @("$processor")
    }
}


Purge-PastDeployment $packageLocation