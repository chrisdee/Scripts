# FileName: spMigrateUser.ps1
# Name: spMigrateUser.ps1
# Version: 1.0
# Author: Lognoul Marc (lognoulm@hotmail.com)
# Description: Reproduces the behavior of the command STSADM -o migrateuser. More added value to come (batch migration and subsequent updates.
# Tested with: Windows 2003 SP3, Windows 2008 SP2, WSS SP2, MOSS SP2
# Dependencies: Assemblies Microsoft.SharePoint and Microsoft.SharePoint.Administration

[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Administration") 

$OldLogin = "DOMAIN\USER"
$NewLogin = "DOMAIN\USER"
$EnforceSidHistory = $False

$spFarm = [Microsoft.SharePoint.Administration.SPfarm]::Local 
$spFarm.MigrateUserAccount($OldLogin, $NewLogin, $EnforceSidHistory) 