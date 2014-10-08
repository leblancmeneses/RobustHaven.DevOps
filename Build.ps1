properties {
	$IsTestingEnabled = $false
	$IsObfuscateEnabled = $true
	$IsInTeamBuild = $false
	$IsDbRestoreEnabled = $false
	
	$VariablePrefix = "Cms"
	$DevProduct = 'Cms'
	$DevEnvironment = 'LOCAL'
	$CompanyName = 'Robust Haven Inc'
	
	$RunInternalPackageDistribution = $false

  	$build_number = if ("$env:BUILD_NUMBER".length -gt 0) { "$env:BUILD_NUMBER" } else { "0" }
	$build_vcs_number = if ("$env:BUILD_VCS_NUMBER".length -gt 0) { "$env:BUILD_VCS_NUMBER" } else { "0" }

	$compileMessage = 'Executed Compile!'
	$cleanMessage = 'Executed Clean!'
}

. .\BuildExt.ps1
Include "..\build\_init.ps1"


Framework "4.0x86"
# Framework "4.0x64"

TaskSetup {
  #"Executing task setup"
}

TaskTearDown {
  #"Executing task tear down"
}

formatTaskName {
	param($taskName)
	write-host $taskName -foregroundcolor Green
}

task default -depends Deploy

task Clean -depends IdentifyBuildVariables { 
	remove-item -force -recurse $script:TemporaryFolder -ErrorAction SilentlyContinue 
	remove-item -force -recurse $script:DeployFolder -ErrorAction SilentlyContinue 
	
    new-item $script:TemporaryFolder -itemType directory  
	if($IsInTeamBuild -eq $true)
	{
		new-item $script:DeployFolder -itemType directory
	}	
}

task Init -depends Clean, IdentifyBuildVariables {
	foreach ($package in $script:PackageItems)
	{
		& $package.OnPreInitScriptBlock
		
		if(($package.ProjectType -eq [ProjectTypes]::XCopy) -or ($package.ProjectType -eq [ProjectTypes]::Library) -or ($package.ProjectType -eq [ProjectTypes]::None)) {  
			continue;
		}
		
		$configFilePathInProject = $package.RootFolder + '\' + $package.ConfigurationFileName
		Generate-EmptyXmlConfiguration -file $configFilePathInProject
		if($IsInTeamBuild -eq $false)
		{
			# create project config from baseline
			$sourceConfigName = $script:BuildFolder + '\Configuration\' +  $package.SolutionName + '.' + $package.ConfigurationFileName
			
			Generate-Config -XDTTask $script:XDTTask `
				-FlexibleConfigTask $script:FlexibleConfigTask `
				-EnvironmentMetaBase $script:EnvironmentMetaBase `
				-BuildFolder $script:BuildFolder `
				-RootFolder $package.RootFolder `
				-TemporaryFolder $script:TemporaryFolder `
				-SolutionName $package.SolutionName `
				-NuspecId $package.NuspecId `
				-DevProduct $DevProduct `
				-DevBranch $script:DevBranch `
				-DevEnvironment $script:DevEnvironment `
				-DevTask $script:DevTask `
				-DevId $script:DevId `
				-IsInTeamBuild $IsInTeamBuild `
				-AssemblyVersion $script:AssemblyVersion `
				-SourceFile $sourceConfigName `
				-DestinationFile $configFilePathInProject `
				-PackageConfigurationFileName $package.ConfigurationFileName `
				-PackageXdts $package.PackageXdts 
		}
	}
}


