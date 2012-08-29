## =====================================================================
## Title       : Set-SPItem
## Description : Modifies an SP Item
## Author      : Idera
## Date        : 24/11/2009
## Input       : Set-SPItem [[-url] <String>] [[-List] <String>] [[-Field] <String>] [[-Item] <String>] [[-Values] <String>]
## Output      : 
## Usage       : Set-SPItem -url http://moss -List Users -Field Title -Item "My Item" -Values "Description=Hello,MultipleChoice=First;Second,Lookup=LookupItem"
## Notes       : Sets The Item "My Item" from the Users List Where the Title field is equal to "My Item"
##             : When Adding Multiple Choice or Lookup Fields, use a ; to Separate the Choices.
##               Adapted From Niklas Goude Script
## Tag         : Item, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$List = "$(Read-Host 'List Name [e.g. My List]')",
   [string]$Field = "$(Read-Host 'Field To match Item With [e.g. Title]')",
   [string]$Item = "$(Read-Host 'Item Name [e.g. First Item]')",
   [string]$Values = "$(Read-Host 'Item Values [e.g. Description=Hello,Choice=First Choice]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	$HashValues = @{}
	$Values.Split(",") | ForEach { $HashValues.Add($_.Split("=")[0],$_.Split("=")[1]) }
	
	Set-SPItem -url $url -List $List -Item $Item -Field $Field -Values $HashValues
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Set-SPItem([string]$url, [string]$List, [string]$Item, [string]$Field, [HashTable]$Values) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	if($OpenList.Items | Where { $_[$Field] -eq $Item }) {
		$OpenItem = $OpenList.Items | Where { $_[$Field] -eq $Item }

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
	
			$OpenItem[$FieldName] = $AddValue
	
			$AddValue = $Null
			$SplitValue = $Null
			$SplitValues = $Null
		}

	} else {

		Write-Host "$($Item) Not Found" -ForeGroundColor Red
	}
	
	$OpenItem.Update()
	$OpenWeb.Dispose()
}
	
main