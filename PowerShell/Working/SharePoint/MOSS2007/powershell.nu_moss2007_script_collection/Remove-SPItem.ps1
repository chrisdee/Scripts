##################################################################################
#
#
#  Script name: Remove-SPItem.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [string]$Field = ("Title"), [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Remove-SPItem
Removes An Item From a List

PARAMETERS: 
-url		Url to SharePoint Site
-List		Name of Document Library
-Name		Item Name
-Field		Field to check, Default set to Title

SYNTAX:

Remove-SPItem -url http://moss -List Users -name nigo

Removes the item nigo from the Users List

Remove-SPItem -url http://moss -List Users -name "IT Consultant" -Field Description

Removes the Item Where the Field Description is equal to "IT Consultant"

Opens The SiteCollection.

Remove-SPItem -help

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

function Remove-SPItem([string]$url, [string]$List, [string]$Name, [string]$Field = ("Title")) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	if($OpenList.Items | Where { $_[$Field] -eq $Name }) {
		$Item = $OpenList.Items | Where { $_[$Field] -eq $Name }
		$Item.Delete()
	} else {
		Write-Host "Item $Item Not Found"
	}
	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Name) { Remove-SPItem -url $url -List $List -Name $Name -Field $Field }