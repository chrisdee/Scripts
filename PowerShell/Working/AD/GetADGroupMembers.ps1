## PowerShell: Get All Groups And Members Associated With The Groups In Active Directory (AD) ##

## Overview: PowerShell Script that uses the 'ActiveDirectory' PowerShell Module to Get AD Groups and all the Members User Details associated with the Groups

## Usage: Edit the variables below and run the script

## Note: If the query is not returning Group Names 'nested' within the Groups in the ' Get-ADGroupMember' command; remove the '-recursive' property

### Start Variables ###
$distinguishedName = "OU=Groups,OU=YourOU,DC=YourDomain,DC=com"
$displayName = "*A*"
$filePath = "C:\ztemp\ADSecurityGroups.csv"
### End Variables ###

Import-Module ActiveDirectory

$Groups = (Get-AdGroup -filter *  -SearchBase $distinguishedName | Where {$_.name -like $displayName} | select name -expandproperty name)


$Table = @()

$Record = @{
"Group Name" = ""
"Name" = ""
"Username" = ""
}

Foreach ($Group in $Groups)
{

$Arrayofmembers = Get-ADGroupMember -identity $Group -recursive | select name,samaccountname

foreach ($Member in $Arrayofmembers)
{
$Record."Group Name" = $Group
$Record."Name" = $Member.name
$Record."UserName" = $Member.samaccountname
$objRecord = New-Object PSObject -property $Record
$Table += $objrecord

}

}

$Table | export-csv $filePath -NoTypeInformation -Encoding "Default"