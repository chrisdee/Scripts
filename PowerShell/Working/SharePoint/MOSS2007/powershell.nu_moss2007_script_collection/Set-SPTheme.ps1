##################################################################################
#
#
#  Script name: Set-SPTheme.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$Url, [string]$Theme, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Set-SPTheme
Changes Theme

PARAMETERS: 
-url		Url to SharePoint Site
-Theme		New Theme

SYNTAX:

Set-SPTheme -Url http://moss -Theme obsidian

Changes Theme to Obsidian

Set-SPTheme -help

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

function Set-SPTheme([string]$url, [string]$Theme) {

	$OpenWeb = Get-SPWeb $url
	$OpenWeb.ApplyTheme($Theme)
	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Theme) { Set-SPTheme -url $url -Theme $Theme }