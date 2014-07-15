
task IdentifyBuildVariables {

	$BuildNumber = $build_number 
	$RevisionNumber = $build_vcs_number
	$script:AssemblyVersion = "1.5.$BuildNumber.$RevisionNumber"
		
	$script:BuildFolder = (pwd).path
	$script:ProjectDirectoryRoot = [io.path]::Combine($BuildFolder, (resolve-path ..).path)
	$script:TemporaryFolder = "$ProjectDirectoryRoot\tmp"
	$script:DeployFolder = "$ProjectDirectoryRoot\Deploy"
	$script:EnvironmentMetaBase = "$ProjectDirectoryRoot\externs\repos\production_metadata"
	
	$script:VcsPath = 'http://svn2.robusthaven.com/repos/team_robusthaven_www/'
	

	if ($IsInTeamBuild -eq $false) { 
		$script:DevId = [Environment]::GetEnvironmentVariable("$($VariablePrefix)DevId","User")
		$script:DevEnvironment = [Environment]::GetEnvironmentVariable("$($VariablePrefix)DevEnvironment","User")
		$script:DevTask = [Environment]::GetEnvironmentVariable("$($VariablePrefix)DevTask","User")
	}
	else
	{
		$script:DevId = 'TeamCity'
		$script:DevTask = 'integration'
		$script:DevEnvironment = $DevEnvironment
	}
	$script:DevBranch = ([io.path]::GetFileName( (get-item $script:BuildFolder).parent.FullName ) ) 

	$script:NugetDeployFeedFolder = "C:\inetpub\wwwroot\deployfeed-cms\Packages"

	
	
	$script:NugetTask = "$script:BuildFolder\tools\.nuget\NuGet.exe"
	$script:FlexibleConfigTask = $script:BuildFolder + '\tools\RobustHaven.Tasks\_FlexibleConfigTask.proj'
	$script:DatabaseChangeManagementTask = $script:BuildFolder + '\tools\RobustHaven.Tasks\_DatabaseChangeManagementTask.proj'
	$script:XDTTask = $script:BuildFolder + '\tools\RobustHaven.Tasks\_XDT.proj'
	$script:ObfuscatorTask ='C:\Program Files (x86)\Eziriz\.NET Reactor\dotNET_Reactor.exe'
	$script:SignTask = 'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Bin\signtool.exe'
	

	
	
	$fullPath = Resolve-Path "Configuration\Cms.Web.config"
	cmd /c mklink "Configuration\RobustHavenWebsite.Web.config" $fullPath
	
	
	
	
	
	
	
	$DbPrefix = ''
	$script:Databases = @()
	$script:Databases += New-Database 'Websites' ($DbPrefix+'Websites')
	
		
	$script:StagingEnvironments = @()
	$script:StagingEnvironments += New-StagingEnvironment 'production' ([PackageTypes]::Production)
	
	
	$script:PackageItems = @()
	
	$script:PackageItems += New-PackageItem	'Presentations' `
		([ProjectTypes]::Website) `
		"$ProjectDirectoryRoot\Presentations.sln"  `
		"Web.config"  `
		"$DeployFolder\Presentations"  `
		"$ProjectDirectoryRoot\Presentations\DevOps" `
		@() `
		'RHPresentations' `
		'RHPresentations' `
		'Robust Haven Inc' `
		'Presentations' `
		'http://www.robusthaven.com/' `
		'http://www.robusthaven.com/' `
		"This is Robust Haven's Presentations." `
		''
		
	$script:PackageItems += New-PackageItem	'RobustHavenWebsite' `
		([ProjectTypes]::Website) `
		"$ProjectDirectoryRoot\Cms.sln"  `
		"Web.config"  `
		"$DeployFolder\Cms"  `
		"$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication" `
		@() `
		'RobustHavenWebsite' `
		'RobustHavenWebsite' `
		'Robust Haven Inc' `
		'Content Management System' `
		'http://www.robusthaven.com/' `
		'http://www.robusthaven.com/' `
		"This is RobustHavenWebsite." `
		'' `
		{
		} `
		{
			rm -recurse "$DeployFolder\Cms\Tenants\www.robusthaven.com\Data"
			if($RunInternalPackageDistribution)
			{
				$areas = @('RobustHaven.Areas.AliasUrlModule.dll', 'RobustHaven.Areas.AnalyticsModule.dll', 'RobustHaven.Areas.AttachmentModule.dll', 'RobustHaven.Areas.CommentsModule.dll', 'RobustHaven.Areas.ContactModule.dll',
					'RobustHaven.Areas.ContentModule.dll', 'RobustHaven.Areas.EmailSubscriptionModule.dll', 'RobustHaven.Areas.ExperienceModule.dll', 'RobustHaven.Areas.FeatureModule.dll',
					'RobustHaven.Areas.ForumModule.dll','RobustHaven.Areas.GalleryModule.dll','RobustHaven.Areas.JobModule.dll','RobustHaven.Areas.MenuModule.dll','RobustHaven.Areas.PartialViewModule.dll',
					'RobustHaven.Areas.PostModule.dll','RobustHaven.Areas.ProductModule.dll','RobustHaven.Areas.RevisionHistoryModule.dll','RobustHaven.Areas.RevisionHistoryModule.Messages.dll',
					'RobustHaven.Areas.SecurityModule.dll','RobustHaven.Areas.StoreLocatorModule.dll','RobustHaven.Areas.TestimonialModule.dll','RobustHaven.Web.dll')
					
				
				foreach($area in $areas)
				{
					$withoutExt = [io.path]::GetFileNameWithoutExtension($area)
					$dll = $script:ProjectDirectoryRoot + "\robusthaven.com.www\RobustHaven.Www.WebApplication\bin\$area"
					$pdb = $script:ProjectDirectoryRoot + "\robusthaven.com.www\RobustHaven.Www.WebApplication\bin\$withoutExt" + '.pdb'
					New-Item "$DeployFolder\$withoutExt" -type directory
					New-Item "$DeployFolder\$withoutExt\lib" -type directory

					cp $dll "$DeployFolder\$withoutExt\lib"
					cp $pdb "$DeployFolder\$withoutExt"
<#  
						exec {
							$params = @("-quiet", "-file", $dll, '-targetfile', "$DeployFolder\$withoutExt\lib\$area")
							& "$script:ObfuscatorTask" @params
						}
						$waitForFile = "$DeployFolder\$withoutExt\lib\$area"
						WaitForFile($waitForFile)
						mv "$DeployFolder\$withoutExt\lib\$withoutExt.pdb" "$DeployFolder\$withoutExt\$withoutExt.pdb"				
#>

					$packageConfig = ""
					
					$parts = ($area -split "\.")
					
					if($area -eq 'RobustHaven.Web.dll')
					{
						$packageConfig = "$ProjectDirectoryRoot\Areas\RobustHaven.Web\packages.config"
					}
					ElseIf ($parts.Length -eq 5)
					{
						$packageConfig = "$ProjectDirectoryRoot\Areas\" + $parts[2] + '.' + $parts[3] + '\packages.config'
					}
					ElseIf ($parts.Length -eq 4)
					{
						$packageConfig = "$ProjectDirectoryRoot\Areas\" + $parts[2] + '\packages.config'
					}
						
						
					if($area -ne 'RobustHaven.Web.dll')
					{
						New-Item ("$DeployFolder\"+ $withoutExt + "\content") -type directory
						New-Item ("$DeployFolder\"+ $withoutExt + "\content\Areas") -type directory
						cp -recurse ("$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\Areas\"+$parts[2]) ("$DeployFolder\"+ $withoutExt + "\content\Areas")
					}
					
					
					$nuspecFile = "$DeployFolder\$withoutExt\$withoutExt" + '.nuspec'
					Generate-Nuspec -NuspecId $withoutExt `
						-NuspecTitle $withoutExt `
						-NuspecAuthors 'Robust Haven Inc' `
						-NuspecOwners 'Robust Haven Inc' `
						-NuspecLicenseUrl 'http://www.robusthaven.com' `
						-NuspecProjectUrl 'http://www.robusthaven.com' `
						-NuspecDescription $withoutExt `
						-AssemblyVersion $script:AssemblyVersion `
						-PackageConfig $packageConfig `
						-file $nuspecFile					
						
					exec {
						$args = @('pack', ('"{0}"' -f $nuspecFile), '-OutputDirectory',  ('"{0}"' -f $script:DeployFolder), '-Version', ('"{0}"' -f $script:AssemblyVersion),  '-NoPackageAnalysis')
						& "$script:NugetTask" $args | Write-Host
					}
					
					mv -Force ("{0}\{1}.{2}.nupkg" -f $script:DeployFolder, $withoutExt, $script:AssemblyVersion) "C:\inetpub\wwwroot\deployfeed-rh-internal\Packages"
				}
					
				




				New-Item "$DeployFolder\RobustHaven.Web.UI" -type directory

				Touch-File "$DeployFolder\RobustHaven.Web.UI\RobustHaven.Web.UI.nuspec"
				(Get-Content "$ProjectDirectoryRoot\build\RobustHaven.Web.UI.nuspec") | Foreach-Object {
				$_ -replace '0\.0\.0\.0', $script:AssemblyVersion 
				} | Set-Content "$DeployFolder\RobustHaven.Web.UI\RobustHaven.Web.UI.nuspec"
					
				New-Item "$DeployFolder\RobustHaven.Web.UI\content" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\Areas" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\Views" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\Views\Shared" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\Views\Shared\DisplayTemplates" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\Views\Shared\EditorTemplates" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\App_Data" -type directory
				New-Item "$DeployFolder\RobustHaven.Web.UI\content\Areas\RobustHavenWeb" -type directory
				cp -recurse -Force "$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\Areas\RobustHavenWeb\*" "$DeployFolder\RobustHaven.Web.UI\content\Areas\RobustHavenWeb"
				cp -recurse -Force "$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\App_Data\*" "$DeployFolder\RobustHaven.Web.UI\content\App_Data"
				cp -recurse -Force "$ProjectDirectoryRoot\RobustHaven.TelerikMvcExt\content\*"  "$DeployFolder\RobustHaven.Web.UI\content"
				cp "$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\Views\Shared\DisplayTemplates\Breadcrumb.cshtml" "$DeployFolder\RobustHaven.Web.UI\content\Views\Shared\DisplayTemplates"
				cp "$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\Views\Shared\EditorTemplates\CMSRichTextEditor.cshtml" "$DeployFolder\RobustHaven.Web.UI\content\Views\Shared\EditorTemplates"
				
				exec {
					$args = @('pack', ('"{0}"' -f "$DeployFolder\RobustHaven.Web.UI\RobustHaven.Web.UI.nuspec"), '-OutputDirectory',  ('"{0}"' -f $script:DeployFolder), '-Version', ('"{0}"' -f $script:AssemblyVersion),  '-NoPackageAnalysis')
					& "$script:NugetTask" $args | Write-Host
				}

				mv -Force ("{0}\RobustHaven.Web.UI.{1}.nupkg" -f $script:DeployFolder, $script:AssemblyVersion) "C:\inetpub\wwwroot\deployfeed-rh-internal\Packages"
				





				New-Item "$DeployFolder\Base.UI" -type directory
				New-Item "$DeployFolder\Base.UI\content" -type directory
				New-Item "$DeployFolder\Base.UI\content\Areas" -type directory
				New-Item "$DeployFolder\Base.UI\content\Areas\Base" -type directory
				
				Touch-File "$DeployFolder\Base.UI\Base.UI.nuspec"
				(Get-Content "$ProjectDirectoryRoot\build\Base.UI.nuspec") | Foreach-Object {
				$_ -replace '0\.0\.0\.0', $script:AssemblyVersion 
				} | Set-Content "$DeployFolder\Base.UI\Base.UI.nuspec"
					
				cp -recurse -Force "$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\Areas\Base\*" "$DeployFolder\Base.UI\content\Areas\Base"
					
				exec {
					$args = @('pack', ('"{0}"' -f "$DeployFolder\Base.UI\Base.UI.nuspec"), '-OutputDirectory',  ('"{0}"' -f $script:DeployFolder), '-Version', ('"{0}"' -f $script:AssemblyVersion),  '-NoPackageAnalysis')
					& "$script:NugetTask" $args | Write-Host
				}

				mv -Force ("{0}\Base.UI.{1}.nupkg" -f $script:DeployFolder, $script:AssemblyVersion) "C:\inetpub\wwwroot\deployfeed-rh-internal\Packages"
				





				
				Generate-Nuspec -NuspecId 'RobustHaven.EntlibExt' `
					-NuspecTitle 'RobustHaven.EntlibExt'  `
					-NuspecAuthors 'Robust Haven Inc' `
					-NuspecOwners 'Robust Haven Inc' `
					-NuspecLicenseUrl 'http://www.robusthaven.com' `
					-NuspecProjectUrl 'http://www.robusthaven.com' `
					-NuspecDescription "This is Robust Haven's RobustHaven.EntlibExt." `
					-AssemblyVersion $script:AssemblyVersion `
					-PackageConfig "$ProjectDirectoryRoot\RobustHaven.EntlibExt\packages.config" `
					-file "$DeployFolder\RobustHaven.EntlibExt\RobustHaven.EntlibExt.nuspec"

				New-Item "$DeployFolder\RobustHaven.EntlibExt\lib" -type directory
				mv "$ProjectDirectoryRoot\robusthaven.com.www\RobustHaven.Www.WebApplication\bin\RobustHaven.EntlibExt.dll" ("{0}\RobustHaven.EntlibExt\lib" -f $script:DeployFolder)
				
				exec {
					$args = @('pack', ('"{0}"' -f "$DeployFolder\RobustHaven.EntlibExt\RobustHaven.EntlibExt.nuspec"), '-OutputDirectory',  ('"{0}"' -f $script:DeployFolder), '-Version', ('"{0}"' -f $script:AssemblyVersion),  '-NoPackageAnalysis')
					& "$script:NugetTask" $args | Write-Host
				}

				mv -Force ("{0}\RobustHaven.EntlibExt.{1}.nupkg" -f $script:DeployFolder, $script:AssemblyVersion) "C:\inetpub\wwwroot\deployfeed-rh-internal\Packages"
			}
			
		}
		
		

		


	if($RunInternalPackageDistribution)
	{
		$script:PackageItems += New-PackageItem	'RobustHaven.TelerikMvcExt' `
			([ProjectTypes]::XCopy) `
			"$ProjectDirectoryRoot\RobustHaven.TelerikMvcExt"  `
			"Web.config"  `
			"$DeployFolder\RobustHaven.TelerikMvcExt"  `
			"$ProjectDirectoryRoot\RobustHaven.TelerikMvcExt" `
			@() `
			'RobustHaven.TelerikMvcExt' `
			'RobustHaven.TelerikMvcExt' `
			'Robust Haven Inc' `
			'RobustHaven.TelerikMvcExt' `
			'http://www.robusthaven.com/' `
			'http://www.robusthaven.com/' `
			"This is Robust Haven's RobustHaven.TelerikMvcExt." `
			'' `
			{
				Write-Host 'PreInit'			
			} `
			{ 
				Write-Host 'PrePackage'	
				Remove-Item "$DeployFolder\RobustHaven.TelerikMvcExt\content\*"  -recurse
			} `
			{
				Write-Host 'PrePush'
				mv -Force ("{0}\RobustHaven.TelerikMvcExt.{1}.nupkg" -f $script:DeployFolder, $script:AssemblyVersion) "C:\inetpub\wwwroot\deployfeed-rh-internal\Packages"
			}
			
		$script:PackageItems += New-PackageItem	'RobustHaven.TelerikReportingExt' `
			([ProjectTypes]::XCopy) `
			"$ProjectDirectoryRoot\RobustHaven.TelerikReportingExt"  `
			"Web.config"  `
			"$DeployFolder\RobustHaven.TelerikReportingExt"  `
			"$ProjectDirectoryRoot\RobustHaven.TelerikReportingExt" `
			@() `
			'RobustHaven.TelerikReportingExt' `
			'RobustHaven.TelerikReportingExt' `
			'Robust Haven Inc' `
			'RobustHaven.TelerikReportingExt' `
			'http://www.robusthaven.com/' `
			'http://www.robusthaven.com/' `
			"This is Robust Haven's RobustHaven.TelerikReportingExt." `
			'' `
			{
				Write-Host 'PreInit'			
			} `
			{ 
				Write-Host 'PrePackage'	
			} `
			{
				Write-Host 'PrePush'
				mv -Force ("{0}\RobustHaven.TelerikReportingExt.{1}.nupkg" -f $script:DeployFolder, $script:AssemblyVersion) "C:\inetpub\wwwroot\deployfeed-rh-internal\Packages"
			}

	}



		
	$script:PackageItems += New-PackageItem	'DbChangeManagement' `
		([ProjectTypes]::XCopy) `
		"$ProjectDirectoryRoot\build\Octopus\Step.DatabaseChangeManagement"  `
		"Web.config"  `
		"$DeployFolder\DbChangeManagement"  `
		"$ProjectDirectoryRoot\build\Octopus\Step.DatabaseChangeManagement" `
		@() `
		'DbChangeManagement' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		{
			Write-Host 'PreInit'			
		} `
		{ 
			cp ($script:BuildFolder + '\Octopus\OctopusDeployment.psm1') "$DeployFolder\DbChangeManagement"
			cp ($script:BuildFolder + '\Octopus\DeployFailed.ps1') "$DeployFolder\DbChangeManagement"

			cp ($script:BuildFolder + '\tools\RobustHaven.Tasks\RobustHaven.Tasks.dll')  "$DeployFolder\DbChangeManagement"
			cp ($script:BuildFolder + '\tools\RobustHaven.Tasks\RobustHaven.Tasks.Targets')  "$DeployFolder\DbChangeManagement"
			cp ($script:ProjectDirectoryRoot + '\Databases')  "$DeployFolder\DbChangeManagement\Databases" -rec -filter *.sql 
		}

	$script:PackageItems += New-PackageItem	'App_Offline' `
		([ProjectTypes]::XCopy) `
		"$ProjectDirectoryRoot\build\Octopus\Step.App_Offline"  `
		"Web.config"  `
		"$DeployFolder\App_Offline"  `
		"$ProjectDirectoryRoot\build\Octopus\Step.App_Offline" `
		@() `
		'App_Offline' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		{
			Write-Host 'PreInit'			
		} `
		{
			cp ($script:BuildFolder + '\Octopus\OctopusDeployment.psm1') "$DeployFolder\App_Offline"
			cp ($script:BuildFolder + '\Octopus\DeployFailed.ps1') "$DeployFolder\App_Offline"
		}

	$script:PackageItems += New-PackageItem	'PurgeActivityForDeployment' `
		([ProjectTypes]::XCopy) `
		"$ProjectDirectoryRoot\build\Octopus\Step.PurgeActivityForDeployment"  `
		"Web.config"  `
		"$DeployFolder\PurgeActivityForDeployment"  `
		"$ProjectDirectoryRoot\build\Octopus\Step.PurgeActivityForDeployment" `
		@() `
		'PurgeActivityForDeployment' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		{
			Write-Host 'PreInit'			
		} `
		{
			cp ($script:BuildFolder + '\Octopus\OctopusDeployment.psm1') "$DeployFolder\PurgeActivityForDeployment"
			cp ($script:BuildFolder + '\Octopus\DeployFailed.ps1') "$DeployFolder\PurgeActivityForDeployment"
		}
		
	$script:PackageItems += New-PackageItem	'InfrastructureChangeManagement' `
		([ProjectTypes]::XCopy) `
		"$ProjectDirectoryRoot\build\Octopus\Step.InfrastructureChangeManagement"  `
		"Web.config"  `
		"$DeployFolder\InfrastructureChangeManagement"  `
		"$ProjectDirectoryRoot\build\Octopus\Step.InfrastructureChangeManagement" `
		@() `
		'InfrastructureChangeManagement' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		'' `
		{
			Write-Host 'PreInit'			
		} `
		{
			cp ($script:BuildFolder + '\Octopus\OctopusDeployment.psm1') "$DeployFolder\InfrastructureChangeManagement"
			cp ($script:BuildFolder + '\Octopus\DeployFailed.ps1') "$DeployFolder\InfrastructureChangeManagement"
			
			cp ($script:BuildFolder + '\tools\RobustHaven.Tasks\RobustHaven.Tasks.dll')  "$DeployFolder\InfrastructureChangeManagement"
			cp ($script:BuildFolder + '\tools\RobustHaven.Tasks\RobustHaven.Tasks.Targets')  "$DeployFolder\InfrastructureChangeManagement"
			cp ($script:ProjectDirectoryRoot + '\InfraScripts')  "$DeployFolder\InfrastructureChangeManagement\InfraScripts" -rec -filter *.ps1 
		}

		
		
	
	
	Generate-Assembly-Info `
		-file ("{0}\GlobalAssemblyInfo.cs" -f $ProjectDirectoryRoot) `
		-company $CompanyName `
		-product ("{0} {1}" -f $DevProduct, $script:AssemblyVersion) `
		-version $script:AssemblyVersion `
		-clsCompliant "false" `
		-copyright ("{0} 2013" -f $CompanyName)
		
		
	
	$tmp = "no"
	if ($IsInTeamBuild -eq $true) { 
		$tmp = "yes" 
	}
	$response = "Your response: DevProduct:{0}, DevBranch:{1}, DevEnvironment:{2}, DevTask:{3}, DevId:{4}, IsInTeamBuild:{5}" -f $DevProduct, $script:DevBranch, $script:DevEnvironment, $script:DevTask, $script:DevId, $tmp
	Write-Host $response
}