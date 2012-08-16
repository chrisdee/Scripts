## SharePoint Server: PowerShell Script To Enumerate SharePoint Site Groups And Their Users ##

<#

Overview: PowerShell script to get SharePoint Group Names, Member Counts, and Members

Environments: Works on both MOSS 2007 and SharePoint Server 2010 Farms

Usage: Save PowerShell script as 'EnumSiteGroups.PS1' and run this like the following example: 

./EnumSiteGroups.ps1 "http://URLHere.com"

Or output to file types: 

./EnumSiteGroups.ps1 http://yoursitename.com | out-file "yourfilepath\sharepoint_users.xls"

./EnumSiteGroups.ps1 http://yoursitename.com | out-file "yourfilepath\sharepoint_users.xml"
Or output with a date/time stamp:
$FileName = "YourName_{0:ddMMyyyy-HHmm}" -f (Get-Date)
./EnumSiteGroups.ps1 http://yoursitename.com | out-file "yourfilepath\$FileName.xml"

#>

#Accept the url of the target site collection as a parameter, throw an error if it's not provided

param ([System.String] $siteurl= $(throw"Required siteurl parameter is missing!"))

#Load the required SharePoint assemblies containing the classes used in the script

#The Out-Null cmdlet instructs the interpreter to not output anything to the interactive shell

#Otherwise information about each assembly being loaded would be displayed

[System.Reflection.Assembly]::Load("Microsoft.SharePoint, Version=12.0.0.0 , Culture=Neutral, PublicKeyToken=71e9bce111e9429c") | Out-Null

#Instantiate the SPSite class for the root-level site collection

$rootsite= New-Object -typeName "Microsoft.SharePoint.SPSite" -argumentList $siteurl

#Assign the SPGroupCollection containing all the groups in the site collection to a variable

$rootgroups=$rootsite.RootWeb.SiteGroups

#Dispose of the site object as it's no longer needed

$rootsite.Dispose()

#Uncomment the following line to get a tabular presentation of group names and user counts

#$rootgroups | Select-Object -Property Name, @{Name="Number of Users";Expression = {$_.Users.Count}}

#Instantiate necessary objects and start writing to XML output

$allprincipals=""
$textwriter= New-Object -typeName "System.IO.StringWriter"
$xmlwriter= New-Object -typeName "System.Xml.XmlTextWriter" -argumentList $textwriter
$xmlwriter.Formatting = [System.Xml.Formatting]::Indented
$xmlwriter.WriteStartElement("SiteGroups")
$xmlwriter.WriteAttributeString("Count",$rootgroups.Count)
#Output each group's information
foreach ($group in $rootgroups)
{
$xmlwriter.WriteStartElement("Group")
$xmlwriter.WriteAttributeString("Name",$group.Name)
$xmlwriter.WriteAttributeString("MemberCount",$group.Users.Count)
 
#Output each user's information
foreach ($user in $group.Users)
 
{
$xmlwriter.WriteStartElement("Member")
$xmlwriter.WriteAttributeString("Name",$user.Name)
$xmlwriter.WriteAttributeString("Login",$user.LoginName)
#SPUser object is not disposable, so nullify the variable instead
$user=$null
$xmlwriter.WriteEndElement()
}
#SPGroup object is not disposable, so nullify the variable instead
$group=$null
$xmlwriter.WriteEndElement()
}
#Call Close on the XML writer - this automatically closes all open tags
$xmlwriter.Close()
#Convert the Text Writer object to string and send to standard output
$textwriter.ToString()
