## SharePoint Server: PowerShell Script to Report on All Site Collections and Sites in a Web Application ##

<#

Overview: PowerShell Script that uses the 'Get-SPSite' commandlet to retrieve all site collections in a web application, and then uses the 'Get-SPWeb' to list properties for all the Sites and Sub-sites associated with them

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the following variables to match your environment and run the script: "$WebApplication"; "$ReportPath"

Note: To get a full report on all the Properties from the 'Get-SPWeb' commandlet; remove the 'Select' statement from the script

Resource: http://iedaddy.com/2011/11/sharepoint-information-architecture-diagram-using-powershell-and-visio

#>

### Start Variables ###
$WebApplication = "https://yourwebapp.yourorganisation.com"
$ReportPath = "C:\BoxBuild\Scripts\SPSitesReport.csv"
### End Variables ###

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

Get-SPWebApplication $WebApplication | Get-SPSite -Limit All | Get-SPWeb -Limit All | Select Title, URL, ID, ParentWebID, IsRootWeb, WebTemplate, AssociatedOwnerGroup, AssociatedMemberGroup, HasUniquePerm, Created, LastItemModifiedDate | Export-CSV $ReportPath -NoTypeInformation