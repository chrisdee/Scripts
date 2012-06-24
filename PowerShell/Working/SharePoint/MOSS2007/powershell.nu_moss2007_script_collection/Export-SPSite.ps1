##################################################################################
#
#
#  Script name: Export-SPSite.ps1
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
NAME: Export-SPSite
Exports a Site to a Backup File

PARAMETERS: 
-url		Url to SharePoint Site
-File		File Name
-Location	File Location

SYNTAX:

Export-SPSite -url http://moss -file Backup.bak -Location C:\Backup\

Exports a Backup of the Site to C:\Backup\Backup.bak

Export-SPSite -help

Displays the help topic for the script

"@
$HelpText

}

function Export-SPSite([string]$url, [string]$File, [string]$Location) {

	if(Test-Path $Location) {

	} else {
		new-item -path $Location -type directory | Out-Null
	}

	$SPExport = New-Object Microsoft.SharePoint.Deployment.SPExport

	$SPExport.Settings.SiteUrl= $url
	$SPExport.Settings.BaseFilename = $File
	$SPExport.Settings.FileLocation = $Location
	$SPExport.Settings.IncludeSecurity = "All"
	$SPExport.Run()

	$SPExport.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $File -AND $Location) { Export-SPSite -url $url -File $File -Location $Location }