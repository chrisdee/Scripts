## SharePoint Server 2010: PowerShell Script To Import CSV File Data Into A List ##
## Overview: Imports data from a CSV file into a SharePoint list set up with the same columns as in the CSV file
## Usage: Create your SharePoint list columns and then include the same column headings in your CSV file
## Additional Columns: Add these below in the script to your 'foreach' loop as per the example
## Note: Any re-imports of existing data will create new columns with this data as if though they were new records
## Resource: http://sp2010adminpack.codeplex.com

<#
.SYNOPSIS
    Imports data from your Excel CSV file into SharePoint
.DESCRIPTION
    Use an Excel CSV file to pull data into your SharePoint lists. This script can be scheduled to automate 
	importing new data as CSVs are created.
	.NOTES
    Author: David Lozzi @DavidLozzi
    DateCreated: 12Jan2012
#>

if((Get-PSSnapin | Where {$_.Name -eq “Microsoft.SharePoint.PowerShell”}) -eq $null) {
	Add-PSSnapin Microsoft.SharePoint.PowerShell
}
$web = Get-SPWeb "http://URL/to/web" #Change this to match your site url

$list = $web.lists["List Name"] #Change this to match your list name

$cnt = 0
foreach($i in Import-CSV YourCSVFile.csv) #Change the CSV file path to match your environment
{
    $new = $list.Items.Add()
    $new["Title"] = $i.Title
	##Important: you can add more fields here - example: $new["YourField"] = $i.YourField
    $new.Update()
    $cnt++
}
"Added " + $cnt.ToString() + " records."

"Done. Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
