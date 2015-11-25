## Azure: PowerShell Commands For Installing and Importing The Azure PowerShell Modules ##

<# 

Version: Azure PowerShell 1.0 (Preview)

Dependencies: Windows Management Framework 5.0 | http://www.microsoft.com/en-us/download/details.aspx?id=48729

Resources:

https://github.com/Azure/azure-powershell

https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/#Install

https://azure.microsoft.com/en-us/blog/azps-1-0-pre

http://www.microsoft.com/en-us/download/details.aspx?id=48729 (Windows Management Framework 5.0)

#>

## Installing and Importing the Azure PowerShell Modules ##

# Install all of the AzureRM.* modules
Install-Module AzureRM

Install-AzureRM

Install-Module Azure

# Import all of the AzureRM.* modules within the known semantic version range
Import-AzureRM

# Import Azure Service Management
Import-Module Azure