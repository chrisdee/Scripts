## Active Directory: PowerShell Script to Get Recently Created Users With CSV Output ##

## Usage: Provide a numeric value to the 'AddDays' property, and provide a path to the 'Export-CSV' command to match your requirements before running the script

Import-Module activedirectory
$When = ((Get-Date).AddDays(-1)).Date #Change the 'AddDays' property to match the number of Days back you want to query
Get-ADUser -Filter {whenCreated -ge $When} -Properties * | Select UserPrincipalName, DisplayName, GivenName, Surname, Title, EmailAddress, Department, OfficePhone, MobilePhone, Office, Company, Enabled, EmployeeNumber, @{N='Manager';E={$_.Manager.Substring($_.Manager.IndexOf("=") + 1, $_.Manager.IndexOf(",") - $_.Manager.IndexOf("=") - 1)}}, WhenCreated | Export-CSV "C:\BoxBuild\Scripts\RecentlyCreatedUsers.csv" -NoTypeInformation -Encoding "Default"
