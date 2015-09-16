## MSOnline: PowerShell Script to Connect to Exchange Online PowerShell Module (o365) ##

Import-PSSession $(New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $(Get-Credential))

##Useful commandlets ##

#Get-UserPhoto "UserName"
#Remove-UserPhoto "UserName"
#Get-DistributionGroup -Identity 'GroupName*'