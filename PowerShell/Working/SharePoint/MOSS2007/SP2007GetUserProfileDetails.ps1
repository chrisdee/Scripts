<# SharePoint Server: PowerShell Script To Get Details On A Users Profile From The Object Model

Overview: Powershell script that creates a function to enumerate properties on a user profile against a web application

Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Farms

Usage: Call the function and provide parameters for your web application ($SiteUR) and login ($UserLogin). Add additional user profile properties under #Detailed Data

Usage Example: Get-MOSS-Profile-User-Details "http://myWebApplication" "DOMAIN\Login"

Important: Script must be run with an account that has Farm Administrator rights and permissions

Resource: http://sharepointpsscripts.codeplex.com/releases/view/21699

#>

function Get-MOSS-Profile-User-Details([string]$SiteURL, [string]$UserLogin) 
{ 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server") > $null 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles") > $null 

    $site = new-object Microsoft.SharePoint.SPSite($SiteURL) 

    $srvContext = [Microsoft.Office.Server.ServerContext]::GetContext($site) 
    Write-Host "Status", $srvContext.Status 
    $userProfileManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($srvContext) 

    Write-Host "Profile Count:", $userProfileManager.Count 

    $UserProfile = $userProfileManager.GetUserProfile($UserLogin) 

    #Basic Data 
    Write-Host "[SID]:", $UserProfile["SID"].Value 
    Write-Host "[PreferredName]:", $UserProfile["PreferredName"].Value 
    Write-Host "[Email]:", $UserProfile["WorkEmail"].Value 

    #Detailed Data 
    Write-Host "[USER_NTNAME]:", $UserProfile["AccountName"].Value 
    Write-Host "[USER_SID]:", $UserProfile["SID"].Value 
    Write-Host "[USER_PREFERRED_NAME]:", $UserProfile["PreferredName"].Value 
    Write-Host "[USER_JOB_TITLE]:", $UserProfile["Title"].Value 
    Write-Host "[USER_DPT]:", $UserProfile["Department"].Value 
    Write-Host "[USER_SIP]:", $UserProfile["WorkEmail"].Value 
    Write-Host "[USER_PICTURE]:", $UserProfile["PictureURL"].Value 
    Write-Host "[USER_ABOUTME]:", $UserProfile["AboutMe"].Value 
    Write-Host "[USER_COUNTRY]:", $UserProfile["Country"].Value
    Write-Host "[USER_MANAGER]:", $UserProfile["Manager"].Value

    $site.Dispose() 
} 

cls
