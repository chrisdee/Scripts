## SharePoint Server 2010: PowerShell Functions To Report On Site Collection And Web Application Recycle Bins ##
## Usage Examples: One function for Web Application level, and another for Site Collection level
## Get-SPWebApplicationRecyleBinItemsReport -url "{web application url}" | ft *
## Get-SPWebApplicationRecyleBinItemsReport -url "{web application url}" | Where {$_.Size -gt 2000} | ft *
## Get-SPSiteCollectionRecycleBinItemsReport -siteCollectionUrl "{site collection url}" | ft *
## Get-SPSiteCollectionRecycleBinItemsReport -siteCollectionUrl "{site collection url}" | Where {$_.Size -gt 2000} | ft *

Add-PSSnapin Microsoft.SharePoint.PowerShell -ea SilentlyContinue  
 
$RecycleBinItem = @"  
    using System; 
     
    namespace RecyleBinReport{ 
        public class RecycleBinItem{ 
            public string DirName { get; set; } 
            public string ItemType { get; set; } 
            public string Title { get; set; } 
            public string AuthorName { get; set; } 
            public string DeletedByName { get; set; } 
            public DateTime DeletedDate { get; set; } 
            public Int32 Size { get; set; }             
        } 
    } 
"@ 
 
Add-Type $RecycleBinItem -Language CSharpVersion3 -ErrorAction SilentlyContinue 
$consolidatedBin = New-Object System.Collections.ArrayList 
     
function AggregateRecyleBinItems($recycleBin)  
{ 
    ForEach($item in $recycleBin) 
    { 
        $obj = New-Object RecyleBinReport.RecycleBinItem 
        $obj.DirName = $item.DirName 
        $obj.ItemType = $item.ItemType 
        $obj.Title = $item.Title 
        $obj.AuthorName = $item.AuthorName 
        $obj.DeletedByName = $item.DeletedByName 
        $obj.DeletedDate = $item.DeletedDate 
        $obj.Size = $item.Size 
         
        $pos = $consolidatedBin.Add($obj) 
    }  
} 
 
function Get-SPWebApplicationRecyleBinItemsReport() 
{ 
    param([string] $url) 
 
    if($url -eq $null -or $url -eq "") 
    { 
        Write-Error "Parameter $url cannot be null or empty" 
        Break; 
    } 
    $spWebApp = Get-SPWebApplication $url 
    $sites = $spWebApp.Sites 
    ForEach($site in $sites) 
    { 
        $scUrl = $site.Url 
        $siteCollectionRecycleBin = $site.RecycleBin 
        AggregateRecyleBinItems($siteCollectionRecycleBin)   
        #processs each web in site collection and print its rec 
        ForEach($web in $site.AllWebs) 
        { 
            AggregateRecyleBinItems($web.RecycleBin)  
        } 
    } 
    return $consolidatedBin 
} 
 
function Get-SPSiteCollectionRecycleBinItemsReport() 
{ 
    param([string] $siteCollectionUrl) 
     
    if($siteCollectionUrl -eq $null -or $siteCollectionUrl -eq "") 
    { 
        Write-Error "Parameter $url cannot be null or empty" 
        Break; 
    } 
    $site = Get-SPSite $siteCollectionUrl  
    if($site -ne $null) 
    { 
        $siteCollectionRecycleBin = $site.RecycleBin 
        AggregateRecyleBinItems($siteCollectionRecycleBin)   
        ForEach($web in $site.AllWebs) 
        { 
            AggregateRecyleBinItems($web.RecycleBin)  
        } 
    } 
    return $consolidatedBin 
} 
 
#Usage Examples:
#Get-SPWebApplicationRecyleBinItemsReport -url "http://team.contoso.local" | ft * 
#Get-SPSiteCollectionRecycleBinItemsReport -siteCollectionUrl "http://team.contoso.local/sites/shared" | ft *  