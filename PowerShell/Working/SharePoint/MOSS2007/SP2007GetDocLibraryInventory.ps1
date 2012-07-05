################################################################################################
# SharePoint 2007: PowerShell Script to Enumerate All Documents on a MOSS 20007 List Library
# 
# Resource: http://www.timeggleston.co.uk/powershell.php
# When run against a document library, outputs a report on all files contained therein, suitable
# for a CSV comprising the following fields:
# > Full server-relative path to item
# > Modified date of item
# > User who modified item
# > Total number of versions (simple integer count, ignores major/minor status)
# > Size of the current version
#
# The script runs a recursive query, so returns all files in the document library, the equivalent
# to a view using "show all items without folders".
#
# Invoke this script using a > operator to redirect the output to a file,
# as follows:
#
# Usage Example: ./SP2007GetDocLibraryInventory.ps1 > output.csv
#
################################################################################################
 
# User-modifiable variables
 
$siteurl = "https://YourWebApp/YourSite"; # site collection URL
$weburl = ""; # blank denotes root web of a site collection
$listurl = "/sitename/My%20List"; # list URL
 
###################################################
#
# Don't change below here
#
###################################################
 
cls;
 
write-host ">>> STARTING at"(get-date) `n;
 
[void] [System.Reflection.Assembly]::Load(”Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c”)
 
$site = new-object Microsoft.SharePoint.SPSite("$siteurl");
$web = $site.OpenWeb("$weburl");
$list = $web.GetList("$listurl");
$query = new-object Microsoft.SharePoint.SPQuery
$query.RowLimit = 1000; # only read 1000 items at a time into memory. Decrease this if you run into memory issues, or increase for a slight speed gain
$query.ViewAttributes += " Scope='Recursive'"; # this is where we make the query disregard folders
$index = 1;
 
write-output "Path,Modified Date,Modified By,Num Versions,Current Ver Size (bytes)";
 
do {
    $itemcoll = $list.GetItems($query);
     
    foreach ($item in $itemcoll) {
        write-host $($item.Url);
        write-output "$($item.Url),$($item["Modified"].ToString()),$($item["Editor"]),$($item.Versions.Count),$($item.File.Length)";
    }
     
    $query.ListItemCollectionPosition = $itemcoll.ListItemCollectionPosition;
    $index++;
} while ($query.ListItemCollectionPosition -ne $null);
 
write-host ">>> FINISHED at"(get-date) `n;