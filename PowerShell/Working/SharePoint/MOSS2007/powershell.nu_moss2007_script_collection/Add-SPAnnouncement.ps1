##################################################################################
#
#
#  Script name: Add-SPAnnouncement.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Title, [string]$Body, [DateTime]$Expires, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Get-SPWeb
Opens a connection a site that holds web contents

PARAMETERS: 
-url		Url to SharePoint Site
-List		Name of List
-Title		Title of Announcement
-Body		Body of Announcement
-Date		Date of Announcement

SYNTAX:

Add-SPAnnouncement

Add-SPAnnouncement -url http://moss -List "Announcements" -Title "Demo från PowerShell.nu" -Body "<h1>PowerShell</h1><p />is Cool!" -Expires (Get-Date).AddHours(1)

Adds A new Announcement to the Announcements List

Add-SPAnnouncement -help

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

function Add-SPAnnouncement ([string]$url, [string]$List, [string]$Title, [string]$Body, [DateTime]$Expires) {

	$OpenWeb = Get-SPWeb $url

	$Announcement = $OpenWeb.Lists[$List]

	$NewItem = $Announcement.Items.Add()
	$NewItem["Title"] = $Title
	$NewItem["Body"] = $Body
	$NewItem["Expires"] = $Expires
	$NewItem.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Title -AND $Body -AND $Expires) { Add-SPAnnouncement -url $url -List $List -Title $Title -Body $Body -Expires $Expires }