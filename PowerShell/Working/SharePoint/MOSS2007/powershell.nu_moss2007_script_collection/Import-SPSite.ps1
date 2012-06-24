##################################################################################
#
#
#  Script name: Import-SPSite.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$File, [string]$Location, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Import-SPSite
Restores a Site from a Backup File

PARAMETERS: 
-url		Url to SharePoint Site
-File		File Name
-Location	File Location

SYNTAX:

Import-SPSite -url http://moss -file Backup.bak -Location C:\Backup\

Restores the site from the Backup File C:\Backup\Backup.bak

Import-SPSite -help

Displays the help topic for the script

"@
$HelpText

}

function Import-SPSite([string]$url, [string]$File, [string]$Location) {

	$SPImport = New-Object Microsoft.SharePoint.Deployment.SPImport
	$SPImport.Settings.SiteUrl= $url
	$SPImport.Settings.BaseFilename = $File
	$SPImport.Settings.FileLocation = $Location
	$SPImport.Settings.IncludeSecurity = "All"
	$SPImport.Run()

	$SPImport.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $File -AND $Location) { Import-SPSite -url $url -File $File -Location $Location }