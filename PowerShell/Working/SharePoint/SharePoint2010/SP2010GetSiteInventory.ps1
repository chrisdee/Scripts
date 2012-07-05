## SharePoint Server: PowerShell Script To produce A CSV Report On All Sites Within A Web App ##
## Usage: This Script Should Work On MOSS 2007 And SharePoint Server 2010 Farms
## Edit Tip: Use CodePlex SharePoint Manager To Find Additional Properties To Add To The Script

######################## Start Variables #######################################################
$siteURL = "http://intranet.theglobalfund.org" #URL to any site in the web application.
$filePath = "D:\Scripts\PowerShell\Intranet_Sites_Report_250412.csv" #Path for exported CSV file
######################## End Variables #########################################################

if(Test-Path $filePath)
{
Remove-Item $filePath
}
Clear-Host

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

# Creates an object that represents a SharePoint site.
function CreateNewObject
{
$customObject = New-Object system.Object
$customObject | Add-Member -type NoteProperty -Name WebCreated -Value $web.Created.ToShortDateString()
$customObject | Add-Member -type NoteProperty -Name WebModified -Value $web.LastItemModifiedDate.ToShortDateString()
$customObject | Add-Member -type NoteProperty -Name RequestAccessEmail -Value $web.RequestAccessEmail
$customObject | Add-Member -type NoteProperty -Name WebTitle -Value $web.Title
$customObject | Add-Member -type NoteProperty -Name WebURL -Value $web.URL
$customObject | Add-Member -type NoteProperty -Name WebTemplateName -Value $web.WebTemplate
$customObject | Add-Member -type NoteProperty -Name WebTemplateID -Value $web.WebTemplateId
$customObject | Add-Member -type NoteProperty -Name ItemCount -Value ""
$customObject | Add-Member -type NoteProperty -Name SiteAdmins -Value ""
$customObject | Add-Member -type NoteProperty -Name GreaterThanZeroItems -Value $false

return $customObject
}

$site = new-object microsoft.sharepoint.spsite($siteURL)
$webApp = $site.webapplication
$allSites = $webApp.sites

$customObjectsList =@()

foreach

($site in $allSites)
{
$allWebs = $site.AllWebs

foreach ($web in $allWebs)
{
$itemCount = 0;

$customWebObject = CreateNewObject

$templateID = $web.WebTemplateID.ToString()


foreach ($list in $web.Lists)
{
if(($list.ItemCount -gt 0) -and ($list.Hidden -ne $true))
{
$customWebObject.GreaterThanZeroItems = $true

$itemCount += $list.ItemCount;
}
}

$customWebObject.ItemCount = $itemCount.ToString()
$customObjectsList += $customWebObject

Write-Host $web.title
$web.Dispose()
}
$site.dispose()
}

# Exporting the data to a CSV file
$customObjectsList | Select-Object WebCreated,WebModified,WebTitle,WebURL,WebTemplateName,WebTemplateID,ItemCount,GreaterThanZeroItems,SiteAdmins,RequestAccessEmail | Export-Csv $filePath