##################################################################################
#
#
#  Script name: Add-SPMultiLookupField.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [string]$Description, [String]$LookupList, [string]$LookupField, [switch]$Required, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPMultiLookupField
Adds a Multiple Lookup Field to a SP List

PARAMETERS: 
-url			Url to SharePoint Site
-List			List Name
-Name			Name of the Field
-Description		Field Description
-LookupList		Lookup List Name
-LookupField		If Specified, Lookup Will Display this Field Instead, Default set to ItemName
-Required		Boolean Value, If True, Field will be Required

SYNTAX:

Add-SPMultiLookupField -url http://moss -List Users -Name Computer -Description "Users Computer" -LookupList Computers

Adds a Lookup Field in the Users List pointing to the Computers List

Add-SPMultiLookupField -help

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

function Add-SPMultiLookupField([string]$url, [string]$List, [string]$Name, [string]$Description, [String]$LookupList, [string]$LookupField, [switch]$Required) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$Lookup = $OpenWeb.Lists[$LookupList]

	[void]$OpenList.Fields.AddLookup($Name,$Lookup.ID,$Required)

	$OpenList.Fields[$Name].Description = $Description

	if($LookupField) {
		$OpenList.Fields[$Name].LookupField = $LookupField
	}

	$OpenList.Fields[$Name].AllowMultipleValues = $True

	$OpenList.Fields[$Name].Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }

if($url -AND $List -AND $Name -AND $Description -AND $LookupList) {
	if($Required) {
		if($LookupField) {
			Add-SPMultiLookupField -url $url -List $List -Name $Name -Description $Description -LookupList $LookupList -LookupField $LookupField -Required
		} else {
			Add-SPMultiLookupField -url $url -List $List -Name $Name -Description $Description -LookupList $LookupList -Required
		}
	} else {
		if($LookupField) {
			Add-SPMultiLookupField -url $url -List $List -Name $Name -Description $Description -LookupList $LookupList -LookupField $LookupField
		} else {
			Add-SPMultiLookupField -url $url -List $List -Name $Name -Description $Description -LookupList $LookupList
		}
	}
}