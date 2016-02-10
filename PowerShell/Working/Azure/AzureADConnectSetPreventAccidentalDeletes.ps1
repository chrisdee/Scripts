## Azure AD Connect: PowerShell Commands to Configure Accidental Deletion Functionality (Prevent Accidental Deletes) ##

## Resource: http://blog.kloud.com.au/2015/08/05/azure-active-directory-connect-export-profile-error-stopped-server-down

## AAD Connect Commandlets: https://mikecrowley.wordpress.com/2015/10/11/azure-ad-connect-powershell-cmdlets

#Import the Azure AD Connect Sync module

Import-Module ADSync

#Disable / Enable ADSync export deletion threshold

Disable-ADSyncExportDeletionThreshold

#Enable-ADSyncExportDeletionThreshold

#Confirm the status of the 'ADSyncExportDeletionThreshold' property

Get-ADSyncExportDeletionThreshold