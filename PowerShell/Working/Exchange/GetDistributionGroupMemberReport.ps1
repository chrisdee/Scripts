## MS Exchange: PowerShell Script to List / Export All Members of Distribution Lists ##

<#

.OVERVIEW
PowerShell Script that lists Exchange Distribution List Members in the Console or Exports these in CSV Format. Also includes Wild Card filter functionality

.REQUIRES -version 2 Runs in Exchange Management Shell, or with Exchange On-premises / Exchange Online (o365) PowerShell Sessions

.ENVIRONMENTS
Exchange Server 2010 / 2013 and Exchange Online (o365)

.USAGE

1. If the script is called from within the Exchange Management Shell; then comment out the two following 2 PowerShell Session sections:

'On-Premises PSSession'
'Exchange Online PSSession'

2. If the script is to be used for Exchange On-premises; then comment out the following PowerShell Session section:

'Exchange Online PSSession'

3. If the script is to be used for Exchange Online; then comment out the following PowerShell Session section:

'On-Premises PSSession'

Run the script and where required provide your Exchange Administration Credentials

.RESOURCES
http://www.careexchange.in/how-to-export-all-distribution-group-and-all-members-of-it-exchange-2010
https://gallery.technet.microsoft.com/Export-all-distribution-707c27eb

Example 1

[PS] C:\DG>.\DistributionGroupMemberReport.ps1

Distribution Group Member Report
----------------------------

1.Display in Shell

2.Export to CSV File

Choose The Task: 1

DisplayName                   Alias                         Primary SMTP address          Distriubtion Group
-----------                   -----                         --------------------          ------------------
Atlast1                       Atlast1                       Atlast1@targetexchange.in     Test1
Atlast2                       Atlast2                       Atlast2@careexchange.in       Test1
Blink                         Blink                         Blink@targetexchange.in       Test1
blink1                        blink1                        blink1@targetexchange.in      Test1
User2                         User2                         User2@careexchange.in         Test11
User3                         User3                         User3@careexchange.in         Test11
User4                         User4                         User4@careexchange.in         Test11
WithClient                    WithClient                    WithClient@careexchange.in    Test11
Blink                         Blink                         Blink@targetexchange.in       Test11
blink1                        blink1                        blink1@targetexchange.in      Test11

Example 2

[PS] C:\DG>.\DistributionGroupMemberReport.ps1

Distribution Group Member Report
----------------------------

1.Display in Shell

2.Export to CSV File

Choose The Task: 2
Enter the Path of CSV file (Eg. C:\DG.csv): C:\DGmembers.csv

.Author
Written By: Satheshwaran Manoharan

Change Log
V1.0, 11/10/2012 - Initial version

Change Log
V1.1, 02/07/2014 - Added "Enter the Distribution Group name with Wild Card"

Change Log
V1.2, 19/07/2014 - Added "Recipient OU,Distribution Group Primary SMTP address,Distribution Group Managers,Distribution Group OU"
V1.2.1, 19/07/2014 - Added "Option- Enter the Distribution Group name with Wild Card (Display)"
V1.2.2, 19/07/2014 - Added "Fixed "Hashtable-to-Object conversion is not supported in restricted language mode or a Data section"
V1.3,05/08/2014 - Hashtable-to-Object conversion is not supported - Fixed 
V1.4,30/08/2015 - 
Removed For loops - As its not listing distribution groups which has one member.
Added Value for Empty groups. It will list empty groups now as well.
V1.5,09/09/2015 - Progress Bars while exporting to CSV
#>

#----------------------
# On-Premises PSSession
#----------------------

##Create the Exchange On-Premises PowerShell Session (PSSession)
$ExchangeServer = Read-Host "Type the FQDN of your Exchange server"

Write-Host "Connecting to $ExchangeServer"

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer/PowerShell/ -Authentication Kerberos

Import-PSSession $Session

<#

#--------------------------
# Exchange Online PSSession
#--------------------------

##Create the Exchange Online PowerShell Session (PSSession)
Import-PSSession $(New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $(Get-Credential))

#>

#----------------
# Console Menu
#----------------

Write-host "

Distribution Group Member Report
----------------------------

1.Display in Exchange Management / PowerShell Shell

2.Export to CSV File

3.Enter the Distribution Group name with Wild Card (Export)

4.Enter the Distribution Group name with Wild Card (Display)

Dynamic Distribution Group Member Report
----------------------------

5.Display in Exchange Management / PowerShell Shell

6.Export to CSV File

7.Enter the Dynamic Distribution Group name with Wild Card (Export)

8.Enter the Dynamic Group name with Wild Card (Display)"-ForeGround "Cyan"

#----------------
# Script
#----------------

Write-Host "               "

$number = Read-Host "Choose The Task"
$output = @()
switch ($number) 
{

1 {

$AllDG = Get-DistributionGroup -resultsize unlimited
Foreach($dg in $allDg)
 {
$Members = Get-DistributionGroupMember $Dg.name -resultsize unlimited


if($members.count -eq 0)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }
else
{
Foreach($Member in $members)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $member.Alias
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }

}

  }

;Break}

2 {

$i = 0 

$CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\DG.csv)" 

$AllDG = Get-DistributionGroup -resultsize unlimited

