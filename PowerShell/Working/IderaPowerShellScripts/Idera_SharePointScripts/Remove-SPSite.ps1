## =====================================================================
## Title       : Remove-SPSite
## Description : Removes a site from the Site Collection
## Author      : Idera
## Date        : 24/11/2009
## Input       : Remove-SPSite [[-url] <String>]
## Output      : 
## Usage       : Remove-SPSite -url http://moss/IT
## Notes       : Adapted From Niklas Goude Script
## Tag         : Site, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss/SiteName]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	Remove-SPSite -url $url
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	$SPSite.OpenWeb()
}

function Remove-SPSite([string]$url) {
	$OpenWeb = Get-SPWeb $url

	if($OpenWeb.Navigation.UseShared) {
		if(($OpenWeb.ParentWeb.Navigation.TopNavigationBar | Where { $_.Title -eq $OpenWeb.Title }) -ne $Null) {
			($OpenWeb.ParentWeb.Navigation.TopNavigationBar | Where { $_.Title -eq $OpenWeb.Title }).Delete()
		}

		if(($OpenWeb.ParentWeb.Navigation.QuickLaunch | Where { $_.Title -eq "Sites" }) -ne $Null) {
			(($OpenWeb.ParentWeb.Navigation.QuickLaunch | Where { $_.Title -eq "Sites" }).Children | Where { $_.Title -eq $OpenWeb.Title }).Delete()
		}
	}

	$OpenWeb.Delete()
	$OpenWeb.Dispose()
}

main