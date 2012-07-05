##SharePoint Server 2010: PowerShell Script To Set Your Site Theme Across SharePoint Sites and Sub Sites
#Usage Note: Setting the $NewTheme Variable to 'Default' doesn't appear to restore the 'out of the box theme'

$SiteUrl = "http://intranet.contoso.com" #Change your Site URL here - Script will also set Theme for all Sub Sites
$NewTheme = "Azure" #Set your Theme here

# Loading Microsoft.SharePoint.PowerShell
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
if ($snapin -eq $null) {
Write-Host "Loading SharePoint Powershell Snapin"
Add-PSSnapin "Microsoft.SharePoint.Powershell"
}

# Setting site themes on sites and sub sites
$SPSite = Get-SPSite | Where-Object {$_.Url -eq $SiteUrl}
if($SPSite -ne $null)
{
$themes = [Microsoft.SharePoint.Utilities.ThmxTheme]::GetManagedThemes($SiteUrl);
foreach ($theme in $themes)
{
if ($theme.Name -eq $NewTheme)
{
break;
}
}
foreach ($SPWeb in $SPSite.AllWebs)
{
$theme.ApplyTo($SPWeb, $true);
Write-Host "Set" $NewTheme "at :" $SPWeb.Title "(" $SPWeb.Url ")"
}
}

Write-Host "Themes uodated at:" $SPSite.Url -foregroundcolor Green