param($installPath, $toolsPath, $package, $project,[switch] $debug)

# using debug switch to set the log level
if( $debug )
{
    $DebugPreference = "Continue"
}
else
{
    $DebugPreference = "SilentlyContinue"
}

## Global Flags
$DeleteFolderAllContentsAreSimilar = $true
##

$projectFile = new-object -typename System.IO.FileInfo -ArgumentList $project.FullName
$projectDirectory = $projectFile.DirectoryName

$defaultContentDirectory = Join-Path -path $installPath -childPath "content"


function getPackageContentConfig($configFilePath = "packages.contentpackageext.config")
{	
	$configFilePath = Join-Path -path $projectDirectory -childPath $configFilePath
	
    if(Test-Path -Path $configFilePath) 
    {
	    Write-Debug "Reading config file: $configFilePath"
	
	    $configFile = New-Object XML
	    $configFile.Load($configFilePath);
	    return $configFile
    }
}

function getContentsToRemoved([xml] $configFile)
{
    foreach ($pkg in $configFile.Packages.ChildNodes) 
	{
		if($pkg.Id -eq $package.Id)
		{
			if($pkg.Action -eq "remove") {
				Write-Debug "Some contents needs to be deleted from this package installation."                
				return $pkg.Content;
			}
		}
	}
	return $false;
}

# Deletes directory contents iff present in the source
function DeleteDirectoryProjectItem ($projectItem, $relativePathTillNow)
{
    if($relativePathTillNow -eq $null)
    {
        $relativePathTillNow = $projectItem.Name
    }
    else
    {
        $relativePathTillNow = "$relativePathTillNow\$($projectItem.Name)"
    }

    foreach($subItem in $projectItem.ProjectItems)
    {
        $subItemSourcePath = Join-Path -Path $defaultContentDirectory -ChildPath "$relativePathTillNow\$($subItem.Name)"

        if(Test-Path -Path $subItemSourcePath) 
        {
            if($subItem.ProjectItems -ne $null) 
            {
                DeleteDirectoryProjectItem $subItem $relativePathTillNow
            }
            else
            {
                $subItem.Delete()
            }
        }
    }

    $shouldDeleteProjectItem = $($DeleteFolderAllContentsAreSimilar -eq $true) -and $($projectItem.ProjectItems.Count -eq 0)

    if( $shouldDeleteProjectItem ) 
    {        
        $projectItem.Delete()
    }
}

function removeItemFromProject($projectItemName)
{
   
	Write-Debug "Removing $projectItemName ..."
    
    $projectItemPath = Join-Path -Path $projectDirectory -ChildPath $projectItemName
    
    if(Test-Path -Path $projectItemPath) 
    { 
	    $projectItem = $project.ProjectItems.Item($projectItemName)

        # if the project item is a directory/folder delete
        if( $projectItem.ProjectItems -ne $null )
        {
            DeleteDirectoryProjectItem $projectItem
        }
        else
        {
            $projectItem.Delete()
        }
    }
    else 
    {
        Write-Debug "$projectItemName {$projectItemPath} does not exist"
    }
}

function removeAll()
{
	$packageContentDir = Join-Path -path $installPath -childPath "content"
	$allFilesUnderContentDir = Get-ChildItem $packageContentDir
	foreach($filePath in $allFilesUnderContentDir) 
	{		
		removeItemFromProject $filePath.Name
	}
}

function removeSelected($contentsToBeRemoved) 
{
	foreach($content in $contentsToBeRemoved.split(";").trim()) 
	{
		removeItemFromProject $content
	}
}

function removeContents($contentsToBeRemoved) 
{
	switch ($contentsToBeRemoved)
	{
		$null { removeAll; break; }
		"*" { removeAll; break; }
		"" {removeAll; break; }
		default { removeSelected $contentsToBeRemoved }
	}
}

