## SharePoint Server: PowerShell Script To Get Details On The Crawl Schedules For SSP Or Search Service Applications ##
## Overview: The 'Get-Crawl-Scheduled-Information' function returns crawl schedule details for a specified SSP URL / Search Application
## Environments: Should work on both MOSS 2007 and SharePoint Server 2010 farms
## Usage: Ensure to put the full URL in for your '$SiteCollectionURL' parameter

function Get-Crawl-Scheduled-Information([string]$SiteCollectionURL) 
{ 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search") > $null 

    $site = new-object Microsoft.SharePoint.SPSite($SiteCollectionURL) 
    Write-Host "SiteCollectionURL", $SiteCollectionURL 
    $context =  [Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($site) 

    $site.Dispose() 
    $sspcontent = new-object Microsoft.Office.Server.Search.Administration.Content($context) 
    $sspContentSources =  $sspcontent.ContentSources 
    foreach ($cs in $sspContentSources) 
    { 
        Write-Host " ------------------------------------------------------ " 
        Write-Host "NAME: ", $cs.Name, " - ID: ", $cs.Id, " - CrawlStatus: ", $cs.CrawlStatus 
        $myFullCrawlschedule = $cs.FullCrawlSchedule 
        Write-Host "Full Crawl Schedule Description: ", $myFullCrawlschedule.Description 
        $myIncrementalschedule = $cs.IncrementalCrawlSchedule 
        Write-Host "Incremental Crawl Schedule Description: ", $myIncrementalschedule.Description 
    } 
    Write-Host " ------------------------------------------------------ " 
} 

Get-Crawl-Scheduled-Information "http://SSPWebApplicationFullPath" #Replace this with your SSP / Search Application full path