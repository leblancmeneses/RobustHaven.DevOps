#http://byteonmyside.wordpress.com/2012/07/08/using-enums-in-powershell/
Add-Type -TypeDefinition @"
   [System.Flags]
   public enum ProjectTypes
   {
      None = 0,
      Website = 1,
      WindowService = 2,
      DesktopApplication = 4,
      Library = 8,
      XCopy = 16
   }
   
   [System.Flags]
   public enum PackageTypes
   {
      None = 0,
      Staging = 1,
      Production = 2
   }
"@

function Debug-Hashtable()
{
	param([Hashtable]$table)
	$table.GetEnumerator() | Sort-Object Name | ForEach-Object {"{0}`t{1}" -f $_.Name,($_.Value -join ",")} | Write-Host
}

function GetSettingXmlValue() {
	param ([string]$settingFile, [string]$keyName)
	[xml]$settings = Get-Content $settingFile
	$node = (Select-Xml -Xml $settings -XPath ("//BuildSettings/add[@key='{0}']" -f $keyName)).Node
	return $node.value;
}

function WaitForFile() {
	param ([string]$file)
  
	$didWait = $false
	while(!(Test-Path $file)) {
		Write-Host "Waiting for $file"
		$didWait = $true
		Start-Sleep -s 10;
	}
	
	if( $didWait -eq $false)
	{
		Start-Sleep -s 10;
	}
}

function Touch-File()
{
	param ([string]$file)

    if($file -eq $null) {
        throw "No filename supplied"
    }

    if(Test-Path $file)
    {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    }
    else
    {
        echo $null > $file
    }
}

