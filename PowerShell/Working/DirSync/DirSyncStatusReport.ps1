## DirSync: PowerShell Script that Displays Information about a DirSync Instance including SQL Info and Recent Sync Activity ##

<#
Description:
This script gathers DirSync information from various locations and reports to the screen.

November 5 2013
Mike Crowley
http://mikecrowley.us
http://mikecrowley.wordpress.com/2013/10/16/dirsync-report
https://gallery.technet.microsoft.com/DirSync-Report-17521dfb

Known Issues:
1) All commands, including SQL queries run as the local user.  This may cause issues on locked-down SQL deployments.
2) For remote SQL installations, the SQL PowerShell module must be installed on the dirsync server.
    (http://technet.microsoft.com/en-us/library/hh231683.aspx)
3) The Azure Service account field is actually just the last account to use the Sign In Assistant.  
    There are multiple entries at that registry location.  We're just taking the last one.
4) Assumes Dirsync version 6385.0012 or later.

#>

#Console Prep
cls
Write-Host "Please wait..." -F Yellow
ipmo SQLps

#Check for SQL Module
if ((gmo sqlps) -eq $null) {
    write-host "The SQL PowerShell Module Is Not loaded.  Please install and try again" -F Red
    write-host "http://technet.microsoft.com/en-us/library/hh231683.aspx" -F Red
    Write-Host "Quitting..." -F Red; sleep 5; Break
    }

#Get Dirsync Registry Info
$DirsyncVersion = (gp 'hklm:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Online Directory Sync').DisplayVersion
$DirsyncPath = (gp 'hklm:SOFTWARE\Microsoft\MSOLCoExistence').InstallPath
$FullSyncNeededBit = (gp 'hklm:SOFTWARE\Microsoft\MSOLCoExistence').FullSyncNeeded
$FullSyncNeeded = "No"
If ((gp 'hklm:SOFTWARE\Microsoft\MSOLCoExistence').FullSyncNeeded -eq '1') {$FullSyncNeeded = "Yes"}

