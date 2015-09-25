## SharePoint Server: PowerShell Script to List All Inactive Features at Farm, Web Application, Site Collection, Web (sub-site) Scope ##

<#

Overview: Script that reports on all inactive SharePoint Features at Farm, Web Application, Site Collection, Web (sub-site) Scope

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the following areas to meet your Scope requirements and run the sctipt: '$_.Scope', 'Get-SPFeature'

Resources: 
 
http://www.theroks.com/list-all-installed-features-that-are-not-active-with-powershell

http://sharepoint.stackexchange.com/questions/76245/powershell-command-to-find-active-features-for-site-collection

#>

$siteFeatures = Get-SPFeature | Where-Object {$_.Scope -eq "Site" } # Farm, WebApp, Site and Web
if ($siteFeatures -ne $null)
{
   foreach ($feature in $siteFeatures)
   {
      # -Site can be replace by -Farm (without url), -WebApp, -Web
      if ((Get-SPFeature -Site "https://yoursitecollection.com" | Where-Object {$_.Id -eq $feature.id}) -eq $null)
      {
         # Inactive features
         Write-Host "Scope: $($feature.Scope) FeatureName: $($feature.DisplayName) FeatureID: $($feature.ID) " -ForeGroundColor Green
      }
   }
}