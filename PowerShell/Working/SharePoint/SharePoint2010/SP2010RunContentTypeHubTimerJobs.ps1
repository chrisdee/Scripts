## SharePoint Server: PowerShell Script to run the Content Type Hub related Timer Jobs following Content Type Updates ##

<#

Overview: PowerShell Script that triggers the following timer jobs 'Content Type Hub'; 'Content Type Subscriber'. This is useful to run following changes made in the Content Type Hub that need to be pushed out

Usage: Edit the '-WebApplication' parameter to match the web applications you want the 'Content Type Subscriber' timer job to run against in your environment

Environments: SharePoint Server 2010 / 2013 Farms

#>

Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

#Run the Content Type Hub timer job (default is to run once daily)
$ctHubTJ = Get-SPTimerJob "MetadataHubTimerJob"
$ctHubTJ.RunNow()

#Run the Content Type Subscriber timer job for a specific Web Application (default to run every hour)
$ctSubTJ = Get-SPTimerJob "MetadataSubscriberTimerJob" -WebApplication "https://yourwebapp.com" #Change this path to match your web application URL
$ctSubTJ.RunNow()