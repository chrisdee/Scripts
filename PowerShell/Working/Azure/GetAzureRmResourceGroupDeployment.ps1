## Azure: Useful Azure RM Resource Group Deployment Commands (AzureRMResourceGroupDeployment) ##

## Resource: https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/?view=azurermps-5.3.0

# Get Azure RM Resource Group Deployment Details
Get-AzureRmResourceGroupDeployment -ResourceGroupName "YourResourceGroupName"
Get-AzureRmResourceGroupDeployment -ResourceGroupName "YourResourceGroupName" | Select DeploymentName, ResourceGroupName, ProvisioningState

# Stop Azure RM Resource Group Deployment
Stop-AzureRmResourceGroupDeployment -ResourceGroupName "YourResourceGroupName" -Name "YourDeploymentName"