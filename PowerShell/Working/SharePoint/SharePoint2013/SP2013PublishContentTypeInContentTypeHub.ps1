## SharePoint Server: PowerShell Function to Force a Publish of Content Types in a Content Type Hub ##

<#

Overview: When working with a Content Type Hub and Multiple Content Types it can be time consuming to have to Publish / Republish these changes via 'Manage publishing for this content type'

The PowerShell function below essentially takes the URL of the Content Type Hub site collection in your Farm along with the Content Type Group Name and forces a Publish / Republish of this

Environments: SharePoint Server 2010 / 2013 Farms

Usage Example: Publish-ContentTypeHub "[URL to CTH]" "[Group Name Containing Content Types]"

Resource: http://www.mice-ts.com/force-a-publish-of-content-types-in-a-content-type-hub-using-powershell

#>

Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

function Publish-ContentTypeHub {
    param
    (
        [parameter(mandatory=$true)][string]$CTHUrl,
        [parameter(mandatory=$true)][string]$Group
    )
 
    $site = Get-SPSite $CTHUrl
    if(!($site -eq $null))
    {
        $contentTypePublisher = New-Object Microsoft.SharePoint.Taxonomy.ContentTypeSync.ContentTypePublisher ($site)
        $site.RootWeb.ContentTypes | ? {$_.Group -match $Group} | % {
            $contentTypePublisher.Publish($_)
            write-host "Content type" $_.Name "has been republished" -foregroundcolor Green
        }
    }
}