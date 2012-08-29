## =====================================================================
## Title       : Remove-SPList
## Description : Removes A List
## Author      : Idera
## Date        : 24/11/2009
## Input       : Remove-SPList [[-url] <String>] [[-List] <String>]
## Output      : 
## Usage       : Remove-SPList -url http://moss -List "Users"
## Notes       : Adapted From Niklas Goude Script
## Tag         : List, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$List = "$(Read-Host 'List Name [e.g. My List]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Remove-SPField -url $url -List $List
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Remove-SPField([string]$url, [string]$List) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	$OpenList.Delete()

	$OpenWeb.Dispose()
}

main