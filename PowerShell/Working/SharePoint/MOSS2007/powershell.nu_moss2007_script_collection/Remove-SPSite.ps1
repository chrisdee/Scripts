##################################################################################
#
#
#  Script name: Remove-SPSite.ps1
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
NAME: Remove-SPSite
Removes a site from the Site Collection

PARAMETERS: 
-url		Url to SharePoint Site

SYNTAX:

Remove-SPSite -url http://moss/IT

Removes the Site "IT" from the Site Collection

Remove-SPSite -help

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

function Remove-SPSite([string]$url) {
	$OpenWeb = Get-SPWeb $url

	if($OpenWeb.Navigation.UseShared) {
		($OpenWeb.ParentWeb.Navigation.TopNavigationBar | Where { $_.Title -eq $OpenWeb.Title }).Delete()
		(($OpenWeb.ParentWeb.Navigation.QuickLaunch | Where { $_.Title -eq "Sites" }).Children | Where { $_.Title -eq $OpenWeb.Title }).Delete()
	}

	$OpenWeb.Delete()
	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url) { Remove-SPSite -url $url }