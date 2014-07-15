Set-StrictMode -Version Latest

# These variables should be set via the Octopus web portal:
#	$Distributors                               - Comma seperated string
#	$Processors                                 - Comma seperated string
#   $AfterStoppingDistributorSleepSeconds       - How long to block before the rest of the deployment process begins
#   $AfterStoppingProcessorsSleepSeconds        - How long to block before the rest of the deployment process begins
# 

Import-Module .\OctopusDeployment.psm1

$packageLocation = pwd


Write-Host 'Stopping NServiceBusDistributor'
foreach($distributor in $Distributors.split(",",[StringSplitOptions]'RemoveEmptyEntries'))
{
    $service = Get-Service $distributor -ErrorAction SilentlyContinue
    if ($service)
    {
		Write-Host $distributor
		Invoke-ElevatedCommand {
			param(
				[string]$distributor
			)
			Stop-Service $distributor -Force
		} -ArgumentList @("$distributor")
    }
}

Start-Sleep -s $AfterStoppingDistributorSleepSeconds


Write-Host 'Stopping Processors'
foreach($processor in $Processors.split(",",[StringSplitOptions]'RemoveEmptyEntries'))
{
    $service = Get-Service $processor -ErrorAction SilentlyContinue
    if ($service)
    {
		Write-Host $processor
		if($service.Status -notlike 'Stopped' )
		{

			$wmiManagementObject = Get-WmiObject -Class Win32_Service -Filter "Name='$processor'"
			$process = Get-Process -Id $wmiManagementObject.ProcessId 
			Write-Host "Found process id: " $wmiManagementObject.ProcessId " - " $process.ProcessName 
			$i = 0
    		do
			{
				$thresholdMillis = 60

				#http://stackoverflow.com/questions/2784881/how-to-check-if-process-is-idle-c-sharp
				if($process.TotalProcessorTime -ne $null)
                {
                    $begin_cpu_time = [TimeSpan]$process.TotalProcessorTime
                }
                else
                {
                    $begin_cpu_time = [TimeSpan]::Zero
                }
                

				Start-Sleep -s 30
				$process.Refresh();
				

				if($process.TotalProcessorTime -ne $null)
                {
                    $end_cpu_time = [TimeSpan]$process.TotalProcessorTime
                }
                else
                {
                    $end_cpu_time = [TimeSpan]::Zero
                }
				
				Write-Host ($end_cpu_time - $begin_cpu_time)
				Write-Host $([TimeSpan]::FromMilliseconds($thresholdMillis))
				$isInIdle = ($end_cpu_time - $begin_cpu_time) -lt [TimeSpan]::FromMilliseconds($thresholdMillis);
				Write-Host $isInIdle
				
			} while(!$isInIdle -and $i++ -lt 10)
    
			Invoke-ElevatedCommand  {
				param(
					[string]$processor
				)
				Stop-Service $processor -Force
			} -ArgumentList @("$processor")
			Write-Host "was turned off " $process.ProcessName
		}
		else
		{
			Write-Host "was already turned off "
		}
    }
}

Start-Sleep -s $AfterStoppingProcessorsSleepSeconds

Purge-PastDeployment $packageLocation