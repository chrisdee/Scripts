##################################################################################
#
#
#  Script name: Get-SPView.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$Url, [string]$List, [string]$View, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Get-SPView
Gets A SP View

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-View		Name of the View

SYNTAX:

$View = Get-SPView -url http://moss -List "Shared Documents" -View "All Documents"

Gets The All Documents View.

Get-SPView -help

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

function Get-SPView([string]$url, [string]$List, [string]$View) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$OpenView = $OpenList.Views[$View]

	return $OpenView

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $View) { Get-SPView -url $url -List $List -View $View }