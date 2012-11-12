## SharePoint Server: PowerShell List All SharePoint Server PowerShell Commands (Cmdlets) ##

# Environments: Works on both SharePoint Server 2010 / 2013 Farms

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

Get-Command –PSSnapin "Microsoft.SharePoint.PowerShell" | format-table name > C:\SP_PowerShell_Commands.txt

# Obtaining these with more detail

Get-Command –PSSnapin "Microsoft.SharePoint.PowerShell" | select name, definition | format-list > C:\SP_PowerShell_Commands_Detailed.txt

# Obtaining a count of these

(Get-Command -PSSnapin Microsoft.SharePoint.PowerShell).count
