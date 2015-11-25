## Azure: PowerShell Commands For Importing and Connecting with the Azure PowerShell Modules (Azure and AzureRM) ##

## Connecting to Azure Service Management ##

Import-Module Azure

Add-AzureAccount

#Get-AzureVM
#Get-AzureWebsite

## Connecting to Azure Resource Management ##

## Dependencies: Windows Management Framework 5.0 | http://www.microsoft.com/en-us/download/details.aspx?id=48729

Import-AzureRM

Login-AzureRmAccount

#Get-AzureRmSubscription
#Get-AzureRmSubscription –SubscriptionName "Microsoft Azure Enterprise" | Select-AzureRmSubscription