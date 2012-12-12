## SharePoint Server: PowerShell Script To List Details On All Site Templates In A Farm ##
## Environments: SharePoint Server 2010 / 2013 Farms
## Resource: http://get-spscripts.com/2011/02/finding-site-template-names-and-ids-in.html

Add-PSSnapin "Microsoft.Sharepoint.PowerShell" -ErrorAction SilentlyContinue

function Get-SPWebTemplateWithId
{
    $templates = Get-SPWebTemplate | Sort-Object "Name"
    $templates | ForEach-Object {
        $templateValues = @{
            "Title" = $_.Title
            "Name" = $_.Name
            "ID" = $_.ID
            "Custom" = $_.Custom
            "LocaleId" = $_.LocaleId
        }
        New-Object PSObject -Property $templateValues | Select @("Name","Title","LocaleId","Custom","ID")
    }
}

# Examples:
Get-SPWebTemplateWithId | Format-Table
Get-SPWebTemplateWithId | Format-Table | Out-File "C:\BoxBuild\Scripts\PowerShell\SP_Site_Templates.txt"