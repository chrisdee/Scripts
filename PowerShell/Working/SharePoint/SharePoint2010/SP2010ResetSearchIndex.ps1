## SharePoint Server: PowerShell Script to Stop All Search Crawls and Reset the Search Index for All Content Sources ##

<#

Overview: PowerShell script that Stops all currently running crawls (including continuous crawls), and then resets the Search Index for all content sources

Note: Sometimes the Crawl Status might get stuck with a status message of 'Stopping'. This can often be resolved by attempting the script again

Environments: SharePoint Server 201 / 2013 Farms

Resources: 

http://www.sharepointdiary.com/2015/05/reset-search-index-in-sharepoint-2013-using-powershell.html

http://www.c-sharpcorner.com/blogs/force-stop-and-then-start-a-full-crawl-search-in-sharepoint-2013

https://technet.microsoft.com/en-us/library/jj219802.aspx#Disable_for_all

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell –ErrorAction SilentlyContinue

#Get Search service application
$ssa = Get-SPEnterpriseSearchServiceApplication

#Get the crawl status of the Search service application
Get-SPEnterpriseSearchCrawlContentSource -SearchApplication "Search Service Application" | select Name, CrawlStatus #Replace the default 'Search Service Application' name under '-SearchApplication' if different for your environment

#Disable continuous crawls for all content sources if enabled
$SSA =  Get-SPEnterpriseSearchServiceApplication
$SPContentSources = $SSA | Get-SPEnterpriseSearchCrawlContentSource | WHERE {$_.Type -eq "SharePoint"} 
foreach ($cs in $SPContentSources) 
{ 
  $cs.EnableContinuousCrawls = $false 
  $cs.Update() 
}

#Stop all currently running crawls
Get-SPEnterpriseSearchCrawlContentSource -SearchApplication "Search Service Application" | ForEach-Object {  
    if ($_.CrawlStatus -ne "Idle")  
    {  
        Write-Host "crawl stopping currently for content source $($_.Name)..."  
        $_.StopCrawl()  
         
        do { Start-Sleep -Seconds 1 }  
        while ($_.CrawlStatus -ne "Idle")  
    }
    }

#Recheck the crawl status of the Search service application (Should be 'Idle')
Get-SPEnterpriseSearchCrawlContentSource -SearchApplication "Search Service Application" | select Name, CrawlStatus

#Reset the search index completely for all content sources
(Get-SPEnterpriseSearchServiceApplication).reset($true, $true)