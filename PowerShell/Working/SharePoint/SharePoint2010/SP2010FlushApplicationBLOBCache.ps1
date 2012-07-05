## SharePoint Server 2010: PowerShell Script to flush the BLOB cache for a Web Application ##
## Resource: http://technet.microsoft.com/en-us/library/gg277249.aspx

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$webApp = Get-SPWebApplication "<WebApplicationURL>" #Change this URL to match your environment
[Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($webApp)
Write-Host "Flushed the BLOB cache for:" $webApp
