## =====================================================================
## Title       : Import-SPSite
## Description : Imports a Site to from a Backup File
## Author      : Idera
## Date        : 24/11/2009
## Input       : Import-SPSite [[-url] <String>] [[-File] <String>] [[-Location] <String>]
## Output      : 
## Usage       : Import-SPSite -url http://moss -file Backup.bak -Location C:\Backup\
## Notes       : Adapted From Niklas Goude Script
## Tag         : Site, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$File = "$(Read-Host 'Backup File Name [e.g. Backup.bak]')",
   [string]$Location = "$(Read-Host 'Backup File Location [e.g. C:\Backup\]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Import-SPSite -url $url -File $File -Location $Location
}

function Import-SPSite([string]$url, [string]$File, [string]$Location) {

	$SPImport = New-Object Microsoft.SharePoint.Deployment.SPImport
	$SPImport.Settings.SiteUrl= $url
	$SPImport.Settings.BaseFilename = $File
	$SPImport.Settings.FileLocation = $Location
	$SPImport.Settings.IncludeSecurity = "All"
	$SPImport.Run()
}

main