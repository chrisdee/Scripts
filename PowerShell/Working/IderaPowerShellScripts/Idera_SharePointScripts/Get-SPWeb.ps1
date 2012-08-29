## =====================================================================
## Title       : Get-SPWeb
## Description : Gets a SP WebSite
## Author      : Idera
## Date        : 24/11/2009
## Input       : Get-SPWeb [[-url] <String>]
## Output      : 
## Usage       : Get-SPWeb -url http://moss
## Notes       : Adapted From Niklas Goude Script
## Tag         : Site, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Get-SPWeb -url $url
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

main