function New-PackageItem()
{
	param ([string]$SolutionName, [ProjectTypes]$ProjectType, [string]$SolutionFilePath, [string]$ConfigurationFileName, `
	[string]$BuildOutput, [string]$RootFolder, `
	$PackageXdts = @(),
	[string]$NuspecId, [string]$NuspecTitle, [string]$NuspecAuthors, [string]$NuspecOwners, [string]$NuspecLicenseUrl, [string]$NuspecProjectUrl, [string]$NuspecDescription, [string]$PackageConfiguration = "", `
	$OnPreInitScriptBlock = {}, $OnPackageScriptBlock = {},  $OnPushScriptBlock = {} )

	return  @{            
		SolutionName = $SolutionName
		ProjectType = $ProjectType
		SolutionFilePath = $SolutionFilePath
		ConfigurationFileName = $ConfigurationFileName
		BuildOutput = $BuildOutput
		RootFolder = $RootFolder
		PackageXdts = $PackageXdts
		NuspecId = $NuspecId
		NuspecTitle = $NuspecTitle
		NuspecAuthors = $NuspecAuthors
		NuspecOwners = $NuspecOwners
		NuspecLicenseUrl = $NuspecLicenseUrl
		NuspecProjectUrl = $NuspecProjectUrl
		NuspecDescription = $NuspecDescription 
		PackageConfiguration = $PackageConfiguration
		OnPreInitScriptBlock = $OnPreInitScriptBlock
		OnPackageScriptBlock = $OnPackageScriptBlock
		OnPushScriptBlock = $OnPushScriptBlock
	}  
}


function New-StagingEnvironment()
{
	param ([string]$EnvironmentName, [PackageTypes]$PackageType )

	return  @{            
		EnvironmentName       = ($EnvironmentName.ToUpper())              
		PackageType           = $PackageType         
	}  
}



function New-Database()
{
	param ([string]$DatabaseName, [string]$PrefixedName)

	return  @{            
		DatabaseName       = $DatabaseName              
		PrefixedName       = $PrefixedName         
	}  
}

function Generate-Assembly-Info
{
	param(
	[string]$clsCompliant = "true",
	[string]$company,
	[string]$product,
	[string]$copyright,
	[string]$trademark,
	[string]$version,
	[string]$file = $(throw "file is a required parameter.")
	)

  $asmInfo = "using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: CLSCompliantAttribute($clsCompliant )]
[assembly: ComVisibleAttribute(false)]
[assembly: AssemblyDelaySignAttribute(false)]

[assembly: AssemblyCompanyAttribute(""$company"")]
[assembly: AssemblyCopyrightAttribute(""$copyright"")]
[assembly: AssemblyTrademark(""$trademark"")]
[assembly: AssemblyConfiguration("""")]

//      Major Version
//      Minor Version 
//      Build Number
//      Revision
[assembly: AssemblyInformationalVersionAttribute(""$version"")]
[assembly: AssemblyVersionAttribute(""$version"")]
[assembly: AssemblyFileVersionAttribute(""$version"")]
"

	$dir = [System.IO.Path]::GetDirectoryName($file)
	if ([System.IO.Directory]::Exists($dir) -eq $false)
	{
		Write-Host "Creating directory $dir"
		[System.IO.Directory]::CreateDirectory($dir)
	}
	Write-Host "Generate-Assembly-Info: $file"
	Write-Output $asmInfo > $file
}


function Generate-Nuspec
{
	param(
	[string]$NuspecId,
	[string]$NuspecTitle,
	[string]$NuspecAuthors,
	[string]$NuspecOwners,
	[string]$NuspecLicenseUrl,
	[string]$NuspecProjectUrl,
	[string]$NuspecDescription,
	[string]$AssemblyVersion,
	[string]$PackageConfig = "",
	[string]$file = $(throw "file is a required parameter.")
	)
	
	$nl = [Environment]::NewLine
	$asmInfo = "<?xml version='1.0'?>
<package xmlns='http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'>
	<metadata>
		<id>$NuspecId</id>
		<title>$NuspecTitle</title>
		<version>$AssemblyVersion</version>
		<authors>$NuspecAuthors</authors>
		<owners>$NuspecOwners</owners>
		<licenseUrl>$NuspecLicenseUrl</licenseUrl>
		<projectUrl>$NuspecProjectUrl</projectUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<description>$NuspecDescription</description>$nl"
		
	if($PackageConfig -ne ""){
		$asmInfo +="	<dependencies>$nl		<group>$nl"
		[xml]$dependencies = Get-Content $PackageConfig
	
		foreach($dependency in $dependencies.packages.package)
		{
			if ($dependency -ne $null) {
				$asmInfo += '			<dependency id="'+ $dependency.id +'" version="'+ $dependency.version +'" />' + $nl
			}
		}
		
		
		$tmp = [System.IO.Directory]::GetParent($PackageConfig).FullName
		$tmp = [System.IO.Path]::Combine($tmp, "packages-additional.config") 
		Write-Host "looking for: $tmp " 
		if( Test-Path $tmp )
		{
			[xml]$dependencies = Get-Content $tmp
			
			foreach($dependency in $dependencies.packages.package)
			{
				if ($dependency -ne $null) {
					if( $dependency.GetAttribute("version") -eq '' )
					{
						$asmInfo += '			<dependency id="'+ $dependency.id +'" version="'+ $AssemblyVersion +'" />' + $nl
					}
					else
					{
						$asmInfo += '			<dependency id="'+ $dependency.id +'" version="'+ $dependency.version+'" />' + $nl
					}				
				}
			}
		}
		
		$asmInfo +="		</group>$nl	</dependencies>$nl"
	}
	
	
	
	$asmInfo += "
	</metadata>
	<files>
		<file src='**\*.*' />
	</files>$nl"
	$asmInfo += "</package>$nl"

	
	
	
	$dir = [System.IO.Path]::GetDirectoryName($file)
	if ([System.IO.Directory]::Exists($dir) -eq $false)
	{
		Write-Host "Creating directory $dir"
		[System.IO.Directory]::CreateDirectory($dir)
	}
	Write-Host "Generate-Nuspec: $file"
	Write-Output $asmInfo > $file
}


function Generate-EmptyXmlConfiguration
{
	param(
		[string]$file = $(throw "file is a required parameter.")
	)

  $asmInfo = "<?xml version='1.0'?>
<configuration>
</configuration>
"

	$dir = [System.IO.Path]::GetDirectoryName($file)
	if ([System.IO.Directory]::Exists($dir) -eq $false)
	{
		Write-Host "Creating directory $dir"
		[System.IO.Directory]::CreateDirectory($dir)
	}
	Write-Host "Generate-EmptyXmlConfiguration: $file"
	Write-Output $asmInfo > $file
}




function Generate-Config
{
	param(
		[string]$XDTTask,
		[string]$FlexibleConfigTask,
		[string]$EnvironmentMetaBase,
		[string]$BuildFolder,
		[string]$RootFolder,
		[string]$TemporaryFolder,
		[string]$SolutionName,
		[string]$NuspecId,
		[string]$DevProduct,
		[string]$DevBranch,
		[string]$DevEnvironment,
		[string]$DevTask,
		[string]$DevId,
		[string]$IsInTeamBuild,
		[string]$AssemblyVersion,
		[string]$SourceFile,
		[string]$DestinationFile,
		[string]$PackageConfigurationFileName,
		$PackageXdts = @()
	)
	
	exec {
		msbuild $FlexibleConfigTask "/t:DoTask" `
			("/p:BuildDirectory={0}" -f $BuildFolder) `
			("/p:RootDirectory={0}" -f $RootFolder) `
			("/p:TemporaryDirectory={0}" -f $TemporaryFolder) `
			("/p:SolutionName={0}" -f $SolutionName) `
			("/p:NuspecId={0}" -f $NuspecId) `
			("/p:DevProduct={0}" -f $DevProduct) `
			("/p:DevBranch={0}" -f $DevBranch) `
			("/p:DevEnvironment={0}" -f $DevEnvironment) `
			("/p:DevTask={0}" -f $DevTask) `
			("/p:DevId={0}" -f $DevId) `
			("/p:IsInTeamBuild={0}" -f $IsInTeamBuild) `
			("/p:AssemblyVersion={0}" -f $AssemblyVersion) `
			("/p:SourceFile={0}" -f $SourceFile) `
			("/p:DestinationFile={0}" -f $DestinationFile) 
	}


	foreach($xdtFile in $PackageXdts)
	{	
		$transformFile =  $BuildFolder + '\Configuration\xdt\' + $xdtFile
		$flexibleTransformFile = $TemporaryFolder + '\xdt.tmp'
		
		exec {
			msbuild $FlexibleConfigTask "/t:DoTask" `
				("/p:BuildDirectory={0}" -f $BuildFolder) `
				("/p:RootDirectory={0}" -f $RootFolder) `
				("/p:TemporaryDirectory={0}" -f $TemporaryFolder) `
				("/p:SolutionName={0}" -f $SolutionName) `
				("/p:NuspecId={0}" -f $NuspecId) `
				("/p:DevProduct={0}" -f $DevProduct) `
				("/p:DevBranch={0}" -f $DevBranch) `
				("/p:DevEnvironment={0}" -f $DevEnvironment) `
				("/p:DevTask={0}" -f $DevTask) `
				("/p:DevId={0}" -f $DevId) `
				("/p:IsInTeamBuild={0}" -f $IsInTeamBuild) `
				("/p:AssemblyVersion={0}" -f $AssemblyVersion) `
				("/p:SourceFile={0}" -f $transformFile) `
				("/p:DestinationFile={0}" -f $flexibleTransformFile) 
		}

		exec {
			msbuild $XDTTask "/t:DoTask" `
				("/p:TemporaryDirectory={0}" -f $TemporaryFolder) `
				("/p:SourceFile={0}" -f $DestinationFile) `
				("/p:TransformFile={0}" -f $flexibleTransformFile)
		}
	}
	
	
	# merge environment xdt (should only be used for private settings: production/dr
	$environmentXdt = $EnvironmentMetaBase + '\Configuration\' + $DevEnvironment + '-' + $SolutionName + '.' + $PackageConfigurationFileName + '.xdt'
	if( Test-Path $environmentXdt )
	{
		exec {
			msbuild $XDTTask "/t:DoTask" `
				("/p:TemporaryDirectory={0}" -f $TemporaryFolder) `
				("/p:SourceFile={0}" -f $DestinationFile) `
				("/p:TransformFile={0}" -f $environmentXdt) 
		}
	}
	else
	{
		Write-Host "$environmentXdt does not exist"
	}
}


Export-ModuleMember -function * -alias *