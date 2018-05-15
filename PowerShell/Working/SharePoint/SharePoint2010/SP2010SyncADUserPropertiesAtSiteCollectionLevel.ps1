##############################################################################################################
###             Sync AD User Properties for each user on a Site Collection using PowerShell                ###
###             Author: Rahul G. Babar                                                                     ###
##############################################################################################################

# Resource: https://sharepoint247.wordpress.com/2012/12/30/how-to-sync-ad-properties-of-users-in-a-sharepoint-site-collection/

$ver = $host | select version
if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Read the Site Collection Url
$siteUrl = Read-Host "Enter Site Collection Url (ex. http://SP2010Server:1234)"
 
if($siteUrl -ne $null -and $siteUrl -ne "")
{
    $siteCollection = Get-SPSite $siteUrl
    if($siteCollection -ne $null)
    {
        foreach($web in $siteCollection.AllWebs)
        {
            Write-Host "Sync AD Properties for users on the web $web.Url"
            foreach($user in $web.AllUsers)
            {   
                Set-SPUser -Identity $user -SyncFromAD  -ErrorAction SilentlyContinue               
            }
        }
        $siteCollection.Dispose();
    }
    else
    {
        Write-Error "Could not find site collection at url $siteUrl."
    }
}
else
{
    Write-Error "Invalid Site Collection Url."  
}