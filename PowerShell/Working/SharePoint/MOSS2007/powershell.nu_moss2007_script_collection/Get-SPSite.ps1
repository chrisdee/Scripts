##################################################################################
#
#
#  Script name: Get-SPSite.ps1
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
NAME: Get-SPSite
Opens a connection to a Microsoft.SharePoint.SPSite Collection

PARAMETERS: 
-url		Url to SharePoint Site Collection

SYNTAX:

$SPSite = Get-SPSite -url http://moss

Opens The SiteCollection.

Get-SPSite -help

Displays the help topic for the script

"@
$HelpText

}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

if($help) { GetHelp; Continue }
if($url) { Get-SPSite -url $url }