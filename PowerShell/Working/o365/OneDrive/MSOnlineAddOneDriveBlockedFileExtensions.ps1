## Office 365: PowerShell Function to Get the latest Ransomware File Extensions from the FSRM API, And Adds them to your Tenant One Drive for Business Blocked Files list ##

<#
    .Synopsis
        Gets the latest ransomware file extensions from 'https://fsrm.experiant.ca/api/v1/get'. Includes functionality to add the list to your tenant One Drive for Business Blocked Files list - https://admin.onedrive.com/?v=SyncSettings
    .EXAMPLE
        Get-SPORansomWareFileExtensionBlackList
    .EXAMPLE
        $credential = Get-Credential
        $sharepointUrl = 'https://<tenantVanityDomian>-admin.sharepoint.com/'

        # Connect to SharePoint
        Connect-SPOService –url $sharepointUrl -Credential $credential

        # Set File Extenstion Restriction
        Set-SPOTenantSyncClientRestriction -ExcludedFileExtensions ((Get-SPORansomWareFileExtensionBlackList) -join ';' )
    .NOTES
        Written by Ben Taylor
        Version 1.0, 24.01.2017


     .RESOURCES

        https://bentaylor.work/2017/04/powershell-office-365-onedrive-sync-client-block-known-ransomware-file-types
        https://fsrm.experiant.ca
        https://github.com/nexxai/CryptoBlocker
    #>

function Get-SPORansomWareFileExtensionBlackList
{
    
    [CmdletBinding()]
    Param()

    Write-Verbose 'Getting up to date ransomware file extensions'
    $cryptoFileExtensions = Invoke-WebRequest -Uri "https://fsrm.experiant.ca/api/v1/get" | Select-Object -ExpandProperty content | ConvertFrom-Json | Select-Object -ExpandProperty filters 

    ForEach($cryptoFileExtension in $cryptoFileExtensions)
    {
        Write-Verbose 'Sorting extension from files'
        if($cryptoFileExtension.Substring(2) -match "^[a-zA-Z0-9]*$")
        {
            if('' -ne $cryptoFileExtension.Substring(2))
            {
                $cryptoFileExtension.Substring(2)
            }
        }
    }
}

Get-SPORansomWareFileExtensionBlackList

$credential = Get-Credential

$sharepointUrl = 'https://YourTenant-admin.sharepoint.com/' #Change the tenant prefix here to match your o365 tenant

# Connect to SharePoint
Connect-SPOService –url $sharepointUrl -Credential $credential

# Set File Extenstion Restriction
Set-SPOTenantSyncClientRestriction -ExcludedFileExtensions ((Get-SPORansomWareFileExtensionBlackList) -join ';' )
