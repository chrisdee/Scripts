## Azure AD: PowerShell Script to Create an Azure AD Application, and Create and Assign the Service Principal to it ##

<#

Overview: PowerShell Script to Create an Azure AD Application (New-AzureRmADApplication), and Create (New-AzureRmADServicePrincipal) and Assign (New-AzureRmRoleAssignment) the Service Principal to it with the 'Contributor' role

Usage: Edit the variables listed below under 'Start Variables', and update the '-EndDate' property under the '$azureAdApplication' before running the script

Resources:

https://octopus.com/docs/guides/azure-deployments/creating-an-azure-account/creating-an-azure-service-principal-account
https://blogs.msdn.microsoft.com/azuresqldbsupport/2017/09/01/how-to-create-an-azure-ad-application-in-powershell
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal

Requires: AzureRM PowerShell Modules

#>

# Sign in to Azure
Login-AzureRmAccount
# If your Azure account is on a non-public cloud, make sure to specify the proper environment 
# example for the German cloud:
# Login-AzureRmAccount -EnvironmentName AzureGermanCloud

# If you have multiple subscriptions, uncomment and set to the subscription you want to work with:
# $subscriptionId = "11111111-aaaa-bbbb-cccc-222222222222" #Provide your tenant specific Subscription ID here
# Set-AzureRmContext -SubscriptionId $subscriptionId

# Provide these values for your new Azure AD app:
# $appName is the display name for your app, must be unique in your directory
# $uri does not need to be a real URI
# $secret is a password you create (Also known as the 'Client Secret')

## Start Variables ##
$appName = "YourAppName"
$uri = "https://YourAppURL"
$secret = "YourClientSecret" #Important: Keep this 'Client Secret' value safe as it can't be viewed via the Azure Portal
## End Variables ##

# Create the Azure AD app
Write-Output "Creating the Azure AD app"
$azureAdApplication = New-AzureRmADApplication -DisplayName $appName -HomePage $Uri -IdentifierUris $Uri -Password $secret -EndDate (new-object System.DateTime 2020, 12, 31) #Change this End Date to match your requirements

# Create a Service Principal for the app
Write-Output "Creating the Service Principal for the app"
$svcprincipal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

# Sleep, to ensure the Service Principal is actually created
Write-Output "Sleeping for 15 seconds to give the Service Principal a chance to finish creating..."
Start-Sleep -s 15

# Assign the Contributor RBAC role to the Service Principal
# If you get a PrincipalNotFound error: wait another 15 seconds, then rerun the following until successful
Write-Output "Assigning the Contributor role to the Service Principal"
$roleassignment = New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $azureAdApplication.ApplicationId.Guid

# Display the values for your application 
Write-Output "Save these values for use in your application:"
Write-Output "Subscription ID:" (Get-AzureRmContext).Subscription.SubscriptionId
Write-Output "Tenant ID:" (Get-AzureRmContext).Tenant.TenantId
Write-Output "Application ID:" $azureAdApplication.ApplicationId.Guid
Write-Output "Application Secret:" $secret