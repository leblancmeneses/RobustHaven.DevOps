Set-StrictMode -Version Latest

$packageLocation = pwd
$packageVersion = [System.IO.Path]::GetFileName($packageLocation)

Write-Host $packageLocation


foreach($dbName in $DbIncluded.split(';'))
{
	$IsIncluded = $true
	foreach($exclude in $DbExcludedRegexForMigration.split(';'))
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

	$array = @("VersionDatabase.proj", "/t:VersionDatabase", "/p:VcsPath=$VcsPath", "/p:AssemblyVersion=$packageVersion", "/p:DevEnvironment=$DevEnvironment", "/p:DbPrefix=$DbPrefix", "/p:DatabaseName=$dbName", "/p:PlatformTarget=x86", "/fl", "/flp:v=diag;logfile=VersionDatabases.log")
	& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" $array | Write-Host

	if (-not $?) {exit 1}
}