Foreach($dg in $allDg)
{
$Members = Get-DistributionGroupMember $Dg.name -resultsize unlimited

if($members.count -eq 0)
{
$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.GroupType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

}
else
{
Foreach($Member in $members)
 {

$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $Member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $Member.Alias
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Member.RecipientType
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Member.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.GroupType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

 }
}
# update counters and write progress
$i++
Write-Progress -activity "Scanning Groups . . ." -status "Scanned: $i of $($allDg.Count)" -percentComplete (($i / $allDg.Count)  * 100)
$output | Export-csv -Path $CSVfile -NoTypeInformation

}

;Break}

3 {

$i = 0 

$CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\DG.csv)" 

$Dgname = Read-Host "Enter the DG name or Range (Eg. DGname , DG*,*DG)"

$AllDG = Get-DistributionGroup $Dgname -resultsize unlimited

Foreach($dg in $allDg)

{

$Members = Get-DistributionGroupMember $Dg.name -resultsize unlimited

if($members.count -eq 0)
{
$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.GroupType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

}
else
{
Foreach($Member in $members)
 {

$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $Member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $Member.Alias
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Member.RecipientType
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Member.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.GroupType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

 }
}
# update counters and write progress
$i++
Write-Progress -activity "Scanning Groups . . ." -status "Scanned: $i of $($allDg.Count)" -percentComplete (($i / $allDg.Count)  * 100)
$output | Export-csv -Path $CSVfile -NoTypeInformation

}

;Break}

4 {

$Dgname = Read-Host "Enter the DG name or Range (Eg. DGname , DG*,*DG)"

$AllDG = Get-DistributionGroup $Dgname -resultsize unlimited

Foreach($dg in $allDg)

 {

$Members = Get-DistributionGroupMember $Dg.name -resultsize unlimited

if($members.count -eq 0)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }
else
{
Foreach($Member in $members)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $member.Alias
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }

}

  }

;Break}

5 {

$AllDG = Get-DynamicDistributionGroup -resultsize unlimited

Foreach($dg in $allDg)

{

$Members = Get-Recipient -RecipientPreviewFilter $dg.RecipientFilter -resultsize unlimited

if($members.count -eq 0)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }
else
{
Foreach($Member in $members)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $member.Alias
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }

}

  }

;Break}

6 {
$i = 0 

$CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\DYDG.csv)" 

$AllDG = Get-DynamicDistributionGroup -resultsize unlimited

Foreach($dg in $allDg)

{

$Members = Get-Recipient -RecipientPreviewFilter $dg.RecipientFilter -resultsize unlimited

if($members.count -eq 0)
{
$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.RecipientType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

}
else
{
Foreach($Member in $members)
 {

$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $Member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $Member.Alias
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Member.RecipientType
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Member.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.RecipientType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

 }
}
# update counters and write progress
$i++
Write-Progress -activity "Scanning Groups . . ." -status "Scanned: $i of $($allDg.Count)" -percentComplete (($i / $allDg.Count)  * 100)
$output | Export-csv -Path $CSVfile -NoTypeInformation

}

;Break}

7 {
$i = 0 

$CSVfile = Read-Host "Enter the Path of CSV file (Eg. C:\DYDG.csv)" 

$Dgname = Read-Host "Enter the DG name or Range (Eg. DynmicDGname , Dy*,*Dy)"

$AllDG = Get-DynamicDistributionGroup $Dgname -resultsize unlimited

Foreach($dg in $allDg)

{

$Members = Get-Recipient -RecipientPreviewFilter $dg.RecipientFilter -resultsize unlimited

if($members.count -eq 0)
{
$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmptyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.RecipientType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

}
else
{
Foreach($Member in $members)
 {

$managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}

$userObj = New-Object PSObject

$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $Member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $Member.Alias
$userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Member.RecipientType
$userObj | Add-Member NoteProperty -Name "Recipient OU" -Value $Member.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
$userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managers.DistributionGroupManagers
$userObj | Add-Member NoteProperty -Name "Distribution Group OU" -Value $DG.OrganizationalUnit
$userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.RecipientType
$userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType

$output += $UserObj  

 }
}
# update counters and write progress
$i++
Write-Progress -activity "Scanning Groups . . ." -status "Scanned: $i of $($allDg.Count)" -percentComplete (($i / $allDg.Count)  * 100)
$output | Export-csv -Path $CSVfile -NoTypeInformation

}

;Break}

8 {

$Dgname = Read-Host "Enter the Dynamic DG name or Range (Eg. DynamicDGname , DG*,*DG)"

$AllDG = Get-DynamicDistributionGroup $Dgname -resultsize unlimited

Foreach($dg in $allDg)

{

$Members = Get-Recipient -RecipientPreviewFilter $dg.RecipientFilter -resultsize unlimited

if($members.count -eq 0)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Alias" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmtpyGroup
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }
else
{
Foreach($Member in $members)
 {
$userObj = New-Object PSObject
$userObj | Add-Member NoteProperty -Name "DisplayName" -Value $member.Name
$userObj | Add-Member NoteProperty -Name "Alias" -Value $member.Alias
$userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $member.PrimarySmtpAddress
$userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
Write-Output $Userobj
 }

}

  }

;Break}

Default {Write-Host "No matches found , Enter Options 1 or 2" -ForeGround "red"}

}