<# SharePoint Server: PowerShell Script To Delete All Items From A List Without Sending Them To The Recycle Bin ##

Overview: PowerShell script that deletes all items from a list library. The list and columns will remain, while all the items
are deleted from this. This script deletes the items directly and they do not get sent to the End User Recycle Bin

Environments: MOSS 2007, SharePoint Server 2010 / 2013 Farms

Usage: Edit the '$SITEURL' and '$oList' variables to match your environment and run the script

Resource:  http://yalla.itgroove.net/2012/03/delete-all-items-from-a-sharepoint-list-powershell

#>

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null;

# Enter your site URL here
$SITEURL = "http://YourWebApp.com" #Change this to match your environment

$site = new-object Microsoft.SharePoint.SPSite ( $SITEURL )
$web = $site.OpenWeb()
"Web is : " + $web.Title

# Enter name of the List below
$oList = $web.Lists["YourList"]; #Change this to match your environment list name

"List is :" + $oList.Title + " with item count " + $oList.ItemCount

$collListItems = $oList.Items;
$count = $collListItems.Count - 1

for($intIndex = $count; $intIndex -gt -1; $intIndex--)
{
        "Deleting : " + $intIndex
        $collListItems.Delete($intIndex);
} 