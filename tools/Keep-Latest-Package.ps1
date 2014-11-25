param([string]$packagesDirectory, [int]$maxPackagesToRetain, [Switch]$debug)

#cd "F:\git-rh\RobustHaven.DevOps\tools"
#.\Keep-Latest-Package.ps1 "C:\inetpub\wwwroot\deployfeed-qspweb\Packages" 2 -debug

if($debug)
{
    $DebugPreference = "Continue"
}
else
{
    $DebugPreference = "SilentlyContinue"
}

Write-Debug "Working Directory: $packagesDirectory"
Write-Debug "Max Packages to Retain: $maxPackagesToRetain"

function Get-PackageName($packageFileName)
{
    return $($packageFileName -replace "\d+\.\d+\.\d+\.\d+\.nupkg")
}

Write-Debug "Categorise packages by Name"
function Categorise-Packages($packages)
{
    $categorisedPackages = @{}
       
    foreach($package in $packages)
    {
        $packageName = Get-PackageName $package.Name

        if( !$categorisedPackages.ContainsKey($packageName) )
        { 
            $packageList = Get-ChildItem $packagesDirectory -Filter "*$packageName*"
            $categorisedPackages.Add($packageName, $packageList)
        }
    }

    return $categorisedPackages
}

# Sort-Object -Property CreationTime | Select-Object -Last maxCount
function Delete-UnwantedPackages($packageTable, $maxCount) 
{
    foreach ($packageName in $packageTable.keys)
    {
        $count = 1
        $sortedPackages = $packageTable.Item($packageName) | Sort-Object -Property CreationTime -Descending
        Write-Debug "---------------------------"
        Write-Debug "Package Name: $packageName"
        Write-Debug "Packages : $sortedPackages"
        Write-Debug "Package Count: $($sortedPackages.Count)"
        foreach($packageFile in $sortedPackages)
        {
            if($count -gt $maxCount) 
            {
                Write-Debug "$count : Deleting $packageFile | $($packageFile.CreationTime)"
                Remove-Item -Path $(Join-Path -path $packagesDirectory $packageFile) -Force
            }
            else
            {
                Write-Debug "$count : Keeping $PackageFile | $($packageFile.CreationTime)"
            }
            $count++
        }
        Write-Debug "---------------------------"
    }
}

$allPackages = Get-ChildItem $packagesDirectory -Filter "*.nupkg"
Write-Debug "All Packages Count: $($allPackages.Count)"

$categorisedPackages = $(Categorise-Packages $allPackages)
Write-Debug "Categorised Packages:"
$categorisedPackages

Delete-UnwantedPackages $categorisedPackages $maxPackagesToRetain