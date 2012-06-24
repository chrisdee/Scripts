##################################################################################
#
#
#  Script name: Add-SPSitePermission.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$Group, [string]$Permission, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPSitePermission
Adds Unique Site Permissions to a Group

PARAMETERS: 
-url		Url to SharePoint Site
-Group		Name of New Group
-Permission	Permission

SYNTAX:

Add-SPSitePermission -url "http://moss/IT" -Group "IT Management" -Permission "FullMask"

Gives the Group "IT Management" Full Rights on the Site http://moss/IT

Opens The SiteCollection.

Add-SPSitePermission -help

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

function Add-SPSitePermission ([string]$url, [string]$Group, [string]$Permission) {

	$OpenWeb = Get-SPWeb $url
	$OpenWeb.Permissions.Add($OpenWeb.Groups[$Group], $Permission)

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Group -AND $Permission) { Add-SPSitePermission -url $url -Group $Group -Permission $Permission }