## SharePoint Server: PowerShell Script to Query the Status of the Enterprise Search Service Application ##

## Environments: SharePoint Server 2013 Farms

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$ssa = "Search Service Application" #Change this to match your SSA Name

Get-SPEnterpriseSearchStatus -SearchApplication $ssa -Detailed -Text