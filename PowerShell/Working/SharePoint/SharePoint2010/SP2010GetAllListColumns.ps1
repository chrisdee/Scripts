## SharePoint Server: PowerShell Script To List All Site Columns At List Library Level ##

<#

Overview: PowerShell Script To List All Site Columns At List Library Level. Provides information on the Field Name, Internal Name, and Column Type

Environments: SharePoint Server 2010 / 2013 + Farms

Usage: Edit the following variables to match your environment and run the script: '$SiteURL'; '$ListName'

Resource: http://www.sharepointdiary.com/2016/04/get-list-fields-in-sharepoint-using-powershell.html

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Configuration Parameters
$SiteURL="https://YourSite.com"
$ListName= "YourListName"
 
#Get the List
$List = (Get-SPWeb $SiteURL).Lists.TryGetList($ListName)
 
Write-Host "Field Name | Internal Name | Type"
Write-Host "------------------------------------"
 
#Loop through each field in the list and get the Field Title, Internal Name and Type
ForEach ($Field in $List.Fields)
{
    Write-Host $Field.Title"|"$Field.internalName"|"$Field.Type
}


#Read more: http://www.sharepointdiary.com/2016/04/get-list-fields-in-sharepoint-using-powershell.html#ixzz58tBLXmub