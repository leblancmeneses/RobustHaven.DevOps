function Purge-MsmqQueue ([string]$QueueFullPath)
{
	Write-Host "Attempting to clear $QueueFullPath"
	[Reflection.Assembly]::LoadWithPartialName("System.Messaging") | Out-Null 
	$queue = New-Object -TypeName "System.Messaging.MessageQueue"
	$queue.Path = $QueueFullPath
	$messagecount = $queue.GetAllMessages().Length 
	$queue.Purge() 
	Write-Host "$QueueFullPath has been purged of $messagecount messages."
}

function Purge-PastDeployment ([string]$PackageDirectory)
{
	# Remove-Item "PostDeploy.ps1" -ErrorAction SilentlyContinue 
	Remove-Item "DeployFailed.ps1" -ErrorAction SilentlyContinue 

<#
	cd $PackageDirectory
	cd ..
	$path = Get-Location
	$folders = @(Get-ChildItem -Path $path | Where-Object {$_.PsIsContainer})
		
	# +1 to keep minimum currently deployed folder
	$keep = $RobustHavenKeepPastDeployment + 1
	if ($folders.Count -gt $keep) {
		$folders |Sort-Object CreationTime |Select-Object -First ($folders.Count - $keep)| Remove-Item -recurse -Force
	}


	# Change the value $oldTime in order to set a limit for files to be deleted.
	$oldTime = [int]7 # 30 days
	$paths = @("$PackageDirectory\..\..\..\.Tentacle\Packages", "$PackageDirectory\..\..\..\..\Data\PackageCache")
	foreach($path in $paths)
	{
		if(Test-Path $path)
		{
			cd $path
	$filter = [regex] "^$OctopusPackageName\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+_"
	Write-Host "Trying to delete $OctopusPackageName cached packages older than $oldTime days, in the folder $path" -ForegroundColor Green
			Get-ChildItem ".\*" -Recurse | Where-Object {$_.Name -match $filter} | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | Remove-Item -Force
		}
		else
		{
			Write-Host "Test-Path $path is false"
		}
	}
#>

	cd $PackageDirectory
}

function Test-Administrator
{
	$user = [Security.Principal.WindowsIdentity]::GetCurrent();
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}


function Invoke-ElevatedCommand
{
	param
	(
		[ScriptBlock]$Command = $(throw "The parameter -Command is required."),
		[System.Collections.ArrayList]$ArgumentList = $(throw "The parameter -ArgumentList is required.")
	)

	if(Test-Administrator)
	{
		if (Get-Command "PowerShell" -errorAction SilentlyContinue)
		{
			Write-Host "running with PowerShell cmdlet"
			PowerShell -Command $Command -args $ArgumentList
		}
		else
		{
			Write-Host "running with Start-Job cmdlet"
			Start-Job -ScriptBlock $Command -ArgumentList $ArgumentList
			Wait-Job *
			Receive-Job *
			Remove-Job *
		}
	}
	else
	{
		Write-Host "running with Invoke-Command cmdlet"
		$computerName = gc env:computername
		$username = $ElevatedServiceAccount
		$password = gc "$ElevatedServiceAccountPasswordLocation" 
		$securestring = New-Object -TypeName System.Security.SecureString
		$password.ToCharArray() | ForEach-Object {$securestring.AppendChar($_)}

		$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $securestring

		Invoke-Command -ScriptBlock $Command -comp $computerName -cred $cred -ArgumentList $ArgumentList
	}
}


# make a request to the site and return the status code. Return 'Failed' if anything goes wrong
function Test-Url([string]$url)
{
    $req = [System.Net.HttpWebRequest]::Create($url)
    try
    {
        $res = $req.GetResponse()
        $res.StatusCode
    }
    catch
    {
        "Failed"
    }
}

Export-ModuleMember -function * -alias *