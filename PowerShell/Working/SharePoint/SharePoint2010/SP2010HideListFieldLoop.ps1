## SharePoint Server: PowerShell Script That Uses the 'Hide-SPField' Function To Hide And Unhide SharePoint List Fields Specified In A CSV File ##
## Usage: Works on both MOSS 2007 and SharePoint Server 2010 Farms

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