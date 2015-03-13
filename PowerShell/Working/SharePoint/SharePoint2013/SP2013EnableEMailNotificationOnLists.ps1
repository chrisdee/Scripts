## SharePoint Server: PowerShell Script to Enable Email Notifications on Lists via CSOM ##

<#

Overview: In some SharePoint Farms the 'E-Mail Notification' option to 'Send e-mail when ownership is assigned?' is not present under 'List Settings --> Advanced settings'

Note: This option only appears to be available on 'Issue Tracking' lists on the affected Farms 'out of the box'

Environments: SharePoint Server 2013 Farms

Usage: Edit the following variables to match your environment and run the script: '$SPSite'; '$SPList'. Change the 'EnableAssignToEmail' value to '$false' if you want to disable this property

Resource: https://gallery.technet.microsoft.com/office/Enable-email-notifications-390a927c

#>

Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

$SPSite = "https://YourSharePointSite.com" #Provide your SharePoint site URL here
$SPList = "Task List" #provide your List Name here

$web = Get-SPWeb "$SPSite"

$list = $web.Lists.TryGetList("$SPList") 

$list.EnableAssignToEmail = $true #Set this to '$false' if you want to disable this property

$list.Update()