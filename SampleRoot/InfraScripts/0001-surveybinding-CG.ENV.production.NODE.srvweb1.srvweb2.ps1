Set-StrictMode -Version Latest

Import-Module ..\InfrastructureCommon.psm1

$WebSiteName = "SurveyWebsite"
$WebSiteAddress = "cg.listenstofans.com"
$WebSiteIP = "*"
$WebSitePort = 80
Add-HttpBinding -WebSiteName $WebSiteName -WebSiteAddress $WebSiteAddress -WebSiteIP $WebSiteIP -WebsitePort $WebSitePort

