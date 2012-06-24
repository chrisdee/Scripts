##################################################################################
#
#
#  Script name: Add-SPFieldToView.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Field, [string]$View, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPFieldToView
Adds a Field To A View

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-View		Name of the View

SYNTAX:

Add-SPFieldToView -url http://moss -List Computers -Field Model -View "All Items"

Adds the Field Model to the "All Items" View

Add-SPFieldToView -help

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

function Add-SPFieldToView([string]$url, [string]$List, [string]$Field, [string]$View) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$OpenField = $OpenList.Fields[$Field]
	$OpenView = $OpenList.Views[$View]

	[void]$OpenView.ViewFields.Add($Field)
	$OpenView.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Field -AND $View) { Add-SPFieldToView -url $url -List $List -Field $Field -View $View }