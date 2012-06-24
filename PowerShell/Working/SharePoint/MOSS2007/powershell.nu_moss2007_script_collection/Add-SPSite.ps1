##################################################################################
#
#
#  Script name: Add-SPSite.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url,[string]$Weburl, [string]$Title, [string]$Description, [string]$Template, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPSite
Adds a New SharePoint Site

PARAMETERS: 
-url		Url to SharePoint Site
-Weburl		New site Name
-Title		Title of New Site
-Description	New Sites Description
-Template	Template to use

SYNTAX:

Add-SPSite -url http://moss -weburl "IT" -Title "Information Technology" -Description "IT Department" -Template "STS#0"

Adds the Site "IT" to http://moss

Add-SPSite -help

Displays the help topic for the script

"@
$HelpText

}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Add-SPSite([string]$url,[string]$Weburl, [string]$Title, [string]$Description, [string]$Template) {

	$SPSite = Get-SPSite $url
	$OpenWeb = Get-SPWeb $url

	$TopNav = $OpenWeb.Navigation.TopNavigationBar
	$QuickLaunch = $OpenWeb.Navigation.QuickLaunch | Where { $_.Title -match "Sites" }

	[void]$SPSite.AllWebs.Add($Weburl, $Title, $Description, [int]1033, $Template, $FALSE, $FALSE)

	$node = New-Object Microsoft.SharePoint.Navigation.SPNavigationNode $Title, $($url + "/" + $Weburl), 1
	[void]$QuickLaunch.Children.AddAsLast($node)
	[void]$TopNav.AddAsLast($Node)

	$OpenSite = $SPSite.OpenWeb($Weburl)
	$OpenSite.Navigation.UseShared = $True

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Weburl -AND $Title -AND $Description -AND $Template) { Add-SPSite -url $url -Weburl $Weburl -Title $Title -Description $Description -Template $Template }