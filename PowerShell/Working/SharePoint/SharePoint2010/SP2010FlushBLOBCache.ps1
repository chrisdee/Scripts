## SharePoint Server: PowerShell Script To Flush BLOB Cache For Web Applications ##

# Resource: http://technet.microsoft.com/en-us/library/gg277249(v=office.15).aspx

# Environments: SharePoint Server 2010 / 2013 Farms

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$webApp = Get-SPWebApplication "https://webapp.yourdomain.com" #Change the web application name to match your environment

[Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($webApp)

Write-Host "Flushed the BLOB cache for:" $webApp