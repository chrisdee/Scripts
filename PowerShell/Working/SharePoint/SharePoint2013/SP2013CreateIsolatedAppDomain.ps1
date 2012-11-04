## SharePoint Server 2013: PowerShell Script To Provision An Isolated App Domain For Custom Applications ##

<#

Overview: The script below provisions your 'App Management Service' and 'Subscription Settings Service Application' service apps,
and also configures an Isolated App Domain for your on-premise farm.

Usage: Run the script and when prompted provide details for the following variables; '$appdomain', '$login' (provide a managed account for this).

Important: You will also need to configure your DNS settings for the new App Domain as per the last resource link below

Resources: http://tomvangaever.be/blogv2/2012/08/prepare-sharepoint-2013-server-for-app-development-create-an-isolated-app-domain
           http://msdn.microsoft.com/en-us/library/fp179923(v=office.15).aspx
           http://sharepointchick.com/archive/2012/07/29/setting-up-your-app-domain-for-sharepoint-2013.aspx
 #>

# Check if the execution policy is set to Unrestricted
$policy = Get-ExecutionPolicy
if($policy -ne "Unrestricted"){
	Set-ExecutionPolicy "Unrestricted"
}

# Check if current script is running under administrator credentials
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
if ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ) -eq $false) { 
	(get-host).UI.RawUI.Backgroundcolor="DarkRed" 
	clear-host 
	write-host "Warning: PowerShell is not running as an Administrator.`n" 
	exit
}

# Load SharePoint powershell commands
Add-PSSnapin "microsoft.sharepoint.powershell" -ErrorAction SilentlyContinue

cls

# Ensure that the spadmin and sptimer services are running
Write-Host
Write-Host "Ensure that the spadmin and sptimer services are running" -ForegroundColor Yellow
net start spadminv4
net start sptimerv4

# Create your isolated app domain by running the SharePoint Management Shell as an administrator and typing the following command.
Write-Host
Write-Host "Create your isolated app domain by running the SharePoint Management Shell as an administrator and typing the following command." -ForegroundColor Yellow
$appdomain = Read-Host "Your App Domain Name"
Set-SPAppDomain $appdomain

# Ensure that the SPSubscriptionSettingsService and AppManagementServiceInstance services are running 
Write-Host
Write-Host "Ensure that the SPSubscriptionSettingsService and AppManagementServiceInstance services are running." -ForegroundColor Yellow
Get-SPServiceInstance | where{$_.GetType().Name -eq "AppManagementServiceInstance" -or $_.GetType().Name -eq "SPSubscriptionSettingsServiceInstance"} | Start-SPServiceInstance

# Verify that the SPSubscriptionSettingsService and AppManagementServiceInstance services are running 
Write-Host
Write-Host "Verify that the SPSubscriptionSettingsService and AppManagementServiceInstance services are running." -ForegroundColor Yellow
Get-SPServiceInstance | where{$_.GetType().Name -eq "AppManagementServiceInstance" -or $_.GetType().Name -eq "SPSubscriptionSettingsServiceInstance"}

# Specify an account, application pool, and database settings for the SPSubscriptionService and AppManagementServiceInstance services 
Write-Host
Write-Host "Specify an account, application pool, and database settings for the SPSubscriptionService and AppManagementServiceInstance services." -ForegroundColor Yellow
$login = Read-Host "The login of a managed account"
$account = Get-SPManagedAccount $login 
$appPoolSubSvc = New-SPServiceApplicationPool -Name SettingsServiceAppPool -Account $account
Write-Host "SettingsServiceAppPool created (1/6)" -ForegroundColor Green
$appPoolAppSvc = New-SPServiceApplicationPool -Name AppServiceAppPool -Account $account
Write-Host "AppServiceAppPool created  (2/6)" -ForegroundColor Green
$appSubSvc = New-SPSubscriptionSettingsServiceApplication –ApplicationPool $appPoolSubSvc –Name SettingsServiceApp –DatabaseName SettingsServiceDB 
Write-Host "SubscriptionSettingsServiceApplication created  (3/6)" -ForegroundColor Green
$proxySubSvc = New-SPSubscriptionSettingsServiceApplicationProxy –ServiceApplication $appSubSvc
Write-Host "SubscriptionSettingsServiceApplicationProxy created  (4/6)" -ForegroundColor Green
$appAppSvc = New-SPAppManagementServiceApplication -ApplicationPool $appPoolAppSvc -Name AppServiceApp -DatabaseName AppServiceDB
Write-Host "AppManagementServiceApplication created  (5/6)" -ForegroundColor Green
$proxyAppSvc = New-SPAppManagementServiceApplicationProxy -ServiceApplication $appAppSvc
Write-Host "AppManagementServiceApplicationProxy created  (6/6)" -ForegroundColor Green

# Specify your tenant name 
write-host
Write-Host "Set AppSiteSubscriptionName to 'app'" -ForegroundColor Yellow
Set-SPAppSiteSubscriptionName -Name "app" -Confirm:$false
Write-Host "AppSiteSubscriptionName set" -ForegroundColor Green

# Disable the loopbackcheck in the registry
Write-Host "Disable the loopbackcheck in the registry" -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name "DisableLoopbackCheck" -PropertyType DWord -Value 1

Write-Host "Completed"