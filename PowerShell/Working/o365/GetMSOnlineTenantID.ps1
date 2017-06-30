## MSOnline: PowerShell Command to Get you Office 365 (o365) Tenant ID Value (GUID) ##

## Tip: You can also get the Tenant ID from the Azure Active Directory Module under Properties - Directory ID: https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Properties

## Resource: http://tomtalks.uk/2015/09/how-to-get-your-office-365-tenant-id

$TenantPrefix = "YourTenantName" #Change the prefix here to match your tenant name

(Invoke-WebRequest https://login.windows.net/$TenantPrefix.onmicrosoft.com/.well-known/openid-configuration|ConvertFrom-Json).token_endpoint.Split(‘/’)[3]