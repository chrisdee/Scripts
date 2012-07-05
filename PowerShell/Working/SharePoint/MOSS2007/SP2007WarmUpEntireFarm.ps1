## SharePoint Server:  PowerShell Script To Warmup All Web Applications And Sites In A Farm ##
# Usage: Works on both MOSS 2007 and SharePoint Server 2010 Farms
# Overview: performs an HTTP GET against the homepeage of each SPWeb of each SPSite of each SPWebapplication in the local farm. This version is NOT compatible with multi-server farm!
# Dependencies: Assemblies Microsoft.SharePoint and Microsoft.SharePoint.Administration. The account running the script must be farm admin and must have full read on web application to be processed.

[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Administration")

Function GetPage([string]$url)
{
    $CurrentSecurityContext = [System.Net.CredentialCache]::DefaultCredentials
    $WebRequest = [System.Net.HttpWebRequest]::Create($url)
    $WebRequest.Credentials = $CurrentSecurityContext
    $WebRequest.UserAgent = "SharePoint_Warm-up_Script"
    $WebResponse = $WebRequest.GetResponse()
}

Function GetAllWebApplicationsInFarm()
{
    $spFarm = [Microsoft.SharePoint.Administration.SPfarm]::Local
    $spUrls = $spFarm.AlternateUrlCollections
    $spWebApplicationUrls = $spUrls | foreach {$_ | foreach {$_.incomingurl}}
    Return $spWebApplicationUrls
}

Function GetAllSiteCollectionInWebApplication($WebApplicationUri)
{
    $spWebApp = [Microsoft.SharePoint.Administration.SPWebApplication]::Lookup($WebApplicationUri)
    $AllSitesCollectionsInWebApp = $spWebApp.Sites.Names
    Return $AllSitesCollectionsInWebApp

}

Function GetAllSitesinSiteCollection($SiteCollectionUri)
{
    $spSite =  new-object Microsoft.SharePoint.SPSite($SiteCollectionUri)
    $AllSitesInSiteCollection = $spSite.AllWebs.Names
    Return $AllSitesInSiteCollection
}

Function AppendSlash($Text)
{
    If (!($Text.SubString($Text.Length-1,1) -eq "/"))
    {
        $Text = $Text + "/"
    }
    Return $Text
}

$AllWebApplications = GetAllWebApplicationsInFarm
Foreach ($WebApplication in $AllWebApplications)
{
    $WebApplication = AppendSlash $WebApplication
    #Write-Host $WebApplication
    $SiteCollections = GetAllSiteCollectionInWebApplication $WebApplication
    Foreach ($SiteCollection in $SiteCollections)
    {
        $SiteCollection = $WebApplication+$SiteCollection
        $SiteCollection = AppendSlash $SiteCollection
        #Write-Host `t $SiteCollection
        $Sites = GetAllSitesinSiteCollection $SiteCollection
        Foreach ($Site in $Sites)
        {
            If ($Site.Length -gt 0)
            {
            $Site = $SiteCollection+$Site
            }
            Else
            {
            $Site = $SiteCollection
            }
            $Site = AppendSlash $Site
            Write-Host `t`t $Site
            GetPage $Site
            Clear-Variable Site
        }
        Clear-Variable Site
        Clear-Variable Sites
    }
    Clear-Variable SiteCollection
    Clear-Variable SiteCollections
}
