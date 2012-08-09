## SharePoint Server 2007: PowerShell Content Type Specific Queries ##
## Overview: The 3 queries below cover Content Types used on SharePoint document and list libraries
## Script 1: Get all lists where a specific content type has been applied to
## Script 2: Get all list items where a specific content type has been applied to
## Script 3: Gets a summary of all content types used on site collections and webs

## 1. PowerShell Script To Show All Lists Where A Specific Content Type Has Been Used

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

$site = New-Object Microsoft.SharePoint.SPSite("http://yourserver/sites/yoursite") #Change the URL to match your environment

$webs = $site.AllWebs

foreach ($web in $webs) 
{
  foreach ($lst in $web.lists) 
  { 
    foreach ($ctype in $lst.ContentTypes) 
    { 
      if ($ctype.Name -eq "Document") #Change your Site Content Type name here
      { $lst.DefaultViewUrl }
    }
  } 
  $web.Dispose() 
}

## 2. PowerShell Script To Show All List Items Where A Specific Content Type Has Been Used

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

$site = New-Object Microsoft.SharePoint.SPSite("http://yourserver/sites/yoursite") #Change the URL to match your environment

$webs = $site.AllWebs

foreach ($web in $webs)
{
  foreach ($lst in $web.lists)
  {
    foreach ($item in $lst.Items)
    {
      if ($item.ContentType.Name -eq "Document") #Change your Site Content Type name here
      { $item.Url}
    }
  }
  $web.Dispose() 
}

## 3. PowerShell Script To Show All Content Types Used On Site Collections And Webs

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

$site = New-Object Microsoft.SharePoint.SPSite("http://yourserver/sites/yoursite") #Change the URL to match your environment

$webs = $site.AllWebs

$web = $site.RootWeb

foreach ($ctype in $web.ContentTypes) {$ctype.Name}

$web.Dispose()