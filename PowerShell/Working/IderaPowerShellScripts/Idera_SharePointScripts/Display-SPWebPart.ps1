## =====================================================================
## Title       : Display-SPWebPart
## Description : Displays All WebParts
## Author      : Idera
## Date        : 24/11/2009
## Input       : Display-SPWebPart [[-url] <String>]
## Output      : 
## Usage       : Display-SPWebPart -url http://moss/MyTeamPlace
## Notes       : Adapted From Niklas Goude Script
## Tag         : Site, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Display-SPWebPart -url $url
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Display-SPWebPart([string]$url) {
	
	$OpenWeb = Get-SPWeb $url
	$WebPartManager  = $OpenWeb.GetLimitedWebPartManager("$url/default.aspx?PageView=Shared", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)

	$WebPartManager.WebParts | Select Title, Description

	$OpenWeb.Dispose()
}

main