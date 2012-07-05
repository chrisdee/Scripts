################################################################################################
# Name: SP2010CreateGroupsFromCSV.ps1														   #
# Author: Chris Dee																			   #
# Version: 1.0 																				   #
# Date: 10/04/2012                                                                             #
# Comment: PowerShell 2.0 script to                                                            #
# bulk create SharePoint Groups from a csv file                                                #
# Usage: Create a CSV file with these columns: 'Web','GroupName','User','GroupDescription'     #
#        Add your data and set your $FileLocation variable and then run the script             #
# Resource: http://mike-greene.com/2012/01/create-sharepoint-groups-with-powershell            #
################################################################################################

$FileLocation = "C:\BoxBuild\Scripts\Groups.csv" #Columns:'Web','GroupName','User','GroupDescription'

Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

$groups = Import-CSV $FileLocation
foreach ($group in $groups) {
    $web = Get-SPWeb $group.Web
    $user = $web | Get-SPUser $group.User
    $web.SiteGroups.Add($group.GroupName, $user, $user, $group.GroupDescription)
}