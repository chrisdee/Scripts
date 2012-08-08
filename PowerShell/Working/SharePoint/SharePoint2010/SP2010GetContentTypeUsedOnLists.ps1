## SharePoint Server 2010: PowerShell Script To Show All Lists Where A Specific Content Type Has Been Used ##

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$webs = get-spsite "http://yourserver/sites/yoursite" | get-spweb #Change the URL to match your environment

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