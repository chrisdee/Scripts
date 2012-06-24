##################################################################################
#
#
#  Script name: Add-SPCalendar.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Title, [string]$Location, [string]$Description, [DateTime]$StartTime, [DateTime]$EndTime, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPCalendar
Adds A new Calendar Appointment

PARAMETERS: 
-url		Url to SharePoint Site Collection
-List		Name of List
-Title		Title of Calendar Entry
-Location	Location
-Description	Descrpition of Calendar Entry
-StartTime	StartTime
-EndTime	EndTime

SYNTAX:

Add-SPCalendar -url http://moss -List "Calendar" -Title "SharePoint - PowerShell Demo" -Location "Stockholm" -Description "PowerShell Demo" -StartTime (Get-Date) -EndTime (Get-Date).AddHours(4)

Adds A New Calendar Entry

Get-SPCalendar -help

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

function Add-SPCalendar ([string]$url, [string]$List, [string]$Title, [string]$Location, [string]$Description, [DateTime]$StartTime, [DateTime]$EndTime) { 

	$OpenWeb = Get-SPWeb $url

	$Calendar = $OpenWeb.Lists[$List]
	$NewItem = $Calendar.Items.Add()
	$NewItem["Title"] = $Title
	$NewItem["Location"] = $Location
	$NewItem["Start Time"] = $StartTime
	$NewItem["End Time"] = $EndTime
	$NewItem["Description"] = $Description
	$NewItem.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Title -AND $Location -AND $Description -AND $StartTime -AND $EndTime) { Add-SPCalendar -url $url -List $List -Title $Title -Location $Location -Description $Description -StartTime $STartTime -EndTime $EndTime }