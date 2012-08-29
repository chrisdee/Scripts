## =====================================================================
## Title       : Display-SPList
## Description : Displays All Lists
## Author      : Idera
## Date        : 24/11/2009
## Input       : Display-SPList [[-url] <String>]
## Output      : 
## Usage       : Display-SPList -url http://moss
## Notes       : Adapted From Niklas Goude Script
## Tag         : List, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Display-SPList -url $url
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Display-SPList([string]$url) {
	
	$OpenWeb = Get-SPWeb $url

	$OpenWeb.Lists | Select Title, ItemCount,Description

	$OpenWeb.Dispose()
}

main