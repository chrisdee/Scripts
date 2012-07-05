##SharePoint Server 2010: Set-SPSite Commands to Set Site Collections Access to: Read Only; No Additions; No Access; and Unlock ##
# Note: Also available through Central Admin under 'Central Administration -- Site Collection Quotas and Locks'

Add-PSSnapin "Microsoft.SharePoint.PowerShell"

#Make a SharePoint 2010 Site Collection Read Only. Also locks down the Site Actions Menu

Set-SPSite -Identity "http://myserver/sites/site1" -LockState "ReadOnly"

#Make a SharePoint 2010 Site Collection 'Capped'. No new content - only some modifications on existing content

Set-SPSite -Identity "http://myserver/sites/site1" -LockState "NoAdditions"

#Make a SharePoint 2010 Site Collection Unreachable (Block Access)

Set-SPSite -Identity "http://myserver/sites/site1" -LockState "NoAccess"

#Unlock a SharePoint 2010 Site Collection. Reverses any of the above Commands

Set-SPSite -Identity "http://myserver/sites/site1" -LockState "Unlock"

