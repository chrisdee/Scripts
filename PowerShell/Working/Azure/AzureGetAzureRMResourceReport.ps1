## Azure: PowerShell Script to Perform an Azure Resources Report by Tags ##

<#

Overview: PowerShell Script that reports on Azure Resources according to Tags. Uses the 'Get-AzureRmResource' PowerShell commandlet.

Usage: Edit the following properties / variables and run the script: 'Select-AzureRmSubscription'; '$results'

Requires: AzureRM PowerShell Module

Resources: 

http://harvestingclouds.com/post/script-sample-generate-azure-resources-report-by-tags
https://github.com/HarvestingClouds/PowerShellSamples/blob/a4eb910aa8eb2cdd340c2866cde150282b47067e/Scripts/Azure%20Resources%20Report%20by%20Tags.ps1

#>

#Adding Azure Account and Subscription
Add-AzureRmAccount

#Selecting the Azure Subscription
Select-AzureRmSubscription -SubscriptionName "Microsoft Azure Enterprise" #Change this to match your Azure Subscription Name

#Getting all Azure Resources
$resources = Get-AzureRmResource

#Declaring Variables
$results = @()
$TagsAsString = ""

foreach($resource in $resources)
{
    #Fetching Tags
    $Tags = $resource.Tags
    
    #Checkign if tags is null or have value
    if($Tags -ne $null)
    {
        foreach($Tag in $Tags)
        {
            $TagsAsString += $Tag.Name + ":" + $Tag.Value + ";"
        }
    }
    else
    {
        $TagsAsString = "NULL"
    }

    #Adding to Results
    $details = @{            
                Tags = $TagsAsString
                Name = $resource.Name
                ResourceId = $resource.ResourceId
                ResourceName = $resource.ResourceName
                ResourceType = $resource.ResourceType
                ResourceGroupName =$resource.ResourceGroupName
                Location = $resource.Location
                SubscriptionId = $resource.SubscriptionId 
                Sku = $resource.Sku
        }                           
        $results += New-Object PSObject -Property $details 

    #Clearing Variable
    $TagsAsString = ""
}

$results | export-csv -Path "C:\BoxBuild\Scripts\AzureSubscriptionResources.csv" -NoTypeInformation #Change this path to match your environment
