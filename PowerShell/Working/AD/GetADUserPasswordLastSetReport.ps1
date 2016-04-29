## Active Directory: PowerShell Script to Check when Users Passwords Were Last Set (Changed) With CSV Output ##

## Usage: Provide a numeric value to the 'AddDays' property, and provide a path to the 'Export-CSV' command to match your requirements before running the script

Import-Module activedirectory
$When = ((Get-Date).AddDays(-30)).Date #Change the 'AddDays' property to match the number of Days back you want to query
Get-ADUser -filter {whenCreated -ge $When} -properties * | sort-object UserPrincipalName | select-object UserPrincipalName, Name, passwordlastset, passwordneverexpires | Export-CSV -path "c:\BoxBuild\RecentUserPassWordChanges.csv" -NoTypeInformation #Change this path to match your environment