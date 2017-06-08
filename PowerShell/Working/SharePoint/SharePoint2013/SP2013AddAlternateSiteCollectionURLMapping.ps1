## SharePoint Server: PowerShell Script to Add additional URLs in Zones for Host Named Site Collections (HNSC) ##

## Environments: SharePoint Server 2013 + Farms

## Resource: https://blogs.msdn.microsoft.com/brian_farnhill/2014/07/07/multiple-zones-for-host-named-site-collections-in-sp2013

$SiteCollectionURL = "https://external.theglobalfund.org" #Provide your original HNSC URL here
$SiteCollectionAlternateURL = "https://vdc2-external.theglobalfund.org" #Provide the new URL to be mapped to the original HNSC
$SiteCollectionZone = "Internet" #Provide the Zone property for the new URL (Default; Intranet; Internet; Custom; Extranet)

Add-PSSnapin microsoft.sharepoint.powershell

Set-SPSiteUrl (Get-SPSite $SiteCollectionURL) -Url $SiteCollectionAlternateURL -Zone $SiteCollectionZone

Get-SPSiteUrl -Identity $SiteCollectionURL