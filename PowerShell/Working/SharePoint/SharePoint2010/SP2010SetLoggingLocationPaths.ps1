## SharePoint Server: PowerShell Script to Set the Path for Diagnostic Logs (ULS) and Usage and Health Data ##

## Environments: SharePoint Server 201 / 2013 Farms

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

#Configure diagnostic logging path (ULS)
Set-SPDiagnosticConfig -LogLocation "D:\Data\SharePoint\Logs\ULS"

#Configure usage and health data collection
Set-SPUsageService -UsageLogLocation "D:\Data\SharePoint\Logs\Usage"
