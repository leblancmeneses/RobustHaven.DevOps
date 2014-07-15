Set-StrictMode -Version Latest

if( Test-Path "_DeployFailed.ps1" )
{
    $extensionFile = Resolve-Path "_DeployFailed.ps1"
	& $extensionFile
	Remove-Item $extensionFile -ErrorAction SilentlyContinue 
}

if([System.Convert]::ToBoolean($RobustHavenIsDeployFailedMailEnabled))
{
Write-Host "Sending Email"

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", 587)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential("integration0001@gmail.com", "DB2A426C-76FA-49E9-8869-E6F37F6B54B6");


#Creating a Mail object
$msg = new-object Net.Mail.MailMessage
#$msg.IsBodyHtml = $FALSE
$msg.From = "integration0001@gmail.com"
$msg.ReplyTo = "integration0001@gmail.com"
$msg.To.Add("leblanc@robusthaven.com")
$msg.subject = "Deployment Failed"

$projectName = [regex]::Replace($OctopusProjectName, "[^a-zA-Z0-9]", '')

if(Test-Path variable:global:OctopusForcePackageRedeployment)
{
	$IsForcePackageRedeployment = $OctopusForcePackageRedeployment
}
else
{
	$IsForcePackageRedeployment = $false
}

$msg.body = @"

[OctopusEnvironmentName] = '$OctopusEnvironmentName'
[OctopusMachineName] = '$OctopusMachineName'
[OctopusReleaseNumber] = '$OctopusReleaseNumber'
[OctopusPackageName] = '$OctopusPackageName'
[OctopusPackageVersion] = '$OctopusPackageVersion'
[OctopusPackageNameAndVersion] = '$OctopusPackageNameAndVersion'
[OctopusProjectName] = '$OctopusProjectName'
[OctopusTaskId] = '$OctopusTaskId'
[OctopusForcePackageRedeployment] = '$IsForcePackageRedeployment'


$RobustHavenOctopusUriLeftPart/projects/$projectName/releases/

"@

#Sending email
$smtp.Send($msg)
}
