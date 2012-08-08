## SharePoint Server 2007: PowerShell Script To Show All Lists Where A Specific Content Type Has Been Used ##

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