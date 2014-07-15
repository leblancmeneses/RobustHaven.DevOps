Set-StrictMode -Version Latest

# These variables should be set via the Octopus web portal:
#
#   SleepSeconds        - How long to block before the rest of the deployment process begins
# 

Import-Module .\OctopusDeployment.psm1

$packageLocation = pwd


$a = Get-Date
$a = $a.AddSeconds($SleepSeconds)


Write-Host 'The system will be down for maintenance at $(a.ToShortTimeString())'


Start-Sleep -s $SleepSeconds

Purge-PastDeployment $packageLocation