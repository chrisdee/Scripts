##################################################################################
#
#
#  Script name: Get-SPList.ps1
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
NAME: Get-SPList
Gets a SPList

PARAMETERS: 
-url		Url to SharePoint Site

SYNTAX:

$SPList = Get-SPList -url http://moss -List Users

Gets The SP List "Users".

Get-SPList -help

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

function Get-SPList([string]$url, [string]$List) {
	
	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	return $OpenList

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List) { Get-SPList -url $url -List $List}