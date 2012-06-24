##################################################################################
#
#
#  Script name: Add-SPTextField.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [string]$Description, [switch]$Required, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPTextField
Adds a Text Field to a SP List

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-Name		Name of the Field
-Description	Field Description
-Required	Boolean Value, If True, Field will be Required

SYNTAX:

Add-SPTextField -url http://moss -List Users -Name Description -Description "Users Description"

Adds the Description Field to The Users List

Add-SPTextField -help

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

function Add-SPTextField([string]$url, [string]$List, [string]$Name, [string]$Description, [switch]$Required) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	[void]$OpenList.Fields.Add($Name, "Text", $Required)
	$OpenList.Fields[$Name].Description = $Description
	$OpenList.Fields[$Name].Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }

if($url -AND $List -AND $Name -AND $Description) {
	if($Required) {
		Add-SPTextField -url $url -List $List -Name $Name -Description $Description -Required
	} else {
		Add-SPTextField -url $url -List $List -Name $Name -Description $Description
	}
}