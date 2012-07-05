## MOSS 2007: PowerShell Script To Enable Or Disable Document Parser Processing ##
## Overview: http://msdn.microsoft.com/en-us/library/aa543341(v=office.12).aspx

param($url=$(Throw "Parameter missing: -url"), $switch=$(Throw "Parameter missing (on/off): -switch"))
"URL -> $url, switch-> $switch"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint");
$site = New-Object Microsoft.SharePoint.SPSite($url);

$enabled = $true;
if ($switch -match "off") {$enabled=$false};


"Current RootWeb Setting: "+$site.RootWeb.ParserEnabled;
$site.RootWeb.ParserEnabled = $enabled;
#$site.RootWeb.AllowUnsafeUpdates = $true; 
$site.RootWeb.Update();
$site = New-Object Microsoft.SharePoint.SPSite($url);
"After RootWeb Setting: "+$site.RootWeb.ParserEnabled;

# Example Command of setting the $site.RootWeb.ParserEnabled value to off / false:

#.\SP2007DisableDocumentParserProcessing.ps1 -url "http://YourSharePointSite.com" off

# Example Command of setting the $site.RootWeb.ParserEnabled value to on / true:

#.\SP2007DisableDocumentParserProcessing.ps1 -url "http://YourSharePointSite.com" on