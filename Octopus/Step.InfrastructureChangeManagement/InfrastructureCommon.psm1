Import-Module WebAdministration 



function Add-HttpBinding
{
    param ([string]$WebSiteName, 
           [string]$WebSiteAddress="",       # Optional parameter. Default value empty string means all addersses
           [string]$WebSiteIP="*",           # Optional parameter. Default value: * meaning all IP addresses
           [int]$WebSitePort="80")           # Optional parameter. Default value: 80

    Write-Debug "Entering: Add-HttpBinding"
    Add-Binding -WebSiteName $WebSiteName -WebSiteAddress $WebSiteAddress -WebSiteIP $WebSiteIP -WebsitePort $WebSitePort -BindingProtocol "http"
    Write-Debug "Leaving: Add-HttpBinding"
}


function Add-HttpsBinding
{
    param ([string]$WebSiteName, 
           [string]$CertificateSubject,
           [string]$WebSiteAddress="",        # Optional parameter. Default value empty string means all addersses
           [string]$WebSiteIP="*",            # Optional parameter. Default value: * meaning all IP addresses
           [int]$WebSitePort="443")           # Optional parameter. Default value: 443

    Write-Debug "Entering: Add-HttpsBinding"
    Add-Binding -WebSiteName $WebSiteName -WebSiteAddress $WebSiteAddress -WebSiteIP $WebSiteIP -WebsitePort $WebSitePort -BindingProtocol "https"
    Assign-Certificate -IPAddress $WebSiteIP -Port $WebSitePort -CertificateSubject $CertificateSubject
    Write-Debug "Leaving: Add-HttpsBinding"
}


function Add-Binding
{
    param ([string]$WebSiteName, 
           [string]$WebSiteAddress="",
           [string]$BindingProtocol,
           [string]$WebSiteIP,
           [int]$WebSitePort)

    # if IP is specified check if it is vlaid IP in this server
    if ($WebSiteIP -ne "*")
    {
        # get all network addapters configuration
        $NetworkAdapterConfiguration = gwmi -query "Select IPAddress From Win32_NetworkAdapterConfiguration Where IPEnabled = True"
        $exists = $False
        
        # check each network addapter for IP addresses
        foreach ($NetworkAdapter in $NetworkAdapterConfiguration)
        {            
            $ExistsInCurrentAddpater=[bool]($NetworkAdapter.IPAddress | where-object {$_ -eq $WebSiteIP})
            if ($ExistsInCurrentAddpater) 
            {
                $exists = $True
            }
        }
        
        # if none of network addapters had this IP assigned, break fail the bindinging
        if (!$exists)
        {
            write-host "IP address $WebSiteIP is not valid for this server." -ForegroundColor Red
            write-host "Binding creation aborted1." -ForegroundColor Red
            break
        }
    }

    # check if port is valid
    if (($WebSitePort -lt 1) -or ($WebSitePort -gt 65535))
    {
        write-host "Port number $WebSitePort is out of range. Port value must be an integer between 1 and 65535." -ForegroundColor Red
        write-host "Binding creation aborted1." -ForegroundColor Red
        break
    }

    $WebSite = "IIS:\Sites\$WebSiteName"
    $bindingInformation = "$WebSiteIP"+":"+"$WebSitePort"+":"+"$WebSiteAddress"
    $NewBinding = @{protocol=$BindingProtocol;bindingInformation=$bindingInformation}
    
    # get web site bindings
    $bindings = Get-ItemProperty $WebSite -Name bindings

    # check if binding already exists
    $exists = [bool]($bindings.Collection | ? {$_.bindingInformation -eq $bindingInformation})
    
    # if binding doesn't exist, add it
    if (!$exists)
    {
        write-host "Adding " $NewBinding.bindingInformation " binding for protocol" $NewBinding.protocol "to website $WebSite" -ForegroundColor Green
        New-ItemProperty $WebSite -name bindings -value $NewBinding
    } else
    {
        write-host "Binding" $NewBinding.bindingInformation "for protocol" $NewBinding.protocol "already exists for website $WebSite" -ForegroundColor Gray
    }

}

function Assign-Certificate
{
    param ([string]$IPAddress, 
           [string]$Port,
           [string]$CertificateSubject)
    
    # get certificate thumbprint by its subject name
    $CertificateThumbprint = (Get-ChildItem cert:\LocalMachine\MY | where-object { $_.Subject -like "*$CertificateSubject*" } | Select-Object -First 1).Thumbprint
    
    # get full real subject name for messages
    $CertificateRealSubject = (Get-ChildItem cert:\LocalMachine\MY | where-object { $_.Thumbprint -eq $CertificateThumbprint } | Select-Object -First 1).Subject
    
    # if IP is specified check if it is vlaid IP in this server
    if ($IPAddress -eq "*")
    {
        $IPAddress = "0.0.0.0"
    }

    # switch to SslBinding namespace
    Push-Location IIS:\SslBindings
    
    # check if 0.0.0.0:Port is already assigned with certificate.
    $exists = [bool](get-item * | where-object {$_.Port -eq "443" -and $_.IPAddress -eq $IPAddress})
    
    # if certificate is not assigned
    if (!$exists)
    {
        write-host "Assigning certificate" $CertificateRealSubject "to" $IPAddress":"$Port  -ForegroundColor Green
        Get-Item cert:\LocalMachine\MY\$CertificateThumbprint | New-Item $IPAddress!$Port
    } else
    {
        write-host "Certificate is already assigned to" $IPAddress":"$Port  -ForegroundColor Gray
    }
    
    Pop-Location
}


Export-ModuleMember -function * -alias *
