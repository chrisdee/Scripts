## MSOnline: PowerShell Script To Assign Service Plan Licenses To Office 365 Users From a CSV File (o365) ##

## Resources: http://exitcodezero.wordpress.com/2013/03/14/how-to-assign-selective-office-365-license-options/comment-page-1; http://social.technet.microsoft.com/wiki/contents/articles/11349.office-365-license-users-for-office-365-workloads.aspx

## Import MSOnline Modules and Connect to the tenant
Import-Module MSOnline
Import-Module MSOnlineExtended
# launches the prompt for your 'onmicrosoft.com' account credentials
$cred=Get-Credential
Connect-MsolService -Credential $cred

## Get the AccountSkuId and license options associated with the tenant Enterprise Plan
Get-MsolAccountSku | ft AccountSkuId,SkuPartNumber
Get-MsolAccountSku | Where-Object {$_.SkuPartNumber -eq 'ENTERPRISEPACK'} | ForEach-Object {$_.ServiceStatus}

## Set the license options required. Any license options not required should be set under '-DisabledPlans'
$MSOnlineLicenses = New-MsolLicenseOptions -AccountSkuId tgf:ENTERPRISEPACK -DisabledPlans YAMMER_ENTERPRISE,RMS_S_ENTERPRISE,MCOSTANDARD,SHAREPOINTWAC,SHAREPOINTENTERPRISE,EXCHANGE_S_ENTERPRISE

## Now set the license plans against the user
#Set-MsolUser -UserPrincipalName "Johannes.Hunger@theglobalfund.org" -UsageLocation "CH"
#Set-MsolUserLicense -UserPrincipalName "Johannes.Hunger@theglobalfund.org" -AddLicenses "tgf:ENTERPRISEPACK" -LicenseOptions $MSOnlineLicenses

$AccountSkuId = "tgf:ENTERPRISEPACK" #Change this to match your 'AccountSkuId'
$UsageLocation = "CH" #Change this to match your usage location (Country Code)
$Users = Import-Csv "C:\ss_vnc\TGF_Employees_Test.csv" #Change this path to the CSV file location
$Users | ForEach-Object {
Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $UsageLocation
Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses $AccountSkuId -LicenseOptions $MSOnlineLicenses
}