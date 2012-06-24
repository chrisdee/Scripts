##################################################################################
#
#
#  Script name: Add-SPListViewWebPart.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [string]$Zone = ("Left"), [string]$Index = ("0"), [string]$ChromeType = ("Default"), [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPListViewWebPart
Adds a New List View WebPart

PARAMETERS: 
-url			Url to SharePoint Site
-List			Name of List
-Name			Title of WebPart
-Zone			Zone to place WebPart, Default set to Left
-Index			Index Position of WebPart, Default set to 0 ( Top )
-ChromeType		Chrome Type of WebPart, Default Set to Default

SYNTAX:

Add-SPListViewWebPart -url http://moss/statistics -List Statistics -Name "Client Statistics" -ChromeType "None"

Adds a New List View WebPart 

Add-SPListViewWebPart -help

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

function Add-SPListViewWebPart([string]$url, [string]$List, [string]$Name, [string]$Zone = ("Left"), [string]$Index = ("0"), [string]$ChromeType = ("Default")) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	$WebPartManager  = $OpenWeb.GetLimitedWebPartManager("$url/default.aspx?PageView=Shared", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)

	$ListViewWebPart = New-Object Microsoft.SharePoint.WebPartPages.ListViewWebPart
	$ListViewWebPart.Title = $Name
	$ListViewWebPart.ListName = ($OpenList.ID).ToString("B").ToUpper()
	$ListViewWebPart.ViewGuid = ($OpenList.DefaultView.ID).ToString("B").ToUpper()
	$ListViewWebPart.ZoneID = $Zone
	$ListViewWebPart.ChromeType = $ChromeType

	$WebPartManager.AddWebPart($ListViewWebPart,$Zone,$Index)

	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Name) { Add-SPListViewWebPart -url $url -List $List -Name $Name -Zone $Zone -Index $Index -ChromeType $ChromeType }