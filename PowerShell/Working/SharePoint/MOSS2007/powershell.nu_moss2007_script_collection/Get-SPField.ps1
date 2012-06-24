##################################################################################
#
#
#  Script name: Get-SPField.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Get-SPField
Gets a SP Field

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-Name		Name of the Field

SYNTAX:

$Field = Get-SPField -url http://moss -List Users -Name Title

Gets The Title Field from the Custom List Users

Get-SPField -help

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

function Get-SPField([string]$url, [string]$List, [string]$Name) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$Field = $OpenList.Fields[$Name]

	return $Field

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Name) { Get-SPField -url $url -List $List -Name $Name }