## SharePoint Server 2010: PowerShell List All SharePoint 2010 PowerShell Commands

Add-PSSnapin "Microsoft.SharePoint.PowerShell"

Get-Command –PSSnapin "Microsoft.SharePoint.PowerShell" | format-table name > C:\SP2010_PowerShell_Commands.txt

Get-Command –PSSnapin "Microsoft.SharePoint.PowerShell" | select name, definition | format-list > C:\SP2010_PowerShell_Commands_Detailed.txt
