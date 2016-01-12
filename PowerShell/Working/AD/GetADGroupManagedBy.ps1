## Active Directory: PowerShell Script to Get AD Groups Details Including the Manager (ManagedBy) Property ##

### Start Variables ###
$GroupName = "Sharepoint" #Provide your Group Name filter, or leave blank to report on all Groups in the domain
$ReportPath = "C:\ztemp\Scripts\GetADGroupsReport.csv" #Change this path to match your environment
### End Variables ###

Import-Module ActiveDirectory

Get-ADGroup -filter * -property Managedby | Where {$_.name -like "*$GroupName*"}| select Name, @{N='Managedby';E={$_.Managedby.Substring($_.Managedby.IndexOf("=") + 1, $_.Managedby.IndexOf(",") - $_.Managedby.IndexOf("=") - 1)}} | Export-CSV "$ReportPath" -NoTypeInformation -Encoding "Default"