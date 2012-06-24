##################################################################################
#
#
#  Script name: Add-SPListToQuickLaunch.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$Url, [string]$List, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPListToQuickLaunch
Adds A List to The QuickLaunch Bar

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name

SYNTAX:

Add-SPListToQuickLaunch -url http://moss -List Users

Adds The List Users to the QuickLaunchBar

Add-SPListToQuickLaunch -help

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

function Add-SPListToQuickLaunch([string]$url, [string]$List) {

	$OpenWeb = Get-SPWeb $url

	$CustomList = $OpenWeb.Lists[$List]

	$CustomList.OnQuickLaunch = $true
	$CustomList.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List) { Add-SPListToQuickLaunch -url $url -List $List }