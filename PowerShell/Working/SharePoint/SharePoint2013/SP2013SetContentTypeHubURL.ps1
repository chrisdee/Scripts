## SharePoint Server: PowerShell Script To Update The Content Type Hub URL For The Managed Metadata Service ##

## Environments: SharePoint Server 2010 / 2013 Farms

## Resource: http://www.sharepointanalysthq.com/2010/11/how-to-change-the-content-type-hub-url

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$ServiceApplicationName = "Managed Metadata Service" #Change this to match your environment
$ContentTypeHub = "https://contenttypehub.yourdomain.com" #Change this to the path of your Content Type Hub

Set-SPMetadataServiceApplication -Identity $ServiceApplicationName -HubURI $ContentTypeHub