## SharePoint Online: PowerShell function to Activate Site Collection Features (SPOnline) ##

<#
Overview: PowerShell Script that enables features (Feature GUID) in a SPO Site via CSOM

Usage: Provide parameters listed below, and the paths to your SharePoint binaries for the CSOM

Provide the required Parameters below in the Script: 

$sUserName: User Name to connect to the SharePoint Online Site Collection
$sPassword: Password for the user 
$sSiteColUrl: SharePoint Online Site Collection 
$sFeatureGuid: GUID of the feature to be enabled 

Provide the paths to your SharePoint DLLs for CSOM under '#Adding the CSOM Assemblies'

Resource: https://gallery.technet.microsoft.com/office/How-to-enable-a-SharePoint-5bb614c7

#>
 
$host.Runspace.ThreadOptions = "ReuseThread" 
 
#Definition of the function that allows to enable a SPO Feature 
function Enable-SPOFeature 
{ 
    param ($sSiteColUrl,$sUserName,$sPassword,$sFeatureGuid) 
    try 
    {     
        #Adding the CSOM Assemblies       
        Add-Type -Path "C:\ztemp\SPDLLs\Microsoft.SharePoint.Client.dll" #Change this path to match your environment
        Add-Type -Path "C:\ztemp\SPDLLs\Microsoft.SharePoint.Client.Runtime.dll"  #Change this path to match your environment
 
        #SPO Client Object Model Context 
        $spoCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sSiteColUrl)  
        $spoCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($sUsername, $sPassword)   
        $spoCtx.Credentials = $spoCredentials       
 
        Write-Host "----------------------------------------------------------------------------"  -foregroundcolor Green 
        Write-Host "Enabling the Feature with GUID $sFeatureGuid !!" -ForegroundColor Green 
        Write-Host "----------------------------------------------------------------------------"  -foregroundcolor Green 
 
        $guiFeatureGuid = [System.Guid] $sFeatureGuid 
        $spoSite=$spoCtx.Site 
        $spoSite.Features.Add($sFeatureGuid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None) 
        $spoCtx.ExecuteQuery() 
        $spoCtx.Dispose() 
    } 
    catch [System.Exception] 
    { 
        write-host -f red $_.Exception.ToString()    
    }     
} 
 
#Required Parameters 
$sSiteColUrl = "https://YourTenantName.sharepoint.com/sites/YourSiteName"  
$sUserName = "User.Name@YourTenantName.onmicrosoft.com"  
$sFeatureGuid= "4bcccd62-dcaf-46dc-a7d4-e38277ef33f4" 
$sPassword = Read-Host -Prompt "Enter your password: " -AsSecureString   
#$sPassword=convertto-securestring "<SPOPassword>" -asplaintext -force 
 
Enable-SPOFeature -sSiteColUrl $sSiteColUrl -sUserName $sUserName -sPassword $sPassword -sFeatureGuid $sFeatureGuid