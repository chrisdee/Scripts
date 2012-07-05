###################################################
#
#  SharePoint 2007: Content Database Enumerator
#
#  Author:      	Mattias.Karlsson@zipper.se
#  Homepage:    	www.mysharepointofview.com
#  Company:		www.zipper.se
#
###################################################





#######################################################################################
#
# Function: 		Enum-ContentDatabases
# Description:		Enumerates through all Web application in a SharePoint 2007 
#			farm and export all content databases to a csv or xml file
#			
#		
# Parameters:		[-OutputFormat]	Specify the format of the output file csv | xml
#
#
# Examples:
#
#			Enum-ContentDatabases -OutputFormat xml
#			Writes all content dbs to the xml file Contentdatabases.xml
#			Enum-ContentDatabases -OutputFormat csv
#			Writes all content dbs to the xml file Contentdatabases.csv
#######################################################################################


param([string]$OutputFormat = "xml", [switch]$help)

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: SP-EnumContentDBs
Enumerates through all web application in the farm and listsor export all content databases to file

PARAMETERS: 
-OutputFormat	txt | xml

-help		Displays the help topic

SYNTAX:

SP-EnumContentDBs -OutputFormat xml
Writes all content dbs to a xml file in the current folder

"@
$HelpText

}


function EnumContentDBs($OutputFormat) {
	
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
	
	$WebService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
	$CurPath = PWD
	$CurrentPath = $CurPath.Path
	$FileName = "ContentDatabases"

	# If XML is specified as output format we create the xml-objects and if not we send it to a csv-file
	if($OutputFormat.ToLower() -eq "xml") {

	[xml]$xml = "<ContentDatabases></ContentDatabases>"

$properties = @"
<WebApplication>{0}</WebApplication>
<Name>{1}</Name>
<DBID>{2}</DBID>
<CurrentSiteCount>{3}</CurrentSiteCount>
<MaxSiteCount>{4}</MaxSiteCount>
<WarningSiteCount>{5}</WarningSiteCount>
<IsReadOnly>{6}</IsReadOnly>
<DatabaseServer>{7}</DatabaseServer>
"@

	}
	else{

		"Web Application ; Database Name ; Database ID ; Sites in Database ; Maximum amount of sites in DB; Site level Warning ; Read only ; Database server" | out-file "$FileName.csv" -append	
	
	}

	# Get the propertie types for the content database. If you want to add more properties it's here you can do that and 
	# then also add the new value in section starting on row 118. To find out available properties you can find them here: 
	# http://msdn.microsoft.com/en-us/library/microsoft.sharepoint.administration.spcontentdatabase_properties(v=office.12).aspx
	
	$DBName = [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("Name")
	$DBID = [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("ID")  
	$DBSiteCount = [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("CurrentSiteCount")
	$DBWarningSiteCount = [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("WarningSiteCount")
	$DBMaximumSiteCount = [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("MaximumSiteCount")
	$DBIsReadOnly = [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("IsReadOnly")
	$DBServer= [Microsoft.SharePoint.Administration.SPContentDatabase].GetProperty("ServiceInstance")


	# Enumerate through all Web applications in the farm
	foreach($WebApplication in $WebService.WebApplications){

		$ContentDBCollection = $WebApplication.ContentDatabases

		$webAppName = $WebApplication.name	
		
  			
		# Enumerate through all content databases attached to the Web application
		foreach($ContentDB in $ContentDBCollection){
			
			# Add variables here with any new properties and then add them to the output lines
			$CurrentDBName = $DBName.GetValue($ContentDB, $null)
			$CurrentDBID = $DBID.GetValue($ContentDB, $null)
			$CurrentDBCurrentSiteCount = $DBSiteCount.GetValue($ContentDB, $null)
			$CurrentDBDBMaximumSiteCount = $DBMaximumSiteCount.GetValue($ContentDB, $null)
			$CurrentDBDWarningSiteCount = $DBWarningSiteCount.GetValue($ContentDB, $null)
			$CurrentDBIsReadOnly = $DBIsReadOnly.GetValue($ContentDB, $null)
			$CurrentDBServer = ($DBServer.GetValue($ContentDB, $null)).NormalizedDataSource
			

			# If XML is specified as output format we create the xml-objects and if not we send it to a csv-file
			if($OutputFormat.ToLower() -eq "xml") {
			
				$element = $xml.CreateElement("ContentDatabase")
				$element.InnerXml = $properties -f $webAppName, $CurrentDBName, $CurrentDBID, $CurrentDBCurrentSiteCount, $CurrentDBDBMaximumSiteCount, $CurrentDBDWarningSiteCount , $CurrentDBIsReadOnly, $CurrentDBServer
				[void]$xml["ContentDatabases"].AppendChild($element)
			}
			else {
			
				"$webAppName ; $CurrentDBName ; $CurrentDBID ; $CurrentDBCurrentSiteCount ; $CurrentDBDBMaximumSiteCount ; $CurrentDBDWarningSiteCount ; $CurrentDBIsReadOnly ; $CurrentDBServer" | out-file "$FileName.csv" -append
			
			}
		}
			if($OutputFormat.ToLower() -eq "xml") {
			
				$xml.Save($CurrentPath + "\" + $FileName + ".xml")
			
			}
	}
}

if($help) { GetHelp; Continue }
if($OutputFormat) { EnumContentDBs -OutputFormat $OutputFormat}
else { GetHelp; Continue }
