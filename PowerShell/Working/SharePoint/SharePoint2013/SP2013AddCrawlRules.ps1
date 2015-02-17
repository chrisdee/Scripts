## SharePoint Server: PowerShell Script to Create and Update Crawl Rules from an XML input File ##

<#

Overview: PowerShell Script that takes either 'Inclusion' or 'Exclusion' rules from an XML input file and uses the 'SPEnterpriseSearchCrawlRule' PowerShell commandlets to create / update crawl rules

Environments:

Usage: Create an XML file like the sample below with relevant "InclusionRule" or ExclusionRule" entries. Also provide your SSA name under '<ServiceName>'

Run the script providing the path to the XML file - example: ./SP2013AddCrawlRules.ps1 "SP2013CrawlRules.xml"

﻿<?xml version="1.0" encoding="utf-8"?>
<CrawlRules>
  <ServiceName>Search Service Application</ServiceName>
  <Rules>
    <Rule Type="ExclusionRule" FollowComplexUrls="false" RegularExpression="false">*://*/_catalogs/masterpage/*</Rule>
    <Rule Type="ExclusionRule" FollowComplexUrls="true" RegularExpression="false">*://*siteassets*</Rule>
    <Rule Type="ExclusionRule" FollowComplexUrls="false" RegularExpression="false">*://*/editform.aspx</Rule>
    <Rule Type="ExclusionRule" FollowComplexUrls="false" RegularExpression="false">*://*/dispform.aspx</Rule>
    <Rule Type="InclusionRule" FollowComplexUrls="true" CrawlAsHttp="true" SuppressIndexing="false" RegularExpression="true">http://ExampleSharePointSite</Rule>
  </Rules>
</CrawlRules>

Resources: 

http://sharepointbrainpump.blogspot.ch/2012/10/powershell-howo-creating-and-deleting-crawl-rules.html
https://github.com/Almond-Labs/SP2013-Starter/tree/master/PowerShell

#>


[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$fileName
)

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

write-host "Parsing file: " $fileName
$XmlDoc = [xml](Get-Content $fileName)

#Search Service Application
$sa = $XmlDoc.SearchProperties.ServiceName
$searchapp = Get-SPEnterpriseSearchServiceApplication $sa

#Process Rules
$RuleNodeList = $XmlDoc.CrawlRules.Rules
foreach ($XmlRule in $RuleNodeList.Rule)
{
	$path = $XmlRule.InnerText
	if ((Get-SPEnterpriseSearchCrawlRule -SearchApplication $searchapp -Identity $path -EA SilentlyContinue)) 
	{
	  #Remove Existing Rule
      Write-Host "Rule Removed: " $path
	  Remove-SPEnterpriseSearchCrawlRule -SearchApplication $searchapp -Identity $path -confirm:$false
	}
	
	#Create Rule & Properties
	$complexUrls = [System.Convert]::ToBoolean($XmlRule.FollowComplexUrls)
	$regExp = [System.Convert]::ToBoolean($XmlRule.RegularExpression)
	New-SPEnterpriseSearchCrawlRule -SearchApplication $searchapp -Path $path -Type $XmlRule.Type -IsAdvancedRegularExpression $regExp -FollowComplexUrls $complexUrls
	
    $Rule = Get-SPEnterpriseSearchCrawlRule -SearchApplication $searchapp -Identity $path -EA SilentlyContinue
    if($XmlRule.Type -eq "InclusionRule") {
		#Update additional properties for inclusion rules
        $Rule.CrawlAsHttp = [System.Convert]::ToBoolean($XmlRule.CrawlAsHttp)
        $Rule.SuppressIndexing = [System.Convert]::ToBoolean($XmlRule.SuppressIndexing)
        $Rule.Update()
    }    
}