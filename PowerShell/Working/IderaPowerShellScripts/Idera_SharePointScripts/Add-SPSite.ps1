## =====================================================================
## Title       : Add-SPSite
## Description : Adds a New SharePoint Site.
## Author      : Idera
## Date        : 24/11/2009
## Input       : Add-SPSite [[-url] <String>] [[-WebUrl] <String>] [[-Title] <String>] [[-Description] <String>] [[-Template] <String>]
## Output      : 
## Usage       : Add-SPSite -url http://moss -weburl "IT" -Title "Information Technology" -Description "IT Department" -Template "STS#0"
## Notes       : Adapted From Niklas Goude Script
## Tag         : Site, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$WebUrl = "$(Read-Host 'New site Name [e.g. NewSite]')",
   [string]$Title = "$(Read-Host 'Title of New Site [e.g. My New Site]')",
   [string]$Description = "$(Read-Host 'New Sites Description [e.g. My New Site]')",
   [string]$Template = "$(Read-Host 'Template to use [e.g. STS#0]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	$SPSite = Get-SPSite $url
	$ValidChoices = ($SPSite.GetWebTemplates(1033) | Select Name) | ForEach { $_.Name }
	$DisplayValidChoices = $SPSite.GetWebTemplates(1033) | Select Name, Description

	$SPSite.Dispose()

	if($ValidChoices -eq $Template) {

		Add-SPSite -url $url -Weburl $Weburl -Title $Title -Description $Description -Template $Template

	} else {
		Write-Host "$Template is not a Valid Template, Please Choose one of the Following" -ForeGroundColor Red
		$DisplayValidChoices
	}
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	$SPSite.OpenWeb()
}

function Add-SPSite([string]$url,[string]$Weburl, [string]$Title, [string]$Description, [string]$Template) {

	$SPSite = Get-SPSite $url
	$OpenWeb = Get-SPWeb $url

	if($SPSite.AllWebs | Where { $_.Title -eq $Title}) {

		Write-Host "Site: $($Title) Already Exists." -ForeGroundColor Red

	} else {

		[void]$SPSite.AllWebs.Add($Weburl, $Title, $Description, [int]1033, $Template, $FALSE, $FALSE)

		$Node = New-Object Microsoft.SharePoint.Navigation.SPNavigationNode $Title, $($url + "/" + $Weburl), 1

		if($OpenWeb.Navigation.TopNavigationBar -ne $Null) {
			$TopNav = $OpenWeb.Navigation.TopNavigationBar
			[void]$TopNav.AddAsLast($Node)
		}

		if(($OpenWeb.Navigation.QuickLaunch | Where { $_.Title -match "Sites" }) -ne $Null) {
			$QuickLaunch = $OpenWeb.Navigation.QuickLaunch | Where { $_.Title -match "Sites" }
			[void]$QuickLaunch.Children.AddAsLast($Node)
		}	

		$OpenSite = $SPSite.OpenWeb($Weburl)
		$OpenSite.Navigation.UseShared = $True
	}

	$OpenWeb.Dispose()
	$SPSite.Dispose()
}

main