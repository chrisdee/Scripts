##################################################################################
#
#
#  Script name: Set-SPImageWebPart.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$WebPart, [string]$Image, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Set-SPImageWebPart
Copies the image to the SharePoint Template/Image folder
And Adds the Image to a Image WebPart

PARAMETERS: 
-url		Url to SharePoint Site
-WebPart	Name of Image WebPart
-Image		Full Path To New Image

SYNTAX:

Set-SPImageWebPart -url http://moss -WebPart "Site Image" -Image "C:\Demo\Files\PowerShell.jpg"

Sets PowerShell.jpg as Image in the "Site Image" Web Part

Set-SPImageWebPart -help

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

function Set-SPImageWebPart([string]$url, [string]$WebPart, [string]$Image){

	$ImageName = Split-Path $Image -leaf

	Copy-Item $Image -destination "C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\TEMPLATE\IMAGES" -Force

	$OpenWeb = Get-SPWeb $url
	$WebPartManager  = $OpenWeb.GetLimitedWebPartManager("$url/default.aspx?PageView=Shared", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
	$SiteImage = $WebPartManager.WebParts | Where { $_.Title -match $WebPart }
	$SiteImage.ImageLink = "/_layouts/images/$ImageName"
	$WebPartManager.SaveChanges($SiteImage)

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $WebPart -AND $Image) { Set-SPImageWebPart -url $url -WebPart $WebPart -Image $Image }