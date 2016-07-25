## Active Directory: PowerShell Script To Get / Remove / Add / Compare Group Membership in AD ##

<#

Overview: PowerShell Script To Get / Remove / Add / Compare Group Membership in AD

Requires: ActiveDirectory PowerShell Module

Usage: Edit the variables below to match your requirements and run the script

Resources:

http://tommymaynard.com/quick-learn-remove-and-add-users-to-an-active-directory-group-2016

http://www.morgantechspace.com/2014/05/Add-AD-Group-Members-using-Powershell-Script.html

#>

Import-Module "ActiveDirectory"

### Start Variables ###
$GroupName = "zzTestGroup" #Provide your AD Group Name here
$CurrentMembers = "C:\BoxBuild\Scripts\zzTestGroup_Current.csv" #Provide the path to the file for a report on the Current group members
$NewMembers = "C:\BoxBuild\Scripts\zzTestGroup_New.csv" #Provide the path to the file of new / edited group members
$AddedMembers = "C:\BoxBuild\Scripts\zzTestGroup_Added.csv" #Provide the path to the file for a report on the New group members
### End Variables ###

## Extract Current AD Group Membership
Get-ADGroupMember -Identity $GroupName | Export-Csv -Path $CurrentMembers  -NoTypeInformation

## Remove Members fom the Current AD Group
Get-ADGroupMember -Identity $GroupName | Foreach-Object {Remove-ADGroupMember -Identity $GroupName -Members $_ -Confirm:$false}

## Add 'New' Members back to the Group
Import-Csv -Path $NewMembers | ForEach-Object { $samAccountName = $_."samAccountName" 
Add-ADGroupMember $GroupName $samAccountName; Write-Host "- "$samAccountName" added to "$GroupName}

## Extract New AD Group Membership
Get-ADGroupMember -Identity $GroupName | Export-Csv -Path $AddedMembers  -NoTypeInformation

## Compare the Extract of Original Group Members against the new one for changes
Compare-Object -ReferenceObject ((Import-Csv -Path $CurrentMembers).SamAccountName) -DifferenceObject ((Import-Csv -Path $AddedMembers).SamAccountName) -IncludeEqual
