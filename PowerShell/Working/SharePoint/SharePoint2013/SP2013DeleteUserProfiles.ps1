## SharePoint Server: PowerShell Script to delete all User Profiles from the User Profile Service Application ##

<#

Overview: Deletes all User Profiles in SharePoint 2010 / 2013 from the User Profile Service Application (UPSA)

Usage: Edit the folowing areas to match your environment and run the script: '$site'; '$AccountName -ne'

Resource: http://gallery.technet.microsoft.com/scriptcenter/Delete-all-User-Profiles-fa4e1428

#>

#Add SharePoint PowerShell SnapIn if not already added 
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { 
    Add-PSSnapin "Microsoft.SharePoint.PowerShell" 
} 
 
 
$site = new-object Microsoft.SharePoint.SPSite("https://mysite.yourdomain.com"); #Change this path to your My Site web application 
$ServiceContext = [Microsoft.SharePoint.SPServiceContext]::GetContext($site);  
 
#Get UserProfileManager from the My Site Host Site context 
$ProfileManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($ServiceContext)    
$AllProfiles = $ProfileManager.GetEnumerator()  
 
foreach($profile in $AllProfiles)  
{  
    $DisplayName = $profile.DisplayName  
    $AccountName = $profile[[Microsoft.Office.Server.UserProfiles.PropertyConstants]::AccountName].Value  
 
    #Do not delete setup (admin) account from user profiles. Please enter the account name below 
    if($AccountName -ne "DOMAIN\spsetup") #Change this account to match your SharePoint farm setup account
    { 
        $ProfileManager.RemoveUserProfile($AccountName); 
        write-host "Profile for account ", $AccountName, " has been deleted" 
    } 
 
}  
write-host "Finished." 
$site.Dispose() 