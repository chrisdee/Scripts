## SharePoint Online: PowerShell Script to Provision Personal Sites (MySite) for One Drive For Business (OD4B) via CSV File Input (SPOnline) ##

<#

Overview: PowerShell Script that provisions user Personal Sites for MySite / One Drive For Business via a CSV File. Uses the 'Request-SPOPersonalSite' SPOnline PowerShell commandlet

Usage:

- Create and save a CSV file with a column called 'User' like the example below

User
User1.Name1@YourDomain.com
User2.Name2@YourDomain.com
User3.Name3@YourDomain.com

- Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix

- Provide the path to the CSV file with user email address (logins) values in the '$InputFilePath' variable

Note: The 'Request-SPOPersonalSite' cmdlet requests that the users specified be enqueued so that a Personal Site be created for each. The actual Personal site is created by a Timer Job later.

Resource: https://technet.microsoft.com/en-us/library/dn792367.aspx

#>

Import-Module "Microsoft.Online.Sharepoint.PowerShell" -ErrorAction SilentlyContinue
$credential = Get-credential 
Connect-SPOService -url https://contoso-admin.sharepoint.com -Credential $credential

$InputFilePath = "C:\BoxBuild\Scripts\SPOnlineUsers.csv" #Change this to match your environment

$CsvFile = Import-Csv $InputFilePath

ForEach ($line in $CsvFile)

{ 

Request-SPOPersonalSite -UserEmails $line.User -NoWait

Write-Host Personal site provisioned for $line.User -ForegroundColor Yellow

}