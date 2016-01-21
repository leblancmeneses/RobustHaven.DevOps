Set-StrictMode -Version Latest

$location = pwd
Write-Host $location


$items = ("..\Externs\repos\team_surveymodule\HostApp\Tenants", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants"),
		 ("..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\bakerbrosdeli.listenstofans.com", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\bakerbrosdeli.improvingrestaurants.com"),
		 ("..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\survey.cristinasmex.com", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\cristinasmex.improvingrestaurants.com"),
		 ("..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\survey.genghisgrill.com", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\gg.improvingrestaurants.com"),
		 ("..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\papajohns.listenstofans.com", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\papajohns.improvingrestaurants.com"),
		 ("..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\littlecaesars.listenstofans.com", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\littlecaesars.improvingrestaurants.com"),
		 ("..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\survey.peppersmash.com", "..\DataCenter.Www\AVSTX.POS.WebMvc\Tenants\peppersmash.improvingrestaurants.com")

		 
FOR ($i=0;$i -lt $items.length; $i++) {
	$f1 = "$location\" + $items[$i][0]
	$f2 = "$location\" + $items[$i][1] 

	if(!(Test-Path $f1))
	{
		Write-Host $f1 => $f2
		cmd /c mklink /D "$f1"  "$f2"
	}
}


