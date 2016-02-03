## o365: PowerShell Commands For The Online Services Module ##
## You need to have the Online Services Module installed: http://g.microsoftonline.com/0BX10EN/423

Import-Module MSOnline
Import-Module MSOnlineExtended
# launches the prompt for your 'onmicrosoft.com' account credentials
$cred=Get-Credential
Connect-MsolService -Credential $cred

##Commandlets Resource: http://onlinehelp.microsoft.com/office365-enterprises/hh125002
##Other Resources: 
#http://blogs.technet.com/b/msukucc/archive/2011/08/18/office-365-non-federated-identity-password-never-expires.aspx
#http://community.office365.com/en-us/wikis/sso/2062.aspx

# Get-MsolSubscription
# Get-MsolAccountSku
# Get-MsolAccountSku | Where-Object {$_.SkuPartNumber -eq 'ENTERPRISEPACK'} | ForEach-Object {$_.ServiceStatus}
# Get-MsolDomainFederationSettings
# Get-MsolFederationProperty
# Get-MSOLUser -DomainName YourDomainName.com
# Get-MSOLUser -DomainName YourDomainName.com -all | Select UserPrincipalName, FirstName, LastName, DisplayName, Department, ProxyAddresses, ObjectId, ImmutableId | Format-Table
# Get-MsolUser –UserPrincipalName UserName@YourDomain.onmicrosoft.com | fl 
# Set-MsolUser –UserPrincipalName UserName@YourDomain.onmicrosoft.com -PasswordNeverExpires $True
# Get-MsolCompanyInformation | fl LastDirSyncTime