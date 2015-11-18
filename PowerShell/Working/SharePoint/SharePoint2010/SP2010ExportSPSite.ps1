## SharePoint Server: PowerShell Script to Export Sites (Export-SPWeb) as CMP Object Files with additional CSV Reporting ##

<#
.SYNOPSIS
    Export a designated Sharepoint site (web) to file, includes a
    CSV report for document counts
.DESCRIPTION
    This script will export a Sharepoint site that you designate
    to files in a folder you specify.  It will include a small
    CSV report with document counts so you can verify that the
    export worked later after you re-import it.  A directory named
    after the site you are exporting will be created in the specified
    path.  If that directory already exists the script will abort.
    
    Script must be run on the Sharepoint server.
.PARAMETER Site
    Full URL of the site you want to report on.  
.PARAMETER RootSite
    Full URL for the root of your Sharepoint site
.PARAMETER ExportPath
    Full path of the directory you want to save the export
    files and CSV report.
.INPUTS
    None
.OUTPUTS
    CMP files - Sharepoint export files
    CSV - SPExportListReport.CSV document count report
    site.txt - text file with the URL of the exported site
               in it.  To be used with Import-SPSite.ps1
.EXAMPLE
    ./ExportSPSite.ps1 -Site "http://SurlySharepoint/IT" -RootSite "http://SurlySharepoint" -ExportPath "E:\Exports"
    Export the IT site to E:\Exports\IT from the SurlySharepoint
    Sharepoint server.  All output will be automatically saved in 
    E:\Exports\IT
.NOTES
    Author:            Martin Pugh
    Twitter:           @thesurlyadm1n
    Spiceworks:        Martin9700
    Blog:              www.thesurlyadmin.com
       
    Changelog:
        1.01            Minor change to document count report name to match
                        Import-SPSite.PS1 naming scheme
        1.0             Initial Release
.LINK
        http://community.spiceworks.com/scripts/show/1824-export-spsite-export-a-sharepoint-site-to-file
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [string]$Site,
    [string]$RootSite = "http://sharepoint",
    [string]$ExportPath = "E:\Exports"
)
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

cls
#Validate site
$Webs = Get-SPWeb $Site
If (-not $Webs)
{   Write-Host "$Site does not exist, aborting script!" -ForegroundColor Red
    Break
}
$Webs.Dispose()

#Export site and sub-sites
$Dir = $Site.Split("/")[-1]
If (Test-Path "$ExportPath\$Dir")
{   Write-Host "Export directory already exists, aborting script!" -ForegroundColor Red
    Break
}
Write-Verbose "Exporting site to $ExportPath\$Dir..."
New-Item -Path "$ExportPath\$Dir" -ItemType Directory | Out-Null
Export-SPWeb -Identity $Site -Path "$ExportPath\$Dir\site.cmp" -IncludeUserSecurity:$true -IncludeVersions ALL 
Set-Content -Value $Site -Path "$ExportPath\$Dir\site.txt"

#Get document counts for site and all sub-sites
Write-Verbose "Gathering document and list counts..."
$Webs = Get-SPWeb -Site $RootSite -Filter { $_.Template -like "*" } -Limit ALL | Where { $_.URL -like "$site*" }
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

$Result | Select 'Site Title',URL,'Library Type','Library Title',Count | Export-CSV "$ExportPath\$Dir\SPExportListReport.csv" -NoTypeInformation
$Result | Select 'Site Title',URL,'Library Type','Library Title',Count | Out-GridView