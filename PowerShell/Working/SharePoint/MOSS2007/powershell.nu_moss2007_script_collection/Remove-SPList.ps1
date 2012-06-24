##################################################################################
#
#
#  Script name: Remove-SPList.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Remove-SPList
Removes A List

PARAMETERS: 
-url		Url to SharePoint Site
-List		Name of Document Library

SYNTAX:

Remove-SPList -url http://moss -List "Users"

Removes The Users list from the site http://moss

Remove-SPList -help

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

function Remove-SPField([string]$url, [string]$List) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	$OpenList.Delete()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List) { Remove-SPField -url $url -List $List }