Set-StrictMode -Version Latest

$packageLocation = pwd
$packageVersion = [System.IO.Path]::GetFileName($packageLocation)

Write-Host $packageLocation

$array = @("VersionInfra.proj", "/t:VersionInfra", "/p:VcsPath=$VcsPath", "/p:AssemblyVersion=$packageVersion", "/p:DevEnvironment=$DevEnvironment", "/p:TagName=$TagName", "/p:DbName=$DbName", "/p:DbInstance=$DbInstance", "/p:PlatformTarget=x86", "/fl", "/flp:v=diag;logfile=VersionInfra.log")
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" $array | Write-Host

if (-not $?) {exit 1}
