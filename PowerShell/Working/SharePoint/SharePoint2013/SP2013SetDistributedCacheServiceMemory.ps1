## SharePoint Server: PowerShell Script to Configure the Memory Used by the Distributed Cache Service (AppFabric) ##

<#

Overview: PowerShell script that configures the maximum memory to be used for the Distributed Cache Service (AppFabric) service

Environments: SharePoint Server 2013

Usage: Change the MB of the '-cachesize' variable under the 'Set-CacheHostConfig' command to suit your requirements

Quick Tip: Use the PowerShell below to check your current Distributed Cache Service Configuration

Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
Use-CacheCluster
Get-AFCacheHostConfiguration -ComputerName "YourMachineName" -CachePort "22233"

Resource: http://platinumdogs.me/2012/09/24/sharepoint-configure-the-distributed-cache-service-appfabric

#>

Clear-Host
 
# Load SharePoint PowerShell snapin
Write-Host
Write-Host "(1) Verify SharePoint PowerShell Snapin Loaded" -ForegroundColor White
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.PowerShell'}
if ($snapin -eq $null) {
    Write-Host "    ..  Loading SharePoint PowerShell Snapin" -ForegroundColor Gray
    Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
}
Write-Host "    Microsoft SharePoint PowerShell snapin loaded" -ForegroundColor Gray
 
# Load the Active Directory snapin
Write-Host
Write-Host "(2) Verify ActiveDirectory Snapin Loaded" -ForegroundColor White
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'ActiveDirectory'}
if ($snapin -eq $null) {
    Write-Host "    ..  Loading ActiveDirectory Snapin" -ForegroundColor Gray
    Import-Module "ActiveDirectory"
}
Write-Host "    ActiveDirectory snapin loaded" -ForegroundColor Gray
 
Write-Host
Write-Host "(3) Get Fully Qualified Domain Name" -ForegroundColor White
$dnsroot = '.' + (Get-ADDomain).dnsroot
$fqdn = $env:COMPUTERNAME + $dnsroot
Write-Host "    '$fqdn'" -ForegroundColor Gray
 
Write-Host
Write-Host "(4) Configure Distributed Cache Service (AppFabric) Memory" -ForegroundColor White
 
Use-CacheCluster
Write-Host "    Checking..." -ForegroundColor Gray
Get-CacheHostConfig -ComputerName $fqdn -CachePort 22233
 
$instanceName ="SPDistributedCacheService Name=AppFabricCachingService"
$serviceInstance = Get-SPServiceInstance | ? {($_.service.tostring()) -eq $instanceName -and ($_.server.name) -eq $env:computername}
Write-Host "    Got service..." -ForegroundColor Gray
$serviceInstance
Write-Host "    Stopping..." -ForegroundColor Gray
$serviceInstance.Unprovision()
Write-Host "    Configuring..." -ForegroundColor Gray
Set-CacheHostConfig -Hostname $fqdn -cacheport 22233 -cachesize 100 #Change this to suit your environment
Write-Host "    Starting..." -ForegroundColor Gray
$serviceInstance.Provision()
 
Write-Host "    Checking..." -ForegroundColor Gray
Get-CacheHostConfig -ComputerName $fqdn -CachePort 22233
 
Write-Host "    Configured Distributed Cache Service (AppFabric)" -ForegroundColor White