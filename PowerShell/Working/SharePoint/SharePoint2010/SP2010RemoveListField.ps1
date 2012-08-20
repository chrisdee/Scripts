## SharePoint Server 2010: PowerShell Scripts To Delete Column Fields Attached To Content Types Or Directly To Lists ##

<#

Overview: The 2 scripts below can be edited to be used for either of the following scenarios related to removing column fields

Script 1: Removes a Column attached to Content Types

Script 2: Removes a Column Field attached directly to List Libraries

#>

## Script 1: Removes a Column attached to Content Types

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

#Attach to the web and content type
$web = Get-SPWeb "http://YourWebApp/YourSite.com" #Change this to your URL
$ct = $web.ContentTypes["YourContentTypeName"] #Change this to the Content Type name

#Get link to the column from the web
$spFieldLink = New-Object Microsoft.SharePoint.SPFieldLink ($web.Fields["YourColumnName"]) #Change this to your Field name

#Remove the column from the content type and update
$ct.FieldLinks.Delete($spFieldLink.Id)
$ct.Update()

#Dispose of the web object
$web.Dispose()


## Script 2: Removes a Column Field attached to List Libraries

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$web = Get-SPWeb "http://YourWebApp/YourSite.com" #Change this to your URL
$list = $web.Lists["YourListName"] #Change this to your List Name
$field = $list.Fields["YourFieldName"] #Change this to your Field name
$field.AllowDeletion = “true”
$field.Sealed = “false”
$field.Delete()
$list.Update()
$web.Dispose()