Set-StrictMode -Version Latest

$packageLocation = pwd
$packageVersion = [System.IO.Path]::GetFileName($packageLocation)

$MSSQLTaskFile = "$packageLocation\MSSQLTask.config"
(Get-Content $MSSQLTaskFile) | Foreach-Object {
	$_ -replace '\$\(DbInstance\)', $DbInstance
	} | Set-Content $MSSQLTaskFile

if(!(Test-Path "$BackupLocation\$DevEnvironment"))
{
	New-Item "$BackupLocation\$DevEnvironment" -type directory
}

if(!(Test-Path "$RestoreUpdatesLocation\$DevEnvironment"))
{
	New-Item "$RestoreUpdatesLocation\$DevEnvironment" -type directory
}


if([System.Convert]::ToBoolean($IsBackupEnabled))
{
	Remove-Item "$BackupLocation\$DevEnvironment\*.bak" -Force -Recurse
	foreach($dbName in $DbIncluded.split(';'))
	{
		$IsIncluded = $true
		foreach($exclude in $DbExcludedRegexForBackup.split(';'))
	{
			if($exclude -ne "" -And $dbName -Match $exclude)
			{
				$IsIncluded = $IsIncluded -And $false
			}
		}
		if(!$IsIncluded)
		{
			Write-Host "excluded $dbName"
			continue;
		}
		else
		{
			Write-Host "included $dbName"
		}
		
		$array = @("BackupDatabase.proj", "/t:BackupDatabase", "/p:VcsPath=$VcsPath", "/p:AssemblyVersion=$packageVersion", "/p:BackupLocation=$BackupLocation", "/p:DbPrefix=$DbPrefix", "/p:DevEnvironment=$DevEnvironment", "/p:DatabaseName=$dbName", "/p:PlatformTarget=x86", "/fl", "/flp:v=diag;logfile=BackupDatabase.log")
		& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" $array | Write-Host
		if (-not $?) {exit 1}
	}
}

if([System.Convert]::ToBoolean($IsRestoreUpdatesEnabled))
{
	$array = @("RestoreDatabase.proj", "/t:RestoreDatabases", "/p:VcsPath=$VcsPath", "/p:AssemblyVersion=$packageVersion", "/p:RestoreUpdatesLocation=$RestoreUpdatesLocation", "/p:DbPrefix=$DbPrefix", "/p:DevEnvironment=$DevEnvironment", "/p:PlatformTarget=x86", "/fl", "/flp:v=diag;logfile=RestoreDatabases.log")
	& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" $array | Write-Host
	if (-not $?) {exit 1}
}
