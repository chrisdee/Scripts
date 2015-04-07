## SharePoint Server: PowerShell Script to Get a Report on the Crawl Log / Crawl History for the Search Service Application (SSA) ##

<#

Overview: PowerShell Script to Get Crawl History Results from the Search Service Application (SSA), and export them to a CSV file for analysis

Usage: Edit the following variables to match your environment and run the script: '$numberOfResults'; '$contentSourceName'; '$ReportPath'

Environments: SharePoint Server 2010 / 2013 Farms

Resources: 

http://cameron-verhelst.be/blog/2014/06/13/powershell-search-crawl-history
http://blogs.technet.com/b/rycampbe/archive/2014/08/15/sharepoint-2013-export-index-a-la-crawl-log.aspx

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

### Start Variables ###
$numberOfResults = 100 #Change this to specify how many crawl history results you want to report back on
$contentSourceName = "Local SharePoint sites"
$ReportPath = "C:\BoxBuild\Scripts\SPCrawlHistoryReport.csv"
### End Variables ###

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search.Administration")

$searchServiceApplication = Get-SPEnterpriseSearchServiceApplication
$contentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchServiceApplication
$contentSource = $contentSources | ? { $_.Name -eq $contentSourceName }

$crawlLog = new-object Microsoft.Office.Server.Search.Administration.CrawlLog($searchServiceApplication)
$crawlHistory = $crawlLog.GetCrawlHistory($numberOfResults, $contentSource.Id)
$crawlHistory.Columns.Add("CrawlTypeName", [String]::Empty.GetType()) | Out-Null

# Label the crawl type
$labeledCrawlHistory = $crawlHistory | % {
 $_.CrawlTypeName = [Microsoft.Office.Server.Search.Administration.CrawlType]::Parse([Microsoft.Office.Server.Search.Administration.CrawlType], $_.CrawlType).ToString()
 return $_
}

#$labeledCrawlHistory | Out-GridView
$labeledCrawlHistory | Export-CSV $ReportPath -NoTypeInformation