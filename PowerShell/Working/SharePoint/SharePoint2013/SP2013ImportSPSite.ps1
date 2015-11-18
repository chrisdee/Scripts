## SharePoint Server: PowerShell Script to Import Sites (Import-SPWeb) as CMP Object Files with additional CSV Reporting ##

<#
.SYNOPSIS
    Take the export from ExportSPSite.PS1 and import it back into
    a Sharepoint site.
.DESCRIPTION
    Use this script to take the exported files from ExportSPSite.ps1,
    creates a new site in a Sharepoint site and imports the data into
    that new site.
.PARAMETER ImportPath
    Is the path name where the export files are located.  Requires
    the CMP files from ExportSPSite.ps1 and the Site.TXT file.
.PARAMETER Search
    The Site.TXT file contains the URL for the exported path, but this
    is unlikely to be the destination on your Sharepoint site import.
    Use this parameter to designate the portion of the old site that
    you want to replace.  This is a string replace.
.PARAMETER ReplaceWith
    This is the new text you want to replace.  Example:
    
    Old Site:  Http://sharepoint/site
    New Site:  Http://SurlySharepoint/site
    
    so 
    
    Search = sharepoint
    ReplaceWith = SurlySharepoint

.PARAMETER RootSite
    Full URL for the root of your Sharepoint site
.PARAMETER AddToTopNav
    Specify this parameter if you want the new site that is created
    to appear in the Top Navigation bar.
.PARAMETER UseParentTopNav
    Specify this parameter if you want the new site that is created
    to use the Top Navigation bar from the parent site.
.PARAMETER AddToQuickLaunch
    Specify this parameter if you want the new site that is created
    to appear in the Quick Launch section of the web site.
.INPUTS
    None
.OUTPUTS
    Sharepoint Site
    CSV - SPListImportReport.csv - Report with document counts for all 
          document libraries in the new site and all sub-sites
.EXAMPLE
    ./ImportSPSite.ps1 -ImportPath "E:\Exports\IT" -Search "SurlySharepoint" -ReplaceWith "NewSharepoint/Operations" -RootSite "http://NewSharepoint" -AddToQuickLaunch -UseParentTopNav
    
    Import Sharepoint site from the E:\Exports\IT folder, and since the Export
    came from my old Http://SurlySharepoint/it server and I want to go to my
    new http://NewSharepoint server, but I want the IT site to be under the new
    Operations site I will search for "SurlySharepoint" and replace it with
    "NewSharepoint/Operations".  This will leave a final site of:
    http://NewSharepoint/Operations/IT.  My new root site is http://NewSharepoint
    (and we'll need that for getting document counts on the newly imported site).
    Last I want this new site to be in the Quick Launch section, and I want to use
    the Top Navigation Bar from the parent Operations site for a consistent interface.
.NOTES
    Author:            Martin Pugh
    Twitter:           @thesurlyadm1n
    Spiceworks:        Martin9700
    Blog:              www.thesurlyadmin.com
       
    Changelog:
       1.0             Initial Release
.LINK
       http://community.spiceworks.com/scripts/show/1837-import-spsite-import-sharepoint-site
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param (
    [Parameter(Mandatory=$true)]
    [string]$ImportPath,
    [string]$Search = "Sharepoint",
    [string]$ReplaceWith = "SurlySharepoint/it",
    [string]$RootSite = "http://SurlySharepoint",
    [switch]$AddToTopNav,
    [switch]$UseParentTopNav,
    [switch]$AddToQuickLaunch
)
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

cls
#Test that Path points to a valid Sharepoint export folder
If (-not (Test-Path $ImportPath\site.txt))
{   Write-Host "Unable to locate ""site.txt"" at $ImportPath, aborting script!" -ForegroundColor Red
    Break
}

#Get site.txt information
$Site = Get-Content $ImportPath\site.txt
$NewSite = $Site.Replace($Search,$ReplaceWith)

#Validate site doesn't already exist
Write-Verbose "Old Site: $Site"
Write-verbose "New Site: $NewSite"
Write-Verbose "Checking if destination site exists, error message with Get-SPWeb is good!`n"
$Webs = Get-SPWeb $NewSite
If ($Webs)
{   Write-Host "Site already exists: $NewSite.  Aborting Script" -ForegroundColor Red
    Break
}

#Create new site
$NewWebParameters = @{
    AddToQuickLaunch = $AddToQuickLaunch
    AddToTopNav = $AddToTopNav
    UseParentTopNav = $UseParentTopNav
}
Write-Verbose "Creating new site at: $NewSite..."
New-SPWeb -Url $NewSite @NewWebParameters

#Import site
Write-Verbose "`n`nImporting data to new site...`n"
Import-SPWeb -Identity $NewSite -Path $ImportPath\site.cmp -IncludeUserSecurity:$true -Force:$true

#Now get document counts on new site which you can validate against the old site report
$Webs = Get-SPWeb -Site $RootSite -Filter { $_.Template -like "*" } -Limit ALL | Where { $_.URL -like "$NewSite*" }
$Result = @()
ForEach ($Web in $Webs)
{   ForEach ( $List in $Web.Lists )
    {   $Result += New-Object PSObject -Property @{
            'Library Title' = $List.Title
            Count = $List.Folders.Count + $List.Items.Count
            'Site Title' = $Web.Title
            URL = $Web.URL
            'Library Type' = $List.BaseType
        }
    }
}
$Result | Select 'Site Title',URL,'Library Type','Library Title',Count | Export-Csv "$ImportPath\SPImportListReport.csv" -NoTypeInformation
$Result | Select 'Site Title',URL,'Library Type','Library Title',Count | Out-GridView