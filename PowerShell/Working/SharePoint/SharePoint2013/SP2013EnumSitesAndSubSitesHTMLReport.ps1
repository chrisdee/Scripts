## SharePoint Server: PowerShell Script to Produce a HTML Report on All Site Collections and Sub Sites (webs) in a Web Application ##

<#

Overview: PowerShell Script to produce a HTML Report on All Site Collections and Sub Sites (webs) in a Web Application

Environments: SharePoint Server 2013 + Farms

Usage: Edit the '$WebApplication' and '$SitesReport' variables to match your environment in the variables section, and run your script

Resource: http://www.sharepoint-journey.com/get-sitecollection-and-subsite-lastmodifieddate-and-size.html

#>

### Start Variables ###
$WebApplication = "https://YourWebApp"
$SitesReport = "C:\BoxBuild\Scripts\SPSiteCollectionsAndSites.html"
### End Variables ###

Add-PSSnapin microsoft.sharepoint.powershell

#constructing table
                  $a = "<style>"
                  $a = $a + "BODY{background-color:#FFFFFF;}"
                  $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: ;border-collapse: collapse;}"
                  $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#ADD8E6}"
                  $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#F0F0F0}"
                  $a = $a + "</style>"

#Getting the list of site collection from the webapplication and stroing in an array
[array]$sites= get-spwebapplication $WebApplication | get-spsite -Limit All

#Variables
$count=0
$webcount=0

#Looping through each sitecollection
foreach($site in $Sites)
{

		$count=$count + 1
		
		#Getting the site collection Title,Url,Last Modified Date and Size. Later adding that to the html file.
		$site | select @{label = "Title";Ex = {$_.rootweb.Title}} , url , @{label = "LastModifiedDate";Ex = {$_.lastcontentmodifieddate}} , @{label = "size";Ex = {$_.usage.storage/1MB}} | ConvertTo-HTML -head $a -body "<H4>Site Collection :$site</H4>" | Add-content $SitesReport

		#Getting the list of sub sites in a sitecollection
		$Webs= get-spweb -site $site -Limit All
	   
	   #Looping through each sub site
		   foreach($web in $webs)
		   { 

		   #Getting the list details from the site
			$lists= $web.Lists
			$webcount= $webcount +1
			
			#Getting the sub site Url, Title, Template and appedning the details to the created html file.	
			$web | select Url , Title , Webtemplate| ConvertTo-HTML -head $a -body "<H4>Websites in the site collection: $site</H4>" | Add-content $SitesReport

			#Getting the List Name and Last Modified Date which are not hidden
			$lists | where{!($_.Hidden)} | select Title, @{label = "LastModifiedDate";Ex = {$_.LastItemModifiedDate}} | sort -desc LastItemModifiedDate | ConvertTo-HTML -head $a -body "<H4>List details in this: $web</H4>" | Add-content $SitesReport
	   
		add-content $SitesReport "<br>"
		add-content $SitesReport "<b>"
		add-content $SitesReport "<font color=black>"
		add-content $SitesReport "Total Number of Webs in the site collection is $webcount"
		add-content $SitesReport "</font>"
		add-content $SitesReport "</b>"

		add-content $SitesReport "<br>"
		add-content $SitesReport "<b>"
		add-content $SitesReport "<font color=black>"
		add-content $SitesReport "----------------------------------------------------------------------------------------------------------------------------"
		add-content $SitesReport "</font>"
		add-content $SitesReport "</b>"   
	
}

add-content $SitesReport "<br>"
add-content $SitesReport "<b>"
add-content $SitesReport "<font color=black>"
add-content $SitesReport "Total Number of site collection is $count"
add-content $SitesReport "</font>"
add-content $SitesReport "</b>"

}