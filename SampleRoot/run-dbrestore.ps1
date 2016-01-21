$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())	 
if ($myWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
{
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
}
else
{
   Start-Process powershell -ArgumentList $myInvocation.MyCommand.Definition -Verb runAs
   exit
}
	
$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
& "$ScriptPath\_RobustHaven.DevOps\tools\psake.4.2.0.1\tools\psake.ps1" -buildFile "$ScriptPath\_RobustHaven.DevOps\Build.ps1" -taskList RunAfterUpdate -properties @{ IsDbRestoreEnabled=$true }

Read-Host 'Press [enter] to continue'