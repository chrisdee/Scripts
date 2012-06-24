##################################################################################
#
#
#  Script name: Add-SPImageWebPart.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$Image, [string]$Name, [string]$BackgroundColor = ("Transparent"), [string]$Zone = ("Left"), [string]$Index = ("0"), [string]$VerticalAlignment = ("Middle"), [string]$HorizontalAlignment = ("Center"), [string]$ChromeType = ("Default"), [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPImageWebPart
Adds a New Image WebPart

PARAMETERS: 
-url		Url to SharePoint Site
-Image			Full Path To New Image
-Name			Title of WebPart
-BackgroundColor	WebPart BackgroundColor, Default set to Transparent
-Zone			Zone to place WebPart, Default set to Left
-Index			Index Position of WebPart, Default set to 0 ( Top )
-VerticalAlignment	Vertical Alignment of WebPart, Default set to Middle
-HorizontalAlignment 	Horizontal Alignment of WebPart, Default set to Center
-ChromeType		Chrome Type of WebPart, Default Set to Default

SYNTAX:

Add-SPImageWebPart -url http://moss/statistics -Name "My Image" -Image "C:\Demo\Files\3DPie.png" -ChromeType "None"

Adds a New Image WebPart to the Site.

Add-SPImageWebPart -help

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

function Add-SPImageWebPart([string]$url, [string]$Image, [string]$Name, [string]$BackgroundColor = ("Transparent"), [string]$Zone = ("Left"), [string]$Index = ("0"), [string]$VerticalAlignment = ("Middle"), [string]$HorizontalAlignment = ("Center"), [string]$ChromeType = ("Default")) {

	$ImageName = Split-Path $Image -leaf


	Copy-Item $Image -destination "C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\TEMPLATE\IMAGES" -Force

	$OpenWeb = Get-SPWeb $url
	$WebPartManager  = $OpenWeb.GetLimitedWebPartManager("$url/default.aspx?PageView=Shared", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)

	$ImageWebPart = New-Object Microsoft.SharePoint.WebPartPages.ImageWebPart
	$ImageWebPart.ImageLink = "/_layouts/images/$ImageName"

	$ImageWebPart.ZoneID = $Zone
	$ImageWebPart.VerticalAlignment = $VerticalAlignment
	$ImageWebPart.HorizontalAlignment = $HorizontalAlignment
	$ImageWebPart.BackgroundColor = $BackgroudColor
	$ImageWebPart.Title = $Name
	$ImageWebPart.ChromeType = $ChromeType

	$WebPartManager.AddWebPart($ImageWebPart,$Zone,$Index)

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Image -AND $Name ) { Add-SPImageWebPart -url $url -Image $Image -Name $Name -BackgroundColor $BackgroundColor -Zone $Zone -Index $Index -VerticalAlignment $VerticalAlignment -HorizontalAlignment $HorizontalAlignment -ChromeType $ChromeType }