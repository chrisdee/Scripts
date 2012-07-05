## SharePoint Server 2010: PowerShell Script / Function to Enable Object Cache Access on all Web Applications ##
## Resource: http://blog.isaacblum.com/2011/06/28/enable-object-cache-all-web-applcations
## If your web application is using claims based authentication accounts should be displayed like: i:0#.w|domain\superuser and i:0#w|domain\superreader

#Edit accounts below to suit your environment if you are using claims based authentication
$SuperUserAcc = "i:0#.w|domain\SPSObjectCacheF"
$SuperReaderAcc = "i:0#.w|domain\SPSObjectCacheR"

#Edit accounts below to suit your environment if you are using classic mode authentication
#$SuperUserAcc = "domain\SPSObjectCacheF"
#$SuperReaderAcc = "domain\SPSObjectCacheR"

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$PortalName = Get-SPWebApplication | select DisplayName
 
function Set-WebAppUserPolicy($webApp, $userName,$displayName, $perm) {
    [Microsoft.SharePoint.Administration.SPPolicyCollection]$policies = $webApp.Policies
    [Microsoft.SharePoint.Administration.SPPolicy]$policy = $policies.Add($userName, $displayName)
    [Microsoft.SharePoint.Administration.SPPolicyRole]$policyRole = $webApp.PolicyRoles | where {$_.Name -eq $perm}
    if ($policyRole -ne $null) {
        $policy.PolicyRoleBindings.Add($policyRole)
    }
    $webApp.Update()
}
 
function ConfigureObjectCache
{
	foreach ($p in $PortalName)
	{
		$site = $p.DisplayName
		Try
		{
   			Write-Host -ForegroundColor White "- Applying object cache..."
        		$webapp = Get-SPWebApplication | ? {$_.DisplayName -eq $p.Displayname}
 
        		If ($webapp -ne $Null)
        		{
				Write-Host -ForegroundColor White " - Applying object cache to $site ..."
           			$webapp.Properties["portalsuperuseraccount"] = $SuperUserAcc
	       			Set-WebAppUserPolicy $webApp $SuperUserAcc "Super User (Object Cache)"  "Full Control"
 
           			$webapp.Properties["portalsuperreaderaccount"] = $SuperReaderAcc
	       			Set-WebAppUserPolicy $webApp $SuperReaderAcc "Super Reader (Object Cache)" "Full Read"
           			$webapp.Update()        
    	   			write-Host -ForegroundColor White "- Done."
        		}
		}
		Catch
		{
			$_
			Write-Warning "- An error occurred applying object cache to portal."
		}
	}
}
 
ConfigureObjectCache