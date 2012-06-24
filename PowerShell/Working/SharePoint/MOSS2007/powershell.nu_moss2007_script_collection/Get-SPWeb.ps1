##################################################################################
#
#
#  Script name: Get-SPWeb.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$Url, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Get-SPWeb
Opens a connection a site that holds web contents

PARAMETERS: 
-url		Url to SharePoint Site

SYNTAX:

$SPWeb = Get-SPWeb -url http://moss

Opens The SiteCollection.

Get-SPWeb -help

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

if($help) { GetHelp; Continue }
if($url) { Get-SPWeb -url $url }