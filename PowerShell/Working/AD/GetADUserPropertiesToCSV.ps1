## Active Directory: PowerShell Script That Uses The Get-ADUser Commandlet To Retrieve User Properties Against An OU With Output To A CSV File ##

## Resource for Get-ADUser Properties: http://social.technet.microsoft.com/wiki/contents/articles/12037.active-directory-get-aduser-default-and-extended-properties.aspx

## Usage: Change your '-Prop', '-Server', '-SearchBase' parameters to match your requirements and change the path under 'Export-CSV' to match your environment

## Tip: By default the Export-CSV Cmdlet exports the CSV file in ASCII format. To change this to Unicode or UTF8 format use the Encoding parameter: -Encoding "Unicode"

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Get-ADUser -Filter * -Prop GivenName,Surname,SamAccountName,EmailAddress,Description,whenCreated,DistinguishedName -Server "ServerName.ext.YourDomain.com" -SearchBase "OU=External Users,DC=ext,DC=YourDomain,DC=com" |
Export-CSV "C:\BoxBuild\Scripts\ADUsersReport.csv" -NoTypeInformation #Change this path to match your environment with a local drive or network location