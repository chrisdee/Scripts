##################################################################################
#
#
#  Script name: Remove-SPField.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Field, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Remove-SPField
Removes A Field From A List

PARAMETERS: 
-url		Url to SharePoint Site
-List		Name of Document Library
-Field		Field to check, Default set to Title

SYNTAX:

Remove-SPField -url http://moss -List "Shared Documents" -Field "Document Type"

Removes The Document Type Field From the List "Shared Documents

Remove-SPField -help

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

function Remove-SPField([string]$url, [string]$List, [string]$Field) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	$OpenField = $OpenList.Fields[$Field]
	$OpenField.Delete()
	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Field) { Remove-SPField -url $url -List $List -Field $Field }