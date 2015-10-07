## SharePoint Server: PowerShell Script to Export Site Content Types to an XML File ##

<#

Overview: Script that exports Site Content Types and Fields to an XML file. These exports can be filtered on Content Types Group names 

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables below to match your environment and run the script

Resources: 

http://get-spscripts.com/2011/02/export-and-importcreate-site-content.html
http://get-spscripts.com/2011/01/export-and-importcreate-site-columns-in.html


Note: If you want to export all Site Content Types then comment out the following like below

 ##if ($_.Group -eq "$contentTypesGroup") {
        Add-Content $xmlFilePath $_.SchemaXml
   ## }

#>

Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

#### Start Variables ####
$sourceWeb = Get-SPWeb "http://YourSiteName.com"
$xmlFilePath = "C:\BoxBuild\Scripts\ContentTypesExport.xml"
$contentTypesGroup = "YourCustomGroup"
#### End Variables ####

#Create Export File
New-Item $xmlFilePath -type file -force

#Export Content Types to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "`n<ContentTypes>"
$sourceWeb.ContentTypes | ForEach-Object {
    if ($_.Group -eq "$contentTypesGroup") {
        Add-Content $xmlFilePath $_.SchemaXml
    }
}
Add-Content $xmlFilePath "</ContentTypes>"

$sourceWeb.Dispose()