#Get SQL Info
$SQLServer = (gp 'HKLM:SYSTEM\CurrentControlSet\services\FIMSynchronizationService\Parameters').Server
if ($SQLServer.Length -eq '0') {$SQLServer = $env:computername}
$SQLInstance = (gp 'HKLM:SYSTEM\CurrentControlSet\services\FIMSynchronizationService\Parameters').SQLInstance
$MSOLInstance = ($SQLServer + "\" + $SQLInstance)
$SQLVersion = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition')" 

#Get Password Sync Status
[xml]$ADMAxml = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT [ma_id] ,[ma_name] ,[private_configuration_xml] FROM [FIMSynchronizationService].[dbo].[mms_management_agent]" | ? {$_.ma_name -eq 'Active Directory Connector'} | select -Expand private_configuration_xml
$PasswordSyncBit = (Select-Xml -XML $ADMAxml -XPath "/adma-configuration/password-hash-sync-config/enabled" | select -expand node).'#text'
$PasswordSyncStatus = "Disabled"
If ($PasswordSyncBit -eq '1') {$PasswordSyncStatus = "Enabled"}

#Get Account Info
$ServiceAccountGuess = (((gci 'hkcu:Software\Microsoft\MSOIdentityCRL\UserExtendedProperties' | select PSChildName)[-1]).PSChildName -split ':')[-1]
$ADServiceAccountUser = $ADMAxml.'adma-configuration'.'forest-login-user'
$ADServiceAccountDomain = $ADMAxml.'adma-configuration'.'forest-login-domain'
$ADServiceAccount = $ADServiceAccountDomain + "\" + $ADServiceAccountUser

#Get DirSync Database Info
$SQLDirSyncInfo = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT DB_NAME(database_id) AS DatabaseName, Name AS Logical_Name, Physical_Name, (size*8)/1024 SizeMB FROM sys.master_files WHERE DB_NAME(database_id) = 'FIMSynchronizationService'" 
$DirSyncDB = $SQLDirSyncInfo | ? {$_.Logical_Name -eq 'FIMSynchronizationService'}
$DirSyncLog = $SQLDirSyncInfo | ? {$_.Logical_Name -eq 'FIMSynchronizationService_log'}

#Get connector space info (optional)
$ADMA = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT [ma_id] ,[ma_name] FROM [FIMSynchronizationService].[dbo].[mms_management_agent] WHERE ma_name = 'Active Directory Connector'"
$AzureMA = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT [ma_id] ,[ma_name] FROM [FIMSynchronizationService].[dbo].[mms_management_agent] WHERE ma_name = 'Windows Azure Active Directory Connector'"
$UsersFromBothMAs = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT [ma_id] ,[rdn] FROM [FIMSynchronizationService].[dbo].[mms_connectorspace] WHERE object_type = 'user'" 
$AzureUsers = $UsersFromBothMAs | ? {$_.ma_id -eq $AzureMA.ma_id}
$ADUsers = $UsersFromBothMAs | ? {$_.ma_id -eq $ADMA.ma_id}

#Get DirSync Run History
$SyncHistory = Invoke-Sqlcmd -ServerInstance $MSOLInstance -Query "SELECT [step_result] ,[end_date] ,[stage_no_change] ,[stage_add] ,[stage_update] ,[stage_rename] ,[stage_delete] ,[stage_deleteadd] ,[stage_failure] FROM [FIMSynchronizationService].[dbo].[mms_step_history]" | sort end_date -Descending

#GetDirSync interval (3 hours is default)
$SyncTimeInterval = (Select-Xml -Path ($DirsyncPath + "Microsoft.Online.DirSync.Scheduler.exe.config") -XPath "configuration/appSettings/add" | select -expand Node).value 

#Generate Output
cls

Write-Host "Report Info" -F DarkGray
Write-Host "Date: " -F Cyan -NoNewline ; Write-Host (Get-Date) -F DarkCyan
Write-Host "Server: " -F Cyan -NoNewline ; Write-Host  $env:computername -F DarkCyan
Write-Host 

Write-Host "Account Info" -F DarkGray
Write-Host "Active Directory Service Account: " -F Cyan -NoNewline ; Write-Host $ADServiceAccount -F DarkCyan
Write-Host "Azure Service Account Guess: " -F Cyan -NoNewline ; Write-Host $ServiceAccountGuess -F DarkCyan
Write-Host

Write-Host "DirSync Info" -F DarkGray
Write-Host "Version: " -F Cyan -NoNewline ; Write-Host $DirsyncVersion -F DarkCyan
Write-Host "Path: " -F Cyan -NoNewline ; Write-Host $DirsyncPath -F DarkCyan
Write-Host "Password Sync Status: " -F Cyan -NoNewline ; Write-Host $PasswordSyncStatus -F DarkCyan
Write-Host "Sync Interval (H:M:S): " -F Cyan -NoNewline ; Write-Host $SyncTimeInterval -F DarkCyan
Write-Host "Full Sync Needed? " -F Cyan -NoNewline ; Write-Host $FullSyncNeeded -F DarkCyan
Write-Host 

Write-Host "User Info" -F DarkGray 
Write-Host "Users in AD connector space: " -F Cyan -NoNewline ; Write-Host $ADUsers.count -F DarkCyan
Write-Host "Users in Azure connector space: " -F Cyan -NoNewline ; Write-Host $AzureUsers.count -F DarkCyan 
Write-Host "Total Users: " -F Cyan -NoNewline ; Write-Host $UsersFromBothMAs.count -F DarkCyan
Write-Host

Write-Host "SQL Info " -F DarkGray 
Write-Host "Version: " -F Cyan -NoNewline ; Write-host $SQLVersion.Column1 $SQLVersion.Column2 $SQLVersion.Column3 -F DarkCyan
Write-Host "Instance: " -F Cyan -NoNewline ; Write-Host  $MSOLInstance -F DarkCyan
Write-Host "Database Location: " -F Cyan -NoNewline ; Write-Host $DirSyncDB.Physical_Name -F DarkCyan
Write-Host "Database Size: " -F Cyan -NoNewline ; Write-Host $DirSyncDB.SizeMB "MB" -F DarkCyan
Write-Host "Database Log Size: " -F Cyan -NoNewline ; Write-Host $DirSyncLog.SizeMB "MB" -F DarkCyan
Write-Host

Write-Host "Most Recent Sync Activity" -F DarkGray
Write-Host "(For more detail, launch:" $DirsyncPath`SYNCBUS\Synchronization Service\UIShell\miisclient.exe")" -F DarkGray
Write-Host "  " ($SyncHistory[0].end_date).ToLocalTime() -F DarkCyan -NoNewline ; Write-Host " --" $SyncHistory[0].step_result -F Gray 
Write-Host "  " ($SyncHistory[1].end_date).ToLocalTime() -F DarkCyan -NoNewline ; Write-Host " --" $SyncHistory[1].step_result -F Gray 
Write-Host "  " ($SyncHistory[2].end_date).ToLocalTime() -F DarkCyan -NoNewline ; Write-Host " --" $SyncHistory[2].step_result -F Gray 
Write-Host