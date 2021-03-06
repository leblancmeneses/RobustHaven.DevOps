Set-StrictMode -Version Latest

Import-Module .\OctopusDeployment.psm1
 
$packageLocation = pwd

function Copy-CsvList ([string]$CsvFile = "CopyList.csv") 
{
    if (!(Test-Path $CsvFile))
    {
        Write-Host "Csv file $CsvFile is not found." -ForegroundColor Red
        Write-Host "Copying aborted." -ForegroundColor Red
        break
    }

    $header = "From", "To"
    $test = Import-Csv -Delimiter ";" -Header $header $CsvFile
    foreach ($line in $test)
    {
        Write-Host "Copy from:" $line.From
        Write-Host "Copy to  :" $line.To
        
        if (($line.From -eq "") -or ($line.To -eq ""))
        {
            Write-Host "Skipping because source or destination path is not specified." -ForegroundColor Gray
        }

        if (!(Test-Path $line.From))
        {
            Write-Host "Skipping because source path does not exist" -ForegroundColor Gray
        } else 
        {
        
            Copy-Item $line.From -Destination $line.To -Force -Recurse
            Write-Host "Copied." -ForegroundColor Green
        }
    }
}

$CsvFile = "CopyList.csv"

Copy-CsvList #$CsvFile

Purge-PastDeployment $packageLocation