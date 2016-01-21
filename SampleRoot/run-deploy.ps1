$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())	 
if ($myWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
{
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
}
else
{
	#x86 for silverlight
   Start-Process "$env:windir\syswow64\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $myInvocation.MyCommand.Definition -Verb runAs
   exit
}

$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
$ScriptPath = join-path $ScriptPath  "./_RobustHaven.DevOps"

& "$ScriptPath\tools\psake.4.2.0.1\tools\psake.ps1" -buildFile "$ScriptPath\Build.ps1" -taskList default -properties @{ IsInTeamBuild=$true; DevEnvironment='production'; build_number=92; build_vcs_number=254; RunInternalPackageDistribution=$true }
if($psake.build_success -eq $false){exit 1} else {exit 0}