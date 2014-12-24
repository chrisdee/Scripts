## SharePoint Server: PowerShell Script To Update User Display Names (DisplayName) From AD ##

<#

Overview: The script below is designed to resolve the common issue in SharePoint Server where the user name (DisplayName) property might show as 'DOMAIN\UserName' or 'UserName' instead of the full Display Name

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables below to match your environment and run the script. Check your log files generated prior to against the ones generated after the script has run to ensure the affected accounts have been updated

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

##### Begin Variables #####
$SPWeb = "https://yourwebapp.com" #Change this to match your environment
$Domain = "*YourDomain*" #Change this domain syntax to match your DC properties
$LogFilePrior = "C:\BoxBuild\LogFilePrior.txt"
$LogFileAfter = "C:\BoxBuild\LogFileAfter.txt"
##### End Variables #####

## Display all the user accounts for the SPWeb Prior to the AD Sync

Get-SPUser –Web $SPWeb | Where-Object {$_.UserLogin –like $Domain} | Out-File -FilePath $LogFilePrior

## Display a count of all the user accounts for the SPWeb

Get-SPUser –Web $SPWeb | Where-Object {$_.UserLogin –like $Domain} | Measure-Object | Out-File -FilePath $LogFilePrior -Append

## Now run the command to update the accounts with a Sync from Active Dirtecory (AD)

Get-SPUser –Web $SPWeb | Set-SPUser –SyncFromAD

## Display all the user accounts for the SPWeb After the AD Sync

Get-SPUser –Web $SPWeb | Where-Object {$_.UserLogin –like $Domain} | Out-File -FilePath $LogFileAfter

## Display a count of all the user accounts for the SPWeb

Get-SPUser –Web $SPWeb | Where-Object {$_.UserLogin –like $Domain} | Measure-Object | Out-File -FilePath $LogFileAfter -Append