## SharePoint Online: PowerShell Script to trigger a Re-index of all Site Collections and Sub-sites (webs) in a tenant via CSOM ##

<#

Overview: PowerShell Script to trigger a re-index of all Site Collections and Sub-sites (webs) in a tenant via CSOM

Usage: Edit the following variables to match your environment and run the script: '$tenant'; '$username'; '$password'; '$csomPath'

Requires:

SharePoint Online Client Components SDK - https://www.microsoft.com/en-us/download/details.aspx?id=42038

SharePoint Online PowerShell Module - https://www.microsoft.com/en-us/download/details.aspx?id=35588

Note: This script doesn't appear to work with Federated domain accounts, and requires a cloud account with appropriate SharePoint Admin access permissions to work

Resource: http://www.techmikael.com/2014/02/how-to-trigger-full-re-index-in.html

#>
 
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# replace these details or use Get-Credential to enter password securely as script runs
$tenant = "YourTenant"
$username = "FirstName.LastName@$tenant.onmicrosoft.com"
$password = "YourPassword"
$url = "https://$tenant.sharepoint.com"
$adminUrl = "https://$tenant-admin.sharepoint.com"
  
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
 
# change to the path of your CSOM dll's
$csomPath = "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI"
 
Add-Type -Path "$csomPath\Microsoft.SharePoint.Client.dll"
Add-Type -Path "$csomPath\Microsoft.SharePoint.Client.Runtime.dll"
 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword) 
 
function Reset-Webs( $siteUrl ) {
    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)     
    $clientContext.Credentials = $credentials
      
    if (!$clientContext.ServerObjectIsNull.Value) 
    { 
        Write-Host "Connected to SharePoint Online site: '$siteUrl'" -ForegroundColor Green 
    } 
      
    function processWeb($web)
    {
        $subWebs = $web.Webs
        $clientContext.Load($web)
        $clientContext.Load($web.AllProperties)
        $clientContext.Load($subWebs)
        $clientContext.ExecuteQuery()
        [int]$version = 0
        $allProperties = $web.AllProperties
        Write-Host "Web URL:" $web.Url -ForegroundColor White
        if( $allProperties.FieldValues.ContainsKey("vti_searchversion") -eq $true ) {
            $version = $allProperties["vti_searchversion"]            
        }
        Write-Host "Current search version: " $version -ForegroundColor White
        $version++
        $allProperties["vti_searchversion"] = $version
        Write-Host "Updated search version: " $version -ForegroundColor White
        $web.Update()
        $clientContext.ExecuteQuery()
 
        foreach ($subWeb in $subWebs)
        {
            processWeb($subWeb)
        }
    }
 
    $rootWeb = $clientContext.Web
    processWeb($rootWeb)
}
 
$spoCredentials = New-Object System.Management.Automation.PSCredential($username, $securePassword)
 
Connect-SPOService -Url $adminUrl -Credential $spoCredentials
Get-SPOSite | foreach {Reset-Webs -siteUrl $_.Url }