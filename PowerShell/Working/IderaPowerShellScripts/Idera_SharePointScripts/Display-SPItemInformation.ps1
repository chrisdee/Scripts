## =====================================================================
## Title       : Display-SPItemInformation
## Description : Displays Detailed Item Information
## Author      : Idera
## Date        : 24/11/2009
## Input       : Display-SPItemInformation [[-url] <String>] [[-List] <String>] [[-Item] <String>]
## Output      : 
## Usage       : Display-SPItemInformation -url http://moss -List Announcements -Item "My Item"
## Notes       : Adapted From Niklas Goude Script
## Tag         : Item, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')",
   [string]$List = "$(Read-Host 'List Name [e.g. Announcements]')",
   [string]$Item = "$(Read-Host 'Item Title Name [e.g. My Item]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Display-SPItemInformation -url $url -List $List -Item $Item
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Display-SPItemInformation([string]$url, [string]$List, [string]$Item) {
	
	$OpenWeb = Get-SPWeb $url

	$SelectString = ' $OpenWeb.Lists[$List].Items | Where { $_.Title -eq $Item } | Select '
	$OpenWeb.Lists[$List].Fields | Select Title -Unique | ForEach {
		$SelectString += '@{Name=' + '"' + $($_.Title) + '"' + ';Expression={$_["' + $($_.Title) + '"]}},'
	}
	$SelectString = $SelectString.TrimEnd(",")

	Invoke-Expression $SelectString

	$OpenWeb.Dispose()
}

main