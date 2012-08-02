## SharePoint Server: PowerShell Script That Uses the 'Hide-SPField' Function To Hide And Unhide SharePoint List Fields Specified In A CSV File ##
## Environments: Works on both MOSS 2007 and SharePoint Server 2010 Farms
## Usage: Create a CSV file with headings for the following fields: listurl,listname,listfield and run your script
## Tip: Use the SQL Query commented below to help you get your 'listurl' and 'listname' data from your Content Databases

## Include a reference to the 'SP2010HideListField.ps1' file containing the 'Hide-SPField' function

. "C:\Scripts\PowerShell\SP2010HideListField.ps1" #Change this path to suit your environment. Important: Note the space after the dot '.'

#Include a path to your CSV file containing the following headings for the fields: listurl,listname,listfield
$ImportFile = Import-Csv "C:\Scripts\PowerShell\fields.csv" #Change this path to suit your environment

ForEach ($field in $ImportFile)
{
#Define your fields from the CSV file
$ListURL = $field.listurl
$ListName = $field.listname
$ListField = $field.listfield
#Now call on the function to hide the fields specified in the CSV file
Hide-SPField -url "$ListURL" -List "$ListName" -Field "$ListField"
}

<#

/* SharePoint: SQL Query to get List URL (listurl) and List Title (listname) data from your content DB */
-- Edit "listurl" to match your web application URL (keep '/' at the end)

-- Common List Template Type Ids --
-- 100 Generic list
-- 101 Document library
-- 102 Survey
-- 103 Links list
-- 104 Announcements list
-- 105 Contacts list
-- 106 Events list
-- 107 Tasks list
-- 108 Discussion board
-- 109 Picture library
-- 110 Data sources
-- 111 Site template gallery
-- 112 User Information list
-- 113 Web Part gallery
-- 114 List template gallery
-- 115 XML Form library

SELECT
"Template Type" = CASE
WHEN [Lists].[tp_ServerTemplate] = 101 THEN 'Doc Lib'
WHEN [Lists].[tp_ServerTemplate] = 115 THEN 'Form Lib'
ELSE 'Unknown'
END,
"listurl" = 'http://YourSharePointApp/' + CASE -- Replace this with your web app url
WHEN [Webs].[FullUrl]=''
THEN [Webs].[FullUrl] + [Lists].[tp_Title]
ELSE [Webs].[FullUrl] + '/' + [Lists].[tp_Title]
END,
[Lists].[tp_Title] as 'listname'
FROM [Lists] LEFT OUTER JOIN [Docs] ON [Lists].[tp_Template]=[Docs].[Id], [Webs]
WHERE ([Lists].[tp_ServerTemplate] = 101 OR [Lists].[tp_ServerTemplate] = 115)
   AND [Lists].[tp_WebId]=[Webs].[Id]
order by "listurl"

#>