##################################################################################
#
#
#  Script name: Add-SPFolder.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPFolder
Adds A Folder to a Document Library.

PARAMETERS: 
-url		Url to SharePoint Site
-List		Name of Document Library
-Name		Folder Name

SYNTAX:

Add-SPFolder -Url http://moss -List "Shared Documents" -Name "New Folder"

Adds A New Folder to the Shared Documents Folder

Add-SPFolder -help

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

function Add-SPFolder([string]$url, [string]$List, [string]$Name) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]
	$Folder = $OpenList.Folders.Add("",[Microsoft.SharePoint.SPFileSystemObjectType]::Folder,$Name)
	$Folder.Update()

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Name) { Add-SPFolder -url $url -List $List -Name $Name }