## SharePoint Server: PowerShell Script to Export Site Columns Groups to an XML File ##

<#

Overview: Script that exports Site Columns to an XML file. These exports can be filtered on Column Group names

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables below to match your environment and run the script

Resources: 

http://get-spscripts.com/2011/01/export-and-importcreate-site-columns-in.html
http://get-spscripts.com/2011/02/export-and-importcreate-site-content.html

Note: If you want to export all Site Columns then comment out the following like below

##if ($_.Group -eq "$columnGroup") {
        Add-Content $xmlFilePath $_.SchemaXml
   ## }

#>

#### Start Variables ####
$sourceWeb = Get-SPWeb "https://YourSharePointSite.com"
$xmlFilePath = "C:\BoxBuild\Scripts\SiteColumnsExport.xml"
$siteColumnsGroup = "YourCustomGroup"
#### End Variables ####

Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

#Create Export Files
New-Item $xmlFilePath -type file -force

#Export Site Columns to XML file
Add-Content $xmlFilePath "<?xml version=`"1.0`" encoding=`"utf-8`"?>"
Add-Content $xmlFilePath "`n<Fields>"
$sourceWeb.Fields | ForEach-Object {
   if ($_.Group -eq "$siteColumnsGroup") {
        Add-Content $xmlFilePath $_.SchemaXml
    }
}
Add-Content $xmlFilePath "</Fields>"

$sourceWeb.Dispose()