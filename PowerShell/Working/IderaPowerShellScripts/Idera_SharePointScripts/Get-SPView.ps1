## =====================================================================
## Title       : Get-SPView
## Description : Gets A SP View
## Author      : Idera
## Date        : 24/11/2009
## Input       : Get-SPView [[-url] <String>] [[-List] <String>] [[-View] <String>]
## Output      : 
## Usage       : Get-SPView -url http://moss -List "Shared Documents" -View "All Documents"
## Notes       : Adapted From Niklas Goude Script
## Tag         : View, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$List = "$(Read-Host 'List Name [e.g. Shared Documents]')", 
   [string]$View = "$(Read-Host 'View Name [e.g. All Documents]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Get-SPView -url $url -List $List -View $View

}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Get-SPView([string]$url, [string]$List, [string]$View) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$OpenView = $OpenList.Views[$View]

	return $OpenView

	$OpenWeb.Dispose()
}

main