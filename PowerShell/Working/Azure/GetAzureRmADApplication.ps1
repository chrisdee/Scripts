## AzureRM: PowerShell Script to Get Azure AD Application Details with Azure Resource Manager ##

Import-Module "AzureRM"

Login-AzureRmAccount

#Get-AzureRmADApplication
#Get-AzureRmADApplication -DisplayNameStartWith "zz" #Change this to match your application Display Name
Get-AzureRmADApplication | Select DisplayName, ReplyUrls | Format-Table