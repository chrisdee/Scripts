## SharePoint Server 2010: PowerShell Script to flush the BLOB cache in SharePoint Server 2010 Farms ##
## Resource: http://blog.isaacblum.com/2010/12/27/flush-cache-sharepoint-2010-powershell
Write-Host -ForegroundColor White " - Enabling SP PowerShell cmdlets..."
If ((Get-PsSnapin |?{$_.Name -eq "Microsoft.SharePoint.PowerShell"})-eq $null)
{
$PSSnapin = Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null
}
$webAppall = Get-SPWebApplication
foreach ($_.URL in $webAppall) {
$webApp = Get-SPWebApplication $_.URL
[Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($webApp)
Write-Host "Flushed the BLOB cache for:" $webApp
}