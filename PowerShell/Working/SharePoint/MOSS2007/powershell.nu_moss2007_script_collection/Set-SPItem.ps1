##################################################################################
#
#
#  Script name: Set-SPSItem.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$List, [string]$Name, [string]$Field = ("Title"), [HashTable]$Values, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Set-SPItem
Adds or Modifies a List Item

PARAMETERS: 
-url		Url to SharePoint Site
-List		List Name
-Name		Title Of Item
-FieldName	Name of Field To Check, Default is Title
-Values		HashTable Array containing Field Name and Value

SYNTAX:

Set-SPItem -url http://moss -List "Shared Documents" -Name "Excel SpreadSheet.xlsx" -Field "Name" -Values @{"Document Type" = "Excel"; "Document Owner" = "Niklas Goude"}

Gets the Item "Excel SpreadSheet.xls" from the "Shared Documents" and sets the Field "Document Type" to Excel and The Field "Document Owner" to "Niklas Goude"

Set-SPItem -url http://moss -List Users -Name nigo -Values @{"Department" = "IT"; "Description" = "IT Consultant"}

Adds a New Item (if it doesn't exist) and sets the Title to nigo, the Department to IT and the Description to ITConsultant

Opens The SiteCollection.

Set-SPItem -help

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

function Set-SPItem([string]$url, [string]$List, [string]$Name, [string]$Field = ("Title"), [HashTable]$Values) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	if($OpenList.Items | Where { $_[$Field] -eq $Name }) {
		$Item = $OpenList.Items | Where { $_[$Field] -eq $Name }
	} else {
		$Item = $OpenList.Items.Add()
		$Item[$Field] = $Name
	}

	$Values.Keys | ForEach {

		$FieldName = $_
		$Value = $Values[$_]

		Switch($OpenList.Fields[$FieldName].TypeDisplayName) {

			{ $_ -eq "Lookup" } {

				if($OpenList.Fields[$FieldName].LookupField -eq $Null) { $LookupField = "Title" } else { $LookupField = $OpenList.Fields[$FieldName].LookupField }
				$LookupGUID = (($OpenList.Fields[$FieldName].LookupList).Replace("{","")).Replace("}","")
				$LookupList = $OpenWeb.Lists | Where { $_.ID -match $LookupGUID }

				if($OpenList.Fields[$FieldName].AllowMultipleValues -eq $True) {
					$SplitValues = $Value.Split(";")
					foreach ($SplitValue in $SplitValues) {
						$SplitValue = ($SplitValue.TrimStart()).TrimEnd()
						$LookupItems = ($LookupList.Items | Where { $_[$LookupField] -eq $SplitValue } | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name + ";#" } }).Item
						$AddValue += $LookupItems

					}
				} else {
					$AddValue = ($LookupList.Items | Where { $_[$LookupField] -eq $Value } | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name} }).Item
				}
			}

			{ $_ -eq "Choice" } {

				if($OpenList.Fields[$FieldName].FieldValueType.Name -eq "SPFieldMultiChoiceValue") {
					$AddValue = New-Object Microsoft.SharePoint.SPFieldMultiChoiceValue
					$SplitValues = $Value.Split(";")

					foreach($SplitValue in $SplitValues) {
						$SplitValue = ($SplitValue.TrimStart()).TrimEnd()
						$AddValue.Add($SplitValue)
					}
				} else {
					$AddValue = [string]$Value
				}
			}

			{ $_ -eq "Currency" } {
				$AddValue = [Double]$Value
			}

			{ $_ -eq "Number" } {
				$AddValue = [Double]$Value
			}

			{ $_ -eq "Date and Time" } {
				$AddValue = [DateTime]$Value
			}

			{ $_ -eq "Yes/No" } {
				if($Value -eq "Yes") { $AddValue = [bool]$True } else { $AddValue = [bool]$False }
			}

			{ $_ -eq "Hyperlink or Picture" } {
				$AddValue = [string]$Value.Replace(";",",")
			}

			{ $_ -eq "Single line of text" } {
				$AddValue = [string]$Value
			}

			{ $_ -eq "Multiple lines of text" } {
				$AddValue = [string]$Value
			}

			{ $_ -eq "Person or Group" } {
				if($OpenList.Fields[$FieldName].AllowMultipleValues -eq $True) {
					$SplitValues = $Value.Split(";")
					foreach($SplitValue in $SplitValues) {
						$SplitValue = ($SplitValue.TrimStart()).TrimEnd()
						if($SplitValue -match "$env:USERDOMAIN\\") {
							$GetItem = ($OpenWeb.AllUsers[$SplitValue] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name + ";#"} }).Item
						} else {
							$GetItem = ($OpenWeb.Groups[$SplitValue] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name + ";#"} }).Item
						}
						$AddValue += $GetItem
					}
				} else {
					if($Value -match "$env:USERDOMAIN\\") {
						$GetItem = ($OpenWeb.AllUsers[$Value] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name } }).Item
					} else {
						$GetItem = ($OpenWeb.Groups[$Value] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name } }).Item
					}
					$AddValue = $GetItem
				}
			}
			Default { Write-Host ”Item Unknown” }
		}

		$Item[$FieldName] = $AddValue

		$AddValue = $Null
		$SplitValue = $Null
		$SplitValues = $Null
	}

	$Item.Update()
	$OpenWeb.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $List -AND $Name -AND $Values) { Set-SPItem -url $url -List $List -Name $Name -Field $Field -Values $Values }