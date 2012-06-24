##################################################################################
#
#
#  Script name: Get-SPItem.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Item, [string]$Field  = ("Title"), [switch]$All, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Get-SPItem
Gets An SP Item

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-Item		Name of the Item
-Field		Field to Check
-All		Returns All Items In List

SYNTAX:

$Item = Get-SPItem  -url http://moss -List Users -Item "User1"

Gets the Item where Title is eq to User1

$Item = Get-SPItem  -url http://moss -List Users -Item "user@mail.com" -Field mail

Gets the Item where the Field mail is eq to User@mail.com

$AllItems = Get-SPItem -url http://moss -List Users -All

Gets All Items from The List

Get-SPItem -help

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

function Get-SPItem([string]$url, [string]$List, [string]$Item, [string]$Field  = ("Title"), [switch]$All) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	if($All) {
		$OpenItem = $OpenList.Items
	} else {
		$OpenItem = $OpenList.Items | Where { $_[$Field] -eq $Item }
	}

	return $OpenItem

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List) { 
	if($All) { 
		Get-SPItem -url $url -List $List -All
	} elseif($Item) {
		Get-SPItem -url $url -List $List -Item $Item -Field $Field
	} else { }
}