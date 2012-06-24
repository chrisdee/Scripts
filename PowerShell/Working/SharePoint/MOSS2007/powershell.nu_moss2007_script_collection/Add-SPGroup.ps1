##################################################################################
#
#
#  Script name: Add-SPGroup.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$Group, [string]$Role, [string]$Owner, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPGroup
Adds a New SharePoint Group

PARAMETERS: 
-url		Url to SharePoint Site
-Group		Name of New Group
-Role		Role Of New Group
-Owner		Group Owner

SYNTAX:

Add-SPGroup -url http://moss -Group "New Group" -Role Read -Owner "powershell\administrator"

Adds the Group "New Group" to the Site.

Add-SPSGroup -help

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

function Add-SPGroup ([string]$url, [string]$Group, [string]$Role, [string]$Owner) {

	$SPSite = Get-SPSite $url
	$OpenWeb = Get-SPWeb $url

	$OpenWeb.SiteGroups.Add($Group,$SPSite.RootWeb.AllUsers[$Owner], $Null, $Group)
	$CurrentGroup = $OpenWeb.SiteGroups[$Group]
	$OpenWeb.Roles[$Role].AddGroup($CurrentGroup)

	$OpenWeb.Dispose()
}
if($help) { GetHelp; Continue }
if($url -AND $Group -AND $Role -AND $Owner) { Add-SPGroup -url $url -Group $Group -Role $Role -Owner $Owner }