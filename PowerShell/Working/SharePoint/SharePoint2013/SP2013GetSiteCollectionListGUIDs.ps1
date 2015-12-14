## SharePoint Server: PowerShell Script to Get GUID IDs (GUIDs) for Lists in a Site Collection ##

<#

Overview: PowerShell Script that Gets the GUID for Site Collection Lists. Returns all lists or a sub-set of lists depending on the list Base Type

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the '$site' variable to match your environment and run the script. Uncomment the queries below if the results requires additional filtering

Resource: http://www.enjoysharepoint.com/Articles/Details/sharepoint-2013-get-sharepoint-list-or-document-library-guids-using-21333.aspx

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell"
$site = Get-SPSite "https://yoursitecollection.com" #Edit this site collection URL to match your environment
$web = $site.RootWeb

## Returns GUIDs for all lists in a site collection
$lists = $web.lists 
$lists | Format-Table title,id -AutoSize 

## Returns GUIDs for all lists in a site collection where the Base Type is 'GenericList' 
##$lists = $web.lists | Where-Object { $_.BaseType -Eq "GenericList" }
##$lists | Format-Table title,id -AutoSize

## Returns GUIDs for all lists in a site collection where the Base Type is 'DocumentLibrary' 
##$libraries = $web.lists | Where-Object { $_.BaseType -Eq "DocumentLibrary" }
##$libraries | Format-Table title,id -AutoSize
