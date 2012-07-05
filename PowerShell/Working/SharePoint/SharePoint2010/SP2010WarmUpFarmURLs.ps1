########################################################################################################
# Name: SP2010WarmUpFarmURLs.ps1
# Overview: Script accepts All / Specific URLs, and also writes to application event log and log files
# Author: Ingo Karstein: http://ikarstein.wordpress.com/2011/08/03/sharepoint-warm-up-now-with-timeout/                    
# Modified by: Wahid Saleemi
# Twitter: @wahidsaleemi                    
# Reference: http://www.wahidsaleemi.com    
########################################################################################################
#Region Define Variables
### Setup your variables here
$timeout = 60000 #=60 seconds
# Leave the line below commented if you want all of the Web Apps. Uncomment and set for only specific ones.
#$urls= @("http://finweb", "http://another.sharepoint.local")
#EndRegion
 
#Region Load SharePoint Snapin
$ver = $host | select version
if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#EndRegion
 
#Region MyWebClient
    Add-Type -ReferencedAssemblies "System.Net" -TypeDefinition @"
    using System.Net;
    public class MyWebClient : WebClient
    {
        private int timeout = 60000;
         public MyWebClient(int timeout)
        {
            this.timeout = timeout;
        }
         public int Timeout
        {
            get
            {
                return timeout;
            }
            set
            {
                timeout = value;
            }
        }
         protected override WebRequest GetWebRequest(System.Uri webUrl)
        {
            WebRequest retVal = base.GetWebRequest(webUrl);
            retVal.Timeout = this.timeout;
            return retVal;
        }
    }
"@
#EndRegion
 
#Region Function to get Site List
Function Get-SiteList {
$script:sitelist = "$env:temp\siteURLs.txt" #Change your log file name here
New-Item $script:sitelist -itemType File -Force | Out-Null
# To WarmUp, we really just need the load the Web Apps
$sites = Get-SPWebApplication -IncludeCentralAdministration | Select Url
# If we want to try some caching too, get all the site collections, comment above and uncomment below
# $sites=Get-SPSite -Limit ALL
foreach ($site in $sites) 
    {
        #write-host $site.Url;
        $site.Url | Out-File $script:sitelist -append
    }
}
#EndRegion
#Region Set URLs to WarmUp
# check to see if a variable $urls is set.
if (!(test-path variable:\urls))
    {
    Get-SiteList
    $urls = (Get-Content $script:sitelist)
    }
#EndRegion
#Region Perform the WarmUp
New-EventLog -LogName "Application" -Source "SharePoint Warmup Script" -ErrorAction SilentlyContinue | Out-Null
$urls | % {
    $url = $_
    Write-Host "Warming up $_"
    try {
        $wc = New-Object MyWebClient($timeout)
        $wc.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $ret = $wc.DownloadString($url)
        if( $ret.Length -gt 0 ) {
            $s = "Last run successful for url ""$($url)"": $([DateTime]::Now.ToString('yyyy.dd.MM HH:mm:ss'))"
            $filename=((Split-Path ($MyInvocation.MyCommand.Path))+"\SPWarmUp.log") #Change your 'success' log file name here
            if( Test-Path $filename -PathType Leaf ) {
                $c = Get-Content $filename
                $cl = $c -split '`n'
                $s = ((@($s) + $cl) | select -First 200)
            }
            Out-File -InputObject ($s -join "`r`n") -FilePath $filename
        }
    } catch {
          Write-EventLog -Source "SharePoint Warmup Script"  -Category 0 -ComputerName "." -EntryType Error -LogName "Application" `
            -Message "SharePoint Warmup failed for url ""$($url)""." -EventId 1001
 
        $s = "Last run failed for url ""$($url)"": $([DateTime]::Now.ToString('yyyy.dd.MM HH:mm:ss')) : $($_.Exception.Message)"
        $filename=((Split-Path ($MyInvocation.MyCommand.Path))+"\lastrunlog.txt") #Change your 'error' log file name here
        if( Test-Path $filename -PathType Leaf ) {
          $c = Get-Content $filename
          $cl = $c -split '`n'
          $s = ((@($s) + $cl) | select -First 200)
        }
        Out-File -InputObject ($s -join "`r`n") -FilePath $filename
    }
}
#EndRegion
$script:sitelist | Remove-Item -force -ErrorAction SilentlyContinue
