# Don't run everything, thanks @alexandair!
clear
break


# Load dbatools module
Import-Module dbatools -force


# Quick overview of commands
Start-Process https://dbatools.io/commands


# Set connection variables
$SQLServers = "localhost\dev2016", "localhost\prd2016", "localhost\dev2017", "localhost\prd2017"
$singleServer = "localhost\dev2016"
$devServers = "localhost\dev2016", "localhost\dev2017"
$prdServers = "localhost\prd2016", "localhost\prd2017"
$CmsInstance = 'localhost\sql2017'
$ComputerName = 'DESKTOP-EBH9MR8'
$dev2016 = "localhost\dev2016"
$prd2016 = "localhost\prd2016"
$prd2017 = "localhost\prd2017"


# Get connections from Registered Servers (CMS) 
$RegisteredServers = Get-DbaRegisteredServer -SqlInstance $CmsInstance
$RegisteredServers | Select-Object ServerName


# Max Memory Setting
Test-DbaMaxMemory -SqlInstance $SQLServers | Out-GridView
Set-DbaMaxMemory -SqlInstance $SQLServers -MaxMB 1024
Test-DbaMaxMemory -SqlInstance $SQLServers | Out-GridView


# sp_configure settings
Get-DbaSpConfigure -SqlInstance $singleServer | Out-GridView
$sourceConfig = Get-DbaSpConfigure -SqlInstance $dev2016 
$destConfig = Get-DbaSpConfigure -SqlInstance $prd2016 

Compare-Object -ReferenceObject $sourceConfig -DifferenceObject $destConfig -Property DisplayName, RunningValue -PassThru | Sort-Object DisplayName | Select-Object DisplayName, RunningValue, ServerName


# TempDB Configuration
Test-DbaTempDbConfiguration -SqlInstance $dev2016 | Select-Object SqlInstance, Rule, Recommended, CurrentSetting, IsBestPractice | Out-GridView


# Startup Parameters
Get-DbaStartupParameter -SqlInstance $dev2016
Set-DbaStartupParameter -SqlInstance $dev2016 -TraceFlags 3226 -Confirm:$false


# DBA Orphan Files
$SQLServers | Find-DbaOrphanedFile

# DBA Orphan User
Get-DbaOrphanUser -SqlInstance $prd2017
Repair-DbaOrphanUser -SqlInstance $prd2017


# You can use the same JSON the website uses to check the status of your own environment
$SQLServers | Get-DbaSqlBuildReference | Out-GridView
$SQLServers | Test-DbaSqlBuild -MaxBehind 2CU | Out-GridView

Start-Process https://sqlcollaborative.github.io/builds


# SQL Agent Jobs
Get-DbaAgentJob -SqlInstance $dev2016 | Out-GridView
Get-DbaAgentJob -SqlInstance $dev2016 | Export-DbaScript -Path C:\temp\jobs.sql
Start-Process C:\Temp\jobs.sql
Find-DbaAgentJob -SqlInstance $SQLServers -JobName dbatools_magic | Out-GridView


# Support Tools
Install-DbaMaintenanceSolution -SqlInstance $SQLServers -Database DBA -CleanupTime 72 -BackupLocation C:\Temp -InstallJobs -ReplaceExisting 

Install-DbaWhoIsActive -SqlInstance $SQLServers -Database DBA

Install-DbaFirstResponderKit -SqlInstance $SQLServers -Database DBA