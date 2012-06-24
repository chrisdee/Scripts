##################################################################################
#
#
#  Script name: Set-SPQuickLaunchOrder.ps1
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
NAME: Set-SPQuickLaunchOrder
Moves A List to the Top of The QuickLaunch

PARAMETERS: 
-url		Url to SharePoint Site

SYNTAX:

Set-QuickLaunchOrder -url http://moss -List Users

Moves the Users List to the Top of The WuickLaunch Bar

Set-QuickLaunchOrder -help

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

function Set-SPQuickLaunchOrder([string]$url, [string]$List) {

	$OpenWeb = Get-SPWeb $url

	$QuickLaunch = $OpenWeb.Navigation.QuickLaunch

	$Lists = $QuickLaunch | Where { $_.Title -match "Lists" }

	$MoveList = $Lists.Children | Where { $_.Title -match $List }
	$MoveList.MoveToFirst($Lists.Children)

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List) { Set-SPQuickLaunchOrder -url $url -List $List }