RobustHaven.DevOps
==================

Since 2013 we have used this DevOps approach on all of our .NET projects.
This project solves db, config, infrastructure change management and distributed team integration issues with run-initial-setup.ps1, run-after-update.ps1, and run-dbrestore.ps1.
This is a key integration component to a complete continuous integration and continuous deployment system.  

[March 16, 2013 - DevOps: Integration, Deployment - Continuous Delivery](https://goo.gl/WYVQNl)


Concepts
===========
Your devs use daily and locally execute: run-after-update.ps1, run-dbrestore.ps1.
TeamCity runs your continuous integration and outputs nuget artifacts our script creates that can be integrated into octopus deploy for continuous deployment.


Conventions
===========

1. Download this project into a folder called "_RobustHaven.DevOps" in the root of your project folder.

Git repos can do this:

```git submodule add https://github.com/leblancmeneses/RobustHaven.DevOps.git _RobustHaven.DevOps```

SVN repos can use svn externals to accomplish the same.


2. "_RobustHaven.DevOps" expects the following project structure on your root.

```
	_RobustHaven.DevOps - readonly; never change.
	build - should contain:  _init.include, _init.ps1
	Database - should contain: nested folders of names of your databases that contain .sql migration scripts.
	InfraScripts - should contain: .ps1 migration scripts.
	run-after-update.ps1
	run-dbrestore.ps1
	run-deploy.ps1
	run-initial-setup.ps1
```

Your can copy _RobustHaven.DevOps\SampleRoot  and update build\_init.ps1.  
"build\_init.ps1" is your build definition and hook into the "_RobustHaven.DevOps" build system.


3. TeamCity integration "Script source:" section:

```
	$ScriptPath = pwd
	& "$ScriptPath\tools\psake.4.2.0.1\tools\psake.ps1" -buildFile "$ScriptPath\Build.ps1" -taskList default -properties @{ IsInTeamBuild=$true; DevEnvironment='production'; PassYourCustomVariables=$false; }
	if($psake.build_success -eq $false){exit 1} else {exit 0}
```