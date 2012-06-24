##################################################################################
#
#
#  Script name: Upload-SPDocument.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$Folder, [string]$Document, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Upload-SPDocument
Uploads a Document to SharePoint

PARAMETERS: 
-url		Url to SharePoint Site
-Folder		Name of Document Folder
-Document	Path to Document

SYNTAX:

Upload-SPDocument -url http://moss -Folder "Shared Documents" -Document "C:\Demo\Files\Excel SpreadSheet.xlsx"

Uploads the Excel Document to The "Shared Folders"

Upload-SPDocument -help

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

function Upload-SPDocument([string]$url, [string]$Folder, [string]$Document) {

	$OpenWeb = Get-SPWeb $url

	$DocumentName = Split-Path $Document -Leaf
	$GetFolder = $OpenWeb.GetFolder($Folder)

	[void]$GetFolder.Files.Add("$Folder/$DocumentName",$((gci $Document).OpenRead()),"")

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Folder -AND $Document) { Upload-SPDocument -url $url -Folder $Folder -Document $Document }