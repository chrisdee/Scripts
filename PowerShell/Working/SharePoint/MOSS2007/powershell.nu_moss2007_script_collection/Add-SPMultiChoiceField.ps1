##################################################################################
#
#
#  Script name: Add-SPMultiChoiceField.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [string]$Description, [Array]$Choices, [switch]$Required, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPMultiChoiceField
Adds a Multiple Choice Field to a SP List

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-Name		Name of the Field
-Description	Field Description
-Choices	Array of Choices
-Required	Boolean Value, If True, Field will be Required

SYNTAX:

Add-SPMultiChoiceField -url http://moss -List Users -Name Department -Description "Users Department" -Choices $("HR","Production","IT","Marketing","Sales")

Adds A Multiple Choice Field to the Department List. Adds the Following Choices:
HR
Production
IT
Marketing
Sales

Add-SPMultiChoiceField -help

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

function Add-SPMultiChoiceField([string]$url, [string]$List, [string]$Name, [string]$Description, [Array]$Choices, [switch]$Required) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$StringCollection = New-Object System.Collections.Specialized.StringCollection

	$Choices | ForEach {
		[void]$StringCollection.Add($_)
	}

	[void]$OpenList.Fields.Add($Name, [Microsoft.SharePoint.SPFieldType]::MultiChoice, $Required, $False, $StringCollection)
	$OpenList.Fields[$Name].Description = $Description
	$OpenList.Fields[$Name].Update()	

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }

if($url -AND $List -AND $Name -AND $Description -AND $Choices) {
	if($Required) {
		Add-SPMultiChoiceField -url $url -List $List -Name $Name -Description $Description -Choices $Choices -Required
	} else {
		Add-SPMultiChoiceField -url $url -List $List -Name $Name -Description $Description -Choices $Choices
	}
}