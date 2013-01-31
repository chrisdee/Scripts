## SharePoint Server: PowerShell Script To Add Items To A List Library From A CSV File ##

<#

Overview: PowerShell Script that takes data from a CSV file and adds this to a SharePoint List Library through the Object Model

Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Farms

Usage: Change the '$FilePath' and '$docliburl' variables to match your environment, and add additional '$item' variables to match your CSV file

Note: The SharePoint List and 'Mapped' Columns Must Have Been Created Already

Important: The script will add records to the existing list the each time it is run (cannot differentiate between duplicates)

Check your script repositories for 'DeleteSPListItems' type scripts to clear down / delete the list before adding list items again

#>

$FilePath = "YourCSVFile.csv" #Change this path to suit your environment
$docliburl="http://YourWebAppURL/TestContacts"; #Change this URL to suit your environment (full path to the list library)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null;

$site=new-object Microsoft.SharePoint.SPSite($docliburl);
$web=$site.openweb();
$list=$web.GetList($docliburl);
$csv_file = Import-Csv $FilePath;
foreach ($line in $csv_file) 
{ 
Write-Output $line.Title;
  $item = $list.Items.Add();
  $item["FirstName"] = $line.FirstName;
  $item["LastName"] = $line.LastName;
  $item["Phone"] = $line.Phone;
  $item["Address"] = $line.Address;
  $item.Update();
}