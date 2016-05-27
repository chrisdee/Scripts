<#   
.SYNOPSIS
Script that compares group membership of source users and destination user and adds destination user to source user group 
    
.DESCRIPTION
This script compares the group membership of $sourceacc and $destacc, based on the membership of the source account the destination account is also to these groups. Script outputs actions taken to the prompt. The script can also be run without any parameters then the script will prompt for both usernames.
 
.PARAMETER Sourceacc
User of which group membership is read

.PARAMETER DestAcc
User that becomes member of all the groups that Sourceacc is member of

.PARAMETER MatchGroup
Supports regular expressions, uses the -match operator to make a select a subset of source user groups to copy to the destination user
    
.PARAMETER Noconfirm
No user input is required and the script runs automatically

.NOTES
Name: CompareADuserAddGroup.ps1
Author: Jaap Brasser
Version: 1.2.0
DateCreated: 2012-03-14
DateUpdated: 2016-01-12

.EXAMPLE
.\CompareADuserAddGroup.ps1 testuserabc123 testuserabc456

Description 
-----------     
This command will add testuserabc456 to all groups that testuserabc123 is a memberof with the exception of all groups testuserabc456 is already a member of.

.EXAMPLE   
.\CompareADuserAddGroup.ps1 -SourceAcc testuserabc123 -DestAcc testuserabc456 -MatchGroup 'FS_'

Description 
-----------     
This command will add testuserabc456 to the groups that contain the FS_ string that testuserabc123 is a memberof with the exception of all groups testuserabc456 is already a member of.
#>
param(
    [Parameter(Mandatory=$true)]
    [string] $SourceAcc,
    [Parameter(Mandatory=$true)]
    [string] $DestAcc,
    [string] $MatchGroup,
    [switch] $NoConfirm
)

# Retrieves the group membership for both accounts
$SourceMember = Get-AdUser -Filter {samaccountname -eq $SourceAcc} -Property memberof | Select-Object memberof
$DestMember   = Get-AdUser -Filter {samaccountname -eq $DestAcc  } -Property memberof | Select-Object memberof

# Checks if accounts have group membership, if no group membership is found for either account script will exit
if ($SourceMember -eq $null) {'Source user not found';return}
if ($DestMember -eq $null)   {'Destination user not found';return}

# Uses -match to select a subset of groups to copy to the new user
if ($MatchGroup) {
    $SourceMember = $SourceMember | Where-Object {$_.memberof -match $MatchGroup}
}

# Checks for differences, if no differences are found script will prompt and exit
if (-not (Compare-Object $DestMember.memberof $SourceMember.memberof | Where-Object {$_.sideindicator -eq '=>'})) {write-host "No difference between $SourceAcc & $DestAcc groupmembership found. $DestAcc will not be added to any additional groups.";return}

# Routine that changes group membership and displays output to prompt
compare-object $DestMember.memberof $SourceMember.memberof | where-object {$_.sideindicator -eq '=>'} |
Select-Object -expand inputobject | foreach {write-host "$DestAcc will be added to:"([regex]::split($_,'^CN=|,OU=.+$'))[1]}

# If no confirmation parameter is set no confirmation is required, otherwise script will prompt for confirmation
if ($NoConfirm)	{
    compare-object $DestMember.memberof $SourceMember.memberof | where-object {$_.sideindicator -eq '=>'} | 
    Select-Object -expand inputobject | foreach {add-adgroupmember "$_" $DestAcc}
}

else {
    do{
        $UserInput = Read-Host "Are you sure you wish to add $DestAcc to these groups?`n[Y]es, [N]o or e[X]it"
        if (('Y','yes','n','no','X','exit') -notcontains $UserInput) {
            $UserInput = $null
            Write-Warning 'Please input correct value'
        }
        if (('X','exit','N','no') -contains $UserInput) {
            Write-Host 'No changes made, exiting...'
            exit
        }     
        if (('Y','yes') -contains $UserInput) {
            compare-object $DestMember.memberof $SourceMember.memberof | where-object {$_.sideindicator -eq '=>'} | 
            Select-Object -expand inputobject | foreach {add-adgroupmember "$_" $DestAcc}
        }
    }
    until ($UserInput -ne $null)
}