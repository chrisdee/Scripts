## SharePoint Server: PowerShell Script to Activate Features Across All Site Collections and Sites (webs) in a Web Application ##

<#

Overview: PowerShell Script to activate a Feature ID across all Sites in all Site Collections in a Web Application

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the following variables to match your environment and run the script: '$SPWebApplication'; '$SPFeatureID'

Resources:

http://www.smellslikesharepoint.com/2012/06/24/activate-feature-on-all-sites-across-all-site-collections
https://technet.microsoft.com/en-us/library/ee837418.aspx#bkmk_activ_all
http://www.spsdemo.com/Lists/Features/All%20SharePoint%20Features.aspx

#> 

Add-PSSnapin "Microsoft.SharePoint.PowerShell"

### Start Variables ###
$SPWebApplication = "https://YourWebApp.com"
$SPFeatureID = "00bfea71-7e6d-4186-9ba8-c047ac750105"
### End Variables ###

Get-SPWebApplication $SPWebApplication | Get-SPSite -Limit All | Get-SPWeb -Limit ALL | foreach {Enable-SPFeature $SPFeatureID -url $_.URL }