# For removing contents from contents folder
function removeDefaultContents()
{
    $configFile = getPackageContentConfig
    if($configFile -eq $null) 
    {
        Write-Host "WARN: packages.content.config file is missing; not running delete operation"
    }
    else
    {
        $contentsToBeRemoved = getContentsToRemoved($configFile)
    
        if($contentsToBeRemoved -ne $false) {
	        removeContents($contentsToBeRemoved)
        }
    }
}	

# For adding contents from tools folder

$tempContentDirectory = $(Join-Path -Path $toolsPath -ChildPath "temp-contents")

function isDirectory($path)
{
     (Get-Item $path) -is [System.IO.DirectoryInfo]
}

function isDirectoryEmpty($path) 
{
    (Get-ChildItem -Path $path) -eq $null
}

function Get-MD5Hash($filePath)
{
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath)))
    return $hash
}

function checkIfFileExists($toolsFile, $relativePath) {
    
    $projectFile = "$projectDirectory\$relativePath"

    if(Test-Path $projectFile) 
    {
        $projectFileMd5 = Get-MD5Hash $projectFile
        $toolsFileMd5 = Get-MD5Hash $toolsFile

        $md5matched = $toolsFileMd5 -eq $projectFileMd5
        if( !$md5matched ) {
            Write-Host "MD5 checksums do not match: {$toolsFile} compared to {$projectFile}"
        }
        return $true 
    }
    return $false
}

function prepareContentsToBeAdded($currentPath, $relativePathTillNow="") 
{
    
    foreach($item in (Get-ChildItem $currentPath))
    {   
        $itemRelativePath = "$relativePathTillNow\$($item.Name)"

        if(isDirectory $item.FullName)
        {            
            if(!$(isDirectoryEmpty $item.FullName)) 
            {
                prepareContentsToBeAdded $item.FullName $itemRelativePath            
            }
        }
        else
        {           
            $fileExists = checkIfFileExists $item.FullName $itemRelativePath 
            
            if( !$fileExists ) 
            {
                $tempPath = Join-Path -Path $tempContentDirectory -ChildPath $itemRelativePath
                
                New-Item -Path $tempPath -ItemType File -Force
                Copy-Item -Path $item.FullName -Destination $tempPath -Force          
            }            
        }
    }
}

function Get-ProjectItem($itemName, $parentItem)
{
    foreach($projectItem in $parentItem.ProjectItems) {
        if($projectItem.Name -eq $itemName) 
        {
            return $projectItem
        }
    }
    return $null
}

function AddDirectoryToProject ($path, $parentProject)
{
    $currentProjectItem = Get-ProjectItem $path.Name $parentProject
    
    if($currentProjectItem -eq $null) 
    {
        $parentProject.ProjectItems.AddFromDirectory($path.FullName)
    }
    else 
    {
        foreach($subItemPath in $(Get-ChildItem $path.FullName))
        {
            if(!$(isDirectory $subItemPath.FullName))
            {        
                $subProjectItem = $(Get-ProjectItem $subItemPath.Name $currentProjectItem)     
                
                if( $subProjectItem -eq $null )
                {
                    $currentProjectItem.ProjectItems.AddFromFileCopy($subItemPath.FullName)    
                }
                else 
                {
                    Write-debug "$($subItemPath.Name) already exists."
                }
            }
            else 
            {
                AddDirectoryToProject $subItemPath $currentProjectItem                    
            }  
        }
    }
}

function addToolsContents() 
{
    $toolsContentPath = Join-Path -Path $toolsPath -ChildPath "content"

    if( $(Test-Path -Path $toolsContentPath) )
    {
        PrepareContentsToBeAdded $toolsContentPath

        if(Test-Path -Path $tempContentDirectory) 
        {
            foreach($path in (Get-ChildItem $tempContentDirectory))
            {
                if(!$(isDirectory $path.FullName))
                {
                    $project.ProjectItems.AddFromFileCopy($path.FullName)
                }
                else 
                {
                    AddDirectoryToProject $path $project                    
                }
            }
            Remove-Item -Path $tempContentDirectory -Force -Recurse 
        }
    }
}

Export-ModuleMember removeDefaultContents, addToolsContents