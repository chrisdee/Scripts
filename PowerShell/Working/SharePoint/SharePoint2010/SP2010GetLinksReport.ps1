## SharePoint Server: PowerShell Script To Produce a Report on Hyperlinks for All Site Collections in a Web Application ##

<#

Overview: This script will print out a list of all links in the Quick Launch, Links Lists, and default page for each SPWeb object to a CSV file located in the directory specified in the variables section

Environments: SharePoint Server 2010 / 2013 + Farms

Usage: Edit the following variables to match your environment and run the script: '$siteURL'; '$filePath'

Resource: https://blog.henryong.com/2011/05/20/sharepoint-link-reporter-using-powershell/

#>

######################## Start Variables ########################
$siteURL = "https://YourWebApp.com" #URL to any site in the web application.
$filePath = "C:\BoxBuild\Scripts\SPLinksReport.csv"
$PublishingFeatureGUID = "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" #You shouldn't need to change this GUID
######################## End Variables ########################
if(Test-Path $filePath)
{
 Remove-Item $filePath
}
Clear-Host
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Publishing")
[System.Reflection.Assembly]::LoadWithPartialName("System.Net.WebClient")

# Creates an object that represents an SPWeb's Title and URL
function CreateNewWebObject
{
 $linkObject = New-Object system.Object
 $linkObject | Add-Member -type NoteProperty -Name WebTitle -Value $web.Title
 $linkObject | Add-Member -type NoteProperty -Name WebURL -Value $web.URL

 return $linkObject
}
# Creates an object that represents the header links of the Quick Launch
function CreateNewLinkHeaderObject
{
 $linkObject = New-Object system.Object
 $linkObject | Add-Member -type NoteProperty -Name WebTitle -Value $prevWebTitle
 $linkObject | Add-Member -type NoteProperty -Name WebURL -Value $prevWebURL  
 $linkObject | Add-Member -type NoteProperty -Name QLHeaderTitle -Value $node.Title
 $linkObject | Add-Member -type NoteProperty -Name QLHeaderLink -Value $node.Url
 return $linkObject
}
# Creates an object that represents to the links in the Top Link bar
function CreateNewTopLinkObject
{
 $linkObject = New-Object system.Object
 $linkObject | Add-Member -type NoteProperty -Name WebTitle -Value $prevWebTitle
 $linkObject | Add-Member -type NoteProperty -Name WebURL -Value $prevWebURL  
 $linkObject | Add-Member -type NoteProperty -Name TopLinkTitle -Value $node.Title
 $linkObject | Add-Member -type NoteProperty -Name TopLinkURL -Value $node.Url
 $linkObject | Add-Member -type NoteProperty -Name TopNavLink -Value $true
 return $linkObject
}
# Creates an object that represents the links of in the Quick Launch (underneath the headers)
function CreateNewLinkChildObject
{
 $linkObject = New-Object system.Object
 $linkObject | Add-Member -type NoteProperty -Name WebTitle -Value $prevWebTitle
 $linkObject | Add-Member -type NoteProperty -Name WebURL -Value $prevWebURL
 $linkObject | Add-Member -type NoteProperty -Name QLHeaderTitle -Value $prevHeaderTitle
 $linkObject | Add-Member -type NoteProperty -Name QLHeaderLink -Value $prevHeaderLink
 $linkObject | Add-Member -type NoteProperty -Name QLChildLinkTitle -Value $childNode.Title
 $linkObject | Add-Member -type NoteProperty -Name QLChildLink -Value $childNode.URL
 return $linkObject
}
## Creates an object that represents items in a Links list.
function CreateNewLinkItemObject
{
 $linkObject = New-Object system.Object
 $linkObject | Add-Member -type NoteProperty -Name WebTitle -Value $prevWebTitle
 $linkObject | Add-Member -type NoteProperty -Name WebURL -Value $prevWebURL
 $linkObject | Add-Member -type NoteProperty -Name ListName -Value $list.Title

 $spFieldURLValue = New-Object microsoft.sharepoint.spfieldurlvalue($item["URL"])

 $linkObject | Add-Member -type NoteProperty -Name ItemTitle -Value $spFieldURLValue.Description
 $linkObject | Add-Member -type NoteProperty -Name ItemURL -Value $spFieldURLValue.Url
 return $linkObject
}
# Determines whether or not the passed in Feature is activated on the site or not.
function FeatureIsActivated
{param($FeatureID, $Web)
 return $web.Features[$FeatureID] -ne $null
}
# Creates an object that represents a link within the body of a content page.
function CreateNewPageContentLinkObject
{
 $linkObject = New-Object system.Object
 $linkObject | Add-Member -type NoteProperty -Name WebTitle -Value $prevWebTitle
 $linkObject | Add-Member -type NoteProperty -Name WebURL -Value $prevWebURL
 $linkObject | Add-Member -type NoteProperty -Name PageContentLink -Value $link

 return $linkObject
}
$wc = New-Object System.Net.WebClient
$wc.UseDefaultCredentials = $true
$pattern = "(((f|ht){1}tp://)[-a-zA-Z0-9@:%_\+.~#?&//=]+)"
$site = new-object microsoft.sharepoint.spsite($siteURL)
$webApp = $site.webapplication
$allSites = $webApp.sites
$customLinkObjects =@()
foreach ($site in $allSites)
{
 $allWebs = $site.AllWebs

 foreach ($web in $allWebs)
 {
  ## If the web has the publishing feature turned OFF, use this method
  if((FeatureIsActivated $PublishingFeatureGUID $web) -ne $true)
  {
   $quickLaunch = $web.Navigation.QuickLaunch
   $customLinkObject = CreateNewWebObject
   $customLinkObjects += $customLinkObject

   $prevWebTitle = $customLinkObject.WebTitle
   $prevWebURL = $customLinkObject.WebURL

   # First level of the Quick Launch (Headers)
   foreach ($node in $quickLaunch)
   {
    $customLinkObject = CreateNewLinkHeaderObject

    $customLinkObjects += $customLinkObject

    $prevHeaderTitle = $node.Title
    $prevHeaderLink = $node.Url

    # Second level of the Quick Launch (Links)
    foreach ($childNode in $node.Children)
    {
     $customLinkObject = CreateNewLinkChildObject

     $customLinkObjects += $customLinkObject
    }
   }

   # Get all the links in the Top Link bar
   $topLinks = $web.Navigation.TopNavigationBar
   foreach ($node in $topLinks)
   {
    $customLinkObject = CreateNewTopLinkObject

    $customLinkObjects += $customLinkObject

    $prevHeaderTitle = $node.Title
    $prevHeaderLink = $node.Url    
   }
  }

  ## If the web has the publishing feature turned ON, use this method
  else
  {
   $publishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
   $quickLaunch = $publishingWeb.CurrentNavigationNodes
   $customLinkObject = CreateNewWebObject
   $customLinkObjects += $customLinkObject

   $prevWebTitle = $customLinkObject.WebTitle
   $prevWebURL = $customLinkObject.WebURL

   # First level of the Quick Launch (Headers)
   foreach ($node in $quickLaunch)
   {
    $customLinkObject = CreateNewLinkHeaderObject

    $customLinkObjects += $customLinkObject

    $prevHeaderTitle = $node.Title
    $prevHeaderLink = $node.Url

    # Second level of the Quick Launch (Links)
    foreach ($childNode in $node.Children)
    {
     $customLinkObject = CreateNewLinkChildObject

     $customLinkObjects += $customLinkObject
    }
   }

   # Get all the links in the Top Link bar
   $topLinks = $web.Navigation.TopNavigationBar
   foreach ($node in $topLinks)
   {
    $customLinkObject = CreateNewTopLinkObject

    $customLinkObjects += $customLinkObject

    $prevHeaderTitle = $node.Title
    $prevHeaderLink = $node.Url    
   }   

  }

  #Looking for lists of type Links
  $lists = $web.Lists
  foreach ($list in $lists)
  {
   if($list.BaseTemplate -eq "Links")
   {
    $prevWebTitle = $customLinkObject.WebTitle
    $prevWebURL = $customLinkObject.WebURL

    # Going through all the links in a Links List
    foreach ($item in $list.Items)
    {
     $customLinkObject = CreateNewLinkItemObject

     $customLinkObjects += $customLinkObject     
    }

Write-Host $list.Title
   }  
  }

  #Looking at the default page for each web for links embedded within the content areas
  $htmlContent = $wc.DownloadString($web.URL)
  $result = $htmlContent | Select-String -Pattern $pattern -AllMatches
  $links = $result.Matches | ForEach-Object {$_.Groups[1].Value}
  foreach ($link in $links)
  {
   $customLinkObject = CreateNewPageContentLinkObject
   $customLinkObjects += $customLinkObject
  }

Write-Host $web.Title
  $web.Dispose()
 }
$site.dispose()
}
# Exporting the data to a CSV file
$customLinkObjects | Select-Object WebTitle,WebURL,TopNavLink,TopLinkTitle,TopLinkURL,QLHeaderTitle,QLHeaderLink,QLChildLinkTitle,QLChildLink,ListName,ItemTitle,ItemURL,PageContentLink | Export-Csv $filePath
write-host "Done"