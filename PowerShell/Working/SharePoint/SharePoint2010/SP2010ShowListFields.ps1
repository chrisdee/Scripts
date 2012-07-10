## SharePoint Server: PowerShell Script to Show All Fields In A List (Includes Custom and System Fields) ##
## Resource: http://allaboutmoss.com/2010/05/11/3-ways-to-find-sharepoint-list-fields-internal-name
## Environments: MOSS 2007 and SharePoint Server 2010

[system.reflection.assembly]::loadwithpartialname("microsoft.sharepoint")
$site= New-Object Microsoft.SharePoint.SPSite ("http://YourSPSite") #Change this to suit your environment
$web=$site.OpenWeb()
$list=$web.Lists["TestCustomList"] #Change this to your list name
$list.Fields |select title, internalname| more