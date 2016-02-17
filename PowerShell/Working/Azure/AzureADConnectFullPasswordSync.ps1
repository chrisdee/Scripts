## Azure AD Connect: PowerShell Script to Trigger a Full Password Sync in Azure AD Sync (AAD Connect) ##

#Resource: http://social.technet.microsoft.com/wiki/contents/articles/28433.how-to-use-powershell-to-trigger-a-full-password-sync-in-azure-ad-sync.aspx

### Start Variables ###
$adConnector  = "fabrikam.com" #Replace this value with your domain (SourceConnector)
$aadConnector = "aaddocteam.onmicrosoft.com - AAD" #Replace this value with your Connector for your o365 Tenant (TargetConnector)
### End Variables ###

#Check whether Password Sync (password hash) for the SourceConnector domain is enabled
Get-ADSyncAADPasswordSyncConfiguration $adConnector
 
Import-Module adsync

$c = Get-ADSyncConnector -Name $adConnector

$p = New-Object Microsoft.IdentityManagement.PowerShell.ObjectModel.ConfigurationParameter "Microsoft.Synchronize.ForceFullPasswordSync", String, ConnectorGlobal, $null, $null, $null

$p.Value = 1

$c.GlobalParameters.Remove($p.Name)

$c.GlobalParameters.Add($p)

$c = Add-ADSyncConnector -Connector $c
 
Set-ADSyncAADPasswordSyncConfiguration -SourceConnector $adConnector -TargetConnector $aadConnector -Enable $false

Set-ADSyncAADPasswordSyncConfiguration -SourceConnector $adConnector -TargetConnector $aadConnector -Enable $true