task Compile -depends Init { 
	$SolutionPathCache = @()
	foreach ($package in $script:PackageItems)
	{
		if( !(Test-Path $package.BuildOutput) )
		{
			new-item $package.BuildOutput -itemType directory
		}
		
		if($package.ProjectType -eq [ProjectTypes]::XCopy) {  
			cp -rec ($package.RootFolder + '\*') $package.BuildOutput
		}
		
		if($package.ProjectType -eq [ProjectTypes]::Website) {  
			Write-Host "Packaging Website " + $package.SolutionName
			$BuildOutput = $package.BuildOutput
			$SolutionPath = $package.SolutionFilePath
			if($SolutionPathCache -notcontains $SolutionPath){
				exec {
					msbuild $SolutionPath "/t:Clean;Rebuild" "/p:_PackageTempDir=$BuildOutput" `
						"/p:Configuration=Release" "/p:DeployOnBuild=true" `
						"/p:DeployTarget=PipelinePreDeployCopyAllFilesToOneFolder" `
						"/p:AutoParameterizationWebConfigConnectionStrings=false" `
						"/fl" "/flp:v=quiet"
				}
			}
				
			Remove-Item "$BuildOutput\*" -include .pdb -recurse
		}
		
		if($package.ProjectType -eq [ProjectTypes]::Library) {  
			Write-Host "Packaging Library " + $package.SolutionName
			$BuildOutput = $package.BuildOutput
			$SolutionPath = $package.SolutionFilePath
			if($SolutionPathCache -notcontains $SolutionPath){
				exec {
					msbuild $SolutionPath "/t:Clean;Rebuild" "/p:Configuration=Release"  `
						"/fl" "/flp:v=quiet"
				}
			}
				
			cp -rec ($package.RootFolder + '\bin\Release\*') $package.BuildOutput
			Remove-Item "$BuildOutput\*" -include .pdb -recurse
		}
		
		if($package.ProjectType -eq [ProjectTypes]::DesktopApplication) {  
			Write-Host "Packaging DesktopApplication " + $package.SolutionName
			$BuildOutput = $package.BuildOutput
			$SolutionPath = $package.SolutionFilePath
			if($SolutionPathCache -notcontains $SolutionPath){
				exec {
					msbuild $SolutionPath "/t:Clean;Rebuild" "/p:Configuration=Release"  `
						"/fl" "/flp:v=quiet"
				}
			}
				
			cp -rec ($package.RootFolder + '\bin\Release\*') $package.BuildOutput
			Remove-Item "$BuildOutput\*" -include .pdb -recurse
		}
		
		if($package.ProjectType -eq [ProjectTypes]::WindowService) {  
			Write-Host "Packaging WindowService " + $package.SolutionName
			$BuildOutput = $package.BuildOutput
			$ReleaseFolder = $package.RootFolder + '\bin\Release'
			$SolutionPath = $package.SolutionFilePath
			if($SolutionPathCache -notcontains $SolutionPath){
				exec {
					msbuild $SolutionPath "/t:Clean;Rebuild" "/p:Configuration=Release" `
						"/fl" "/flp:v=quiet"
				}
			}
			Remove-Item "$ReleaseFolder\*" -include .pdb -recurse
			
			if( Test-Path "$ReleaseFolder\_PublishedWebsites" )
			{
				Remove-Item "$ReleaseFolder\_PublishedWebsites" -recurse
			}
			
			cp -rec ($ReleaseFolder + '\*') $package.BuildOutput
		}
	
	
		if(($package.ProjectType -eq [ProjectTypes]::XCopy) -or ($package.ProjectType -eq [ProjectTypes]::Library) -or ($package.ProjectType -eq [ProjectTypes]::None)) {  
			continue;
		}
		
		
		#wait till artifacts are created in Deploy folder
		if($IsInTeamBuild -eq $true)
		{
			# create specific devenvironment destination config from baseline; compile once and promote to any supported env
			foreach ($stagingEnvironment in $script:StagingEnvironments)
			{
				$destinationConfigName = $package.BuildOutput + '\' +	$stagingEnvironment.EnvironmentName + '-' + $package.ConfigurationFileName
				$sourceConfigName = $script:BuildFolder + '\Configuration\' +  $package.SolutionName + '.' + $package.ConfigurationFileName
	
				Generate-Config -XDTTask $script:XDTTask `
					-FlexibleConfigTask $script:FlexibleConfigTask `
					-EnvironmentMetaBase $script:EnvironmentMetaBase `
					-BuildFolder $script:BuildFolder `
					-RootFolder $package.RootFolder `
					-TemporaryFolder $script:TemporaryFolder `
					-SolutionName $package.SolutionName `
					-NuspecId $package.NuspecId `
					-DevProduct $DevProduct `
					-DevBranch $script:DevBranch `
					-DevEnvironment $stagingEnvironment.EnvironmentName `
					-DevTask $script:DevTask `
					-DevId 'BuildAgent' `
					-IsInTeamBuild $IsInTeamBuild `
					-AssemblyVersion $script:AssemblyVersion `
					-SourceFile $sourceConfigName `
					-DestinationFile $destinationConfigName `
					-PackageConfigurationFileName $package.ConfigurationFileName `
					-PackageXdts $package.PackageXdts 
			}
		}
		
		$SolutionPathCache += $package.SolutionFilePath
	}
}
	

task Test -depends Compile { 
	if($script:IsTestingEnabled -eq $true)
	{
	
	}
}

task Package -depends Compile, Test { 
	foreach ($package in $script:PackageItems)
	{
		$nuspecFileNameExpected = $package.BuildOutput + '\' + $package.NuspecId + '.nuspec'
		if( !(Test-Path $nuspecFileNameExpected) )
		{
			Generate-Nuspec -NuspecId $package.NuspecId `
				-NuspecTitle $package.NuspecTitle `
				-NuspecAuthors $package.NuspecAuthors `
				-NuspecOwners $package.NuspecOwners `
				-NuspecLicenseUrl $package.NuspecLicenseUrl `
				-NuspecProjectUrl $package.NuspecProjectUrl `
				-NuspecDescription $package.NuspecDescription `
				-AssemblyVersion $script:AssemblyVersion `
				-PackageConfig $package.PackageConfiguration `
				-file $nuspecFileNameExpected
		}
		
		
		& $package.OnPackageScriptBlock

		if(($package.ProjectType -ne [ProjectTypes]::XCopy) -and ($package.ProjectType -ne [ProjectTypes]::Library) -and ($package.ProjectType -ne [ProjectTypes]::None)) {  
			cp ($script:DevOpsFolder + '\Octopus\OctopusDeployment.psm1') $package.BuildOutput 
			cp ($script:DevOpsFolder + '\Octopus\DeployFailed.ps1') $package.BuildOutput 
		}

		if($package.ProjectType -eq [ProjectTypes]::Website) {
			cp ($script:DevOpsFolder + '\Octopus\Step.Www\*.*') $package.BuildOutput 
		}
		if($package.ProjectType -eq [ProjectTypes]::WindowService) {
			cp ($script:DevOpsFolder + '\Octopus\Step.WindowService\*.*') $package.BuildOutput 
		}
			
		$args = @('pack', ('"{0}"' -f $nuspecFileNameExpected), '-OutputDirectory',  ('"{0}"' -f $script:DeployFolder), '-Version', ('"{0}"' -f $script:AssemblyVersion),  '-NoPackageAnalysis')
		& "$script:NugetTask" $args | Write-Host
		if (-not $?) {
			throw "Error: Failed to execute NugetTask pack command"
		}
	}
}

task Push -depends Package { 
	foreach ($package in $script:PackageItems)
	{
		& $package.OnPushScriptBlock
	}
	
	$fileName = ("{0}\{1}.{2}.nupkg" -f $script:DeployFolder, $package.NuspecId, $script:AssemblyVersion)
	WaitForFile($fileName)
	
	$args = @('push', ('"{0}"' -f $fileName), '-s', ('"{0}"' -f $script:NugetDeployUrl), ('"{0}"' -f $script:NugetDeployApiKey) )
	& "$script:NugetTask" $args | Write-Host
	if (-not $?) {
		throw "Error: Failed to push packages"
	}
}

task Deploy -depends Push, Package { 

}







task RunInitialSetup {
	$DevId = Read-Host 'What is your DevId? e.g [ leblanc | {username} ]'
	$DevEnvironment = Read-Host 'What is your DevEnvironment? e.g [ home.desktop | home.laptop | work | testdev | test | futuredev | futuretest  | generaldev | generaltest | uat | production | training | dr | modeloffice ]'
	$DevTask = Read-Host 'What is your DevTask? e.g [ integration | ui ]'

	$tmp = "no"
	if ($IsInTeamBuild -eq $true) { 
		$tmp = "yes" 
	}
	$response = "Your response: DevProduct:{0}, DevId:{1}, DevEnvironment:{2}, DevTask:{3}, IsInTeamBuild:{4}" -f $DevProduct, $DevId, $DevEnvironment, $DevTask, $tmp 
	
	[Environment]::SetEnvironmentVariable($VariablePrefix + 'DevId', $DevId, "User")
	[Environment]::SetEnvironmentVariable($VariablePrefix + 'DevEnvironment', $DevEnvironment, "User")
	[Environment]::SetEnvironmentVariable($VariablePrefix + 'DevTask', $DevTask, "User")

	Write-Host ''
	Write-Host $response
}

task RunAfterUpdate -depends Init {

	if($script:Databases.Count > 0)
	{
		$DbChangeManagementConfig = $script:BuildFolder + '\Configuration\DbChangeManagement.config'
		$tmpFile =  $script:TemporaryFolder + '\db.config'
		
		exec {
			msbuild $script:FlexibleConfigTask "/t:DoTask" `
				("/p:BuildDirectory={0}" -f $script:BuildFolder) `
				("/p:RootDirectory={0}" -f $script:ProjectDirectoryRoot) `
				("/p:TemporaryDirectory={0}" -f $script:TemporaryFolder) `
				("/p:DevProduct={0}" -f $DevProduct) `
				("/p:DevBranch={0}" -f $script:DevBranch) `
				("/p:DevEnvironment={0}" -f $script:DevEnvironment) `
				("/p:DevTask={0}" -f $script:DevTask) `
				("/p:DevId={0}" -f  $script:DevId) `
				("/p:IsInTeamBuild={0}" -f $IsInTeamBuild) `
				("/p:AssemblyVersion={0}" -f $script:AssemblyVersion) `
				("/p:SourceFile={0}" -f $DbChangeManagementConfig) `
				("/p:DestinationFile={0}" -f $tmpFile) `
				"/fl" `
				("/flp:v=diag;logfile={0}\FlexibleConfigTask.log" -f $script:TemporaryFolder)
		}
		
		foreach ($database in $script:Databases)
		{
			exec {
				msbuild $script:DatabaseChangeManagementTask "/t:DoTask" `
					("/p:BuildDirectory={0}" -f $script:BuildFolder) `
					("/p:RootDirectory={0}" -f $script:ProjectDirectoryRoot) `
					("/p:TemporaryDirectory={0}" -f $script:TemporaryFolder) `
					("/p:DevProduct={0}" -f $DevProduct) `
					("/p:DevBranch={0}" -f $script:DevBranch) `
					("/p:DevEnvironment={0}" -f $script:DevEnvironment) `
					("/p:DevTask={0}" -f $script:DevTask) `
					("/p:DevId={0}" -f  $script:DevId) `
					("/p:IsInTeamBuild={0}" -f $IsInTeamBuild) `
					("/p:AssemblyVersion={0}" -f $script:AssemblyVersion) `
					("/p:TaskConfiguration={0}" -f $tmpFile) `
					("/p:PrefixedName={0}" -f $database.PrefixedName) `
					("/p:DatabaseName={0}" -f $database.DatabaseName) `
					("/p:IsDbRestoreEnabled={0}" -f $IsDbRestoreEnabled) `
					("/p:VcsPath={0}" -f $script:VcsPath) `
					"/fl" `
					("/flp:v=diag;logfile={0}\DatabaseChangeManagementTask.log" -f $script:TemporaryFolder)
			}
		}
	}

	remove-item -force -recurse $script:TemporaryFolder -ErrorAction SilentlyContinue 
		#InfraChangesSync, 

	#	throw "I failed on purpose!"
}


task ? -Description "Helper to display task info" {
	Write-Documentation
}