param($installPath, $toolsPath, $package, $project)

$projectFile = new-object -typename System.IO.FileInfo -ArgumentList $project.FullName
$projectDirectory = $projectFile.DirectoryName

function getPackageContentConfig($configFilePath = "packages.content.config")
{	
	$configFilePath = Join-Path -path $projectDirectory -childPath $configFilePath
	
	Write-Debug "Reading config file: $configFilePath"
	
	$configFile = New-Object XML
	$configFile.Load($configFilePath);
	return $configFile
}

function getContentsToRemoved([xml] $configFile)
{
	foreach ($pkg in $configFile.Packages.Package) 
	{
		if($pkg.Id -eq $package.Id)
		{
			if($pkg.Action -eq "remove") {
				Write-Debug "Some contents needs to be deleted from this package installation."
				return $configFile.Packages.Package.Content;
			}
		}
	}
	return $false;
}

function removeItemFromProject($projectItemName)
{
	Write-Host "Removing $projectItemName ..."
	$project.ProjectItems.Item($projectItemName).remove()
	Remove-Item -Path $(Join-Path -Path $projectDirectory -ChildPath $projectItemName) -Force -Recurse
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

# set the test page's custom tool to the razor generator
$testPage = $project.ProjectItems.Item("SampleTemplate.cshtml")
$testPage.Properties.Item("CustomTool").Value = "RazorGenerator"

$configFile = getPackageContentConfig
$contentsToBeRemoved = getContentsToRemoved($configFile)

if($contentsToBeRemoved -ne $false) {
	removeContents($contentsToBeRemoved)
}	
