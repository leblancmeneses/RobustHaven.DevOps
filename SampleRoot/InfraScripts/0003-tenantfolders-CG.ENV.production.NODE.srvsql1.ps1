if (!(Get-PSSnapin -Name SQLServerCmdletSnapin100 -ErrorAction SilentlyContinue)) 
{
   Add-PSSnapin SQLServerCmdletSnapin100
}
if (!(Get-PSSnapin -Name SqlServerProviderSnapin100 -ErrorAction SilentlyContinue)) 
{
   Add-PSSnapin SqlServerProviderSnapin100
}

$computer = gc env:computername
Set-Location SQLSERVER:\SQL\$computer\DEFAULT\Databases\Avstx

$vars = @("TenantName='cg.listenstofans.com'");
$d = Invoke-Sqlcmd -SuppressProviderContextWarning -Variable $vars -Query "SELECT tdg.[Id],td.[Domain] FROM [TenantDataGroup] as tdg INNER JOIN TenantDomain as td ON td.TenantDataGroup_Id = tdg.Id WHERE Name = `$(TenantName)"
foreach($x in $d)
{
	$Id = $x[0]
	$Domain = $x[1]
	
	if(!(Test-Path "C:\central-storage-ir\TenantDataGroup_Id\$Id"))
	{
		Write-Host Creating $Id
		New-Item "C:\central-storage-ir\TenantDataGroup_Id\$Id" -type directory
	}
	
	Write-Host Creating $Domain
	cmd /c mklink /D "C:\central-storage-ir\Tenants\$Domain" "\\SRVSQL1\central-storage-ir\TenantDataGroup_Id\$Id"
}