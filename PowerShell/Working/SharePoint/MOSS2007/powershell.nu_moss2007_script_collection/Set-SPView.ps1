##################################################################################
#
#
#  Script name: Set-SPView.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$Url, [string]$List, [string]$View, [string]$Query, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Set-SPView
Gets A SP View

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-View		Name of the View
-Query		Query to set the View

SYNTAX:

Set-SPView -url http://moss -List "Shared Documents" -View "All Documents" -Query '<GroupBy Collapse="TRUE" GroupLimit="100"><FieldRef Name="Document_x0020_Type" /></GroupBy><OrderBy><FieldRef Name="FileLeafRef" /></OrderBy>'

Sets The "All Documents" View to Group by the "Document Type" Custom Field.

Set-SPView -help

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

function Set-SPView([string]$url, [string]$List, [string]$View, [string]$Query ) {

	$OpenWeb = Get-SPWeb $url

	$OpenList = $OpenWeb.Lists[$List]

	$OpenView = $OpenList.Views[$View]
	$OpenView.Query = $Query
	$OpenView.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $View -AND $Query) { Set-SPView -url $url -List $List -View $View -Query $Query }