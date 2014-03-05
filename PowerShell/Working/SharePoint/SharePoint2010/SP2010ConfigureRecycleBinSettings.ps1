## Sharepoint Server: Powershell Script to Configure Web Application Recycle Bin Settings ##

<#

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the following variables to match your requirements: '$WebApp'; '$WebApp.RecycleBinEnabled'; '$WebApp.RecycleBinRetentionPeriod'; '$WebApp.SecondStageRecycleBinQuota'

Resources: 

http://www.sharepointdiary.com/2013/05/set-sharepoint-recycle-bin-properties-programmatically-powershell.html

http://www.sharepointdiary.com/2011/09/sharepoint-recycle-bins-lets-get-it-clear.html

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Get the Web Application
$WebApp = Get-SpWebApplication "http://inside.npe.theglobalfund.org" #Change this to match your environment
 
#*** Set Recycle bin Options ***
#Enable Recycle bin
$WebApp.RecycleBinEnabled = $true #Set this to $false if you want to disable the recycle bin
 
#Set Retention Period number of days
$WebApp.RecycleBinRetentionPeriod = 90 #Change the number of days here
#To Turnoff Recycle bin Retention, use: $WebApp.RecycleBinCleanUpEnabled=$false
 
#Set Second Stage Recycle bin Quota %
$WebApp.SecondStageRecycleBinQuota = 100 #Change the '%' percentage here
#To turn OFF Second Stage recycle bin, use: $WebApp.SecondStageRecycleBinQuota = 0
 
#Apply the changes
$WebApp.Update()
 
Write-Host "Recycle bin Settings Updated!"