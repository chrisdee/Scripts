## =====================================================================
## Title       : Add-SPList
## Description : Creates a New SharePoint List
## Author      : Idera
## Date        : 24/11/2009
## Input       : Add-SPList [[-url] <String>] [[-List] <String>] [[-Description] <String>] [[-Type] <String>]
## Output      : 
## Usage       : Add-SPList -url http://moss -List Users -Description "Company Users" -Type "Custom List"
## Notes       : Adapted From Niklas Goude Script
## Tag         : List, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$List = "$(Read-Host 'List Name [e.g. My List]')", 
   [string]$Description = "$(Read-Host 'List Description [e.g. My New List]')", 
   [string]$Type = "$(Read-Host 'Type of List [e.g. Custom List]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	$OpenWeb = Get-SPWeb $url
	$ValidChoices = ($OpenWeb.ListTemplates | Select Name) | ForEach { $_.Name }
	$OpenWeb.Dispose()

	if($ValidChoices -eq $Type) {

		Add-SPList -url $url -List $List -Description $Description -Type $Type

	} else {
		Write-Host "$Type is not a Valid type of List, Please Choose one of the Following" -ForeGroundColor Red
		$ValidChoices
	}
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Add-SPList([string]$url, [string]$List, [string]$Description, [string]$Type) {
	
	$OpenWeb = Get-SPWeb $url

	if($OpenWeb.Lists | Where { $_.Title -eq $List}) {

		Write-Host "List: $($List) Already Exists." -ForeGroundColor Red

	} else {

		$TemplateType = $OpenWeb.ListTemplates[$Type]
		[void]$OpenWeb.Lists.Add($List, $Description, $TemplateType)
	}

	$OpenWeb.Dispose()
}

main