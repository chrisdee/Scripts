##################################################################################
#
#
#  Script name: Add-SPLink.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Link, [string]$Description, [string]$Notes, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPLink
Adds a new Link to the Links List

PARAMETERS: 
-url		Url to SharePoint Site
-List		Name of List
-Link		Url to Linked Page
-Description	Description of Link
-Notes		Additional NOtes

SYNTAX:

Add-SPLink -url http://moss -List "Links" -Link "http://www.powershell.nu" -Description "PowerShell.nu - Blog" -Notes "PowerShell Blog"

Adds a New Link to SharePoint Links List

Add-SPLink -help

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

function Add-SPLink([string]$url, [string]$List, [string]$Link, [string]$Description, [string]$Notes) {

	$OpenWeb = Get-SPWeb $url

	$Links = $OpenWeb.Lists[$List]

	$NewItem = $Links.Items.Add()
	$NewItem["URL"] = "$Link, $Description"
	$NewItem["Notes"] = $Notes
	$NewItem.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Link -AND $Description -AND $Notes) { Add-SPLink -url $url -List $List -Link $Link -Description $Description -Notes $Notes }