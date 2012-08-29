## =====================================================================
## Title       : CheckIn-SPDocument
## Description : Checks in a Document in SharePoint
## Author      : Idera
## Date        : 24/11/2009
## Input       : CheckIn-SPDocument [[-url] <String>] [[-List] <String>] [[-Document] <String>]
## Output      : 
## Usage       : CheckIn-SPDocument -url http://moss -List "Shared Documents" -Document "MyDoc.Doc"
## Notes       : Adapted From Niklas Goude Script
## Tag         : Document, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$List = "$(Read-Host 'Document Library [e.g. Shared Documents]')",
   [string]$Document = "$(Read-Host 'Document Name [e.g. Word Doc.docx]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	CheckIn-SPDocument -url $url -List $List -Document $Document
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function CheckIn-SPDocument([string]$url, [string]$List, [string]$Document) {

	$OpenWeb = Get-SPWeb $url
	$GetFolder = $OpenWeb.GetFolder($List)
	$GetFolder.Files | Where { $_.Name -eq $Document } | ForEach {

		if($_.CheckOutStatus -ne "None") {
			Write-Host "$($_.Name) is Checked out To: $($_.CheckedOutBy)" -ForeGroundColor Yellow
			$_.CheckIn("Checked In By Administrator")
			Write-Host "$($_.Name) Checked In" -ForeGroundColor Green
		} else {
			Write-Host "$($_.Name) is Already Checked In" -ForeGroundColor Green
		}
		
	}
	$OpenWeb.Dispose()
}


main