##################################################################################
#
#
#  Script name: Add-SPList.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$Name, [string]$Description, [string]$Type, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPList
Creates a New SharePoint List

PARAMETERS: 
-url		Url to SharePoint Site
-Name		Name of the New List
-Description	List Description
-Type		Type of List

SYNTAX:

Add-SPList -url http://moss -Name Users -Description "Company Users" -Type "Custom List"

Adds A Custom List to SharePoint.

Add-SPList -help

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

function Add-SPList([string]$url, [string]$Name, [string]$Description, [string]$Type) {
	
	$OpenWeb = Get-SPWeb $url
	$TemplateType = $OpenWeb.ListTemplates[$Type]

	[void]$OpenWeb.Lists.Add($Name, $Description, $TemplateType)

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Name -AND $Description -AND $Type) { Add-SPList -url $url -Name $Name -Description $Description -Type $Type }