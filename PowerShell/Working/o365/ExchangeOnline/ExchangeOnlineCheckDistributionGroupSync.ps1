## MSOnline: PowerShell Script to Check and Report on Distribution Group Objects that are not correctly Synced between Exchange Online and MSOnline (o365) ##

## Overview: Script that compares Distribution Group Objects and reports on ones that are not Synced. Results are exported to a Text and CSV file for analysis

## Requires: MSOnline and Exchange Online PowerShell Modules / Connections

## Usage: Edit the following variables to match your environment and run the script: '$path'; '$OutputPath'

#===================
# Disclaimer
#===================
#Please note that this code is made available as is, without warranty of any kind. 
#The entire risk of the use or the results from the use of this code remains with the user. 
#Please test it beforehand and consider this script only as an example
#===================

#===================
# Scope
#===================
# purpose of this script is to test if the MSODS and EXODS Group Objects are correctly synced. We are testing ONLY Distribution Groups
#===================

## Connect to MSOnline (O365)
Function Connect-O365 {
 
Param (
  [Parameter(Mandatory=$true)]
  $User
  )
 
  $Cred = Get-Credential -Credential $User
 
  $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic -AllowRedirection
 
  Import-Module (Import-PSSession $Session -AllowClobber) -Global
 
  Connect-MSOLService -Credential $Cred
 
}

## Call the function
Connect-O365

# Created a simple txt file - needed to test with TXT - the script will also generate a CSV with all groups and their status so you can ditch the txt. 

#clearing the TXT File
$path = "C:\ztemp\Scripts\DG_Script\DG_Script\Groups_new.txt";
if(!(Test-Path -Path $path)){New-Item $path -type file}
else {Clear-Content -Path $path;}

#path to CSV File
$OutputPath = "C:\ztemp\Scripts\DG_Script\DG_Script\"
$fileName = $OutputPath + "Group_Status_" + (Get-Date).Ticks + ".csv"

# initializing the data to be exported to CSV
$data = @()


# discovering all Distribution Groups in the tenant
$exo_groups = Get-DistributionGroup -ResultSize unlimited;

# I am doing the validation for each group. At the end of each loop the variable $Wrong_Group_Count and $Wrong_Group_Membership will either have the value FALSE or TRUE. 
# If it is TRUE it means that Group Membership does not match for that criteria, therefore the Status in CSV will be NotSynced due to Count or due to Membership.

$exo_groups | % {

#saving variable for the current iteration
$email = $_.PrimarySmtpAddress;
$alias = $_.Alias;
$exo_objectID = $_.GUID.tostring();
$msol_objectID = $_.externaldirectoryobjectid.tostring(); # externaldirectoryobjectid identifies both group and members across MSODS and EXODS
$Wrong_Group_Count = $False;
$Wrong_Group_Membership = $False;

# Getting the membership about the MSOLGroup Object for each DL in EXO. Search Key is the "externaldirectoryobjectid" which matches the MSOL "GroupObjectID"
# Please note that there is a limitation of how many members the command will return - might have changed since writing this script. Now limit is 500 members
# members are sorted based on the ObjectID of each individual Member. This ID is equal to the Externaldirectoryobjectid of the DL Group Member and should in theory be the same after sorting
$msol_group_member = Get-MsolGroupMember -GroupObjectId $_.externaldirectoryobjectid.tostring() -All | Sort-Object -Property ObjectId;

# Discovering also the EXO DL Members to compare them with the MSOL Group Members
# Please note that I am sorting both objects to be sure the comparison is ok - they should match if groups are correctly synced
$exo_group_member = Get-DistributionGroupMember -Identity $exo_objectID -ResultSize unlimited| Sort-Object -Property ExternalDirectoryObjectId;

# if the number of members does not match, we can safely assume the current group has a problem - not going further with validation
# if the count is the same, I am also validating that the members are indeed the same by comparing the objectID and externaldirectoryobjectid
# As soon as the script finds one that does not match, we break the loop and report it back as faulty. 

$exocount = ($exo_group_member | measure).count;
$msolcount = ($msol_group_member | measure).count;

if ( $exocount -ne $msolcount) {$Wrong_Group_Count = $True;}
else    {
         $counter = $exocount;
         for ( $i=0;$i -lt $counter; $i++ )         { 

            if ($exo_group_member[$i].ExternalDirectoryObjectId.ToString() -ne $msol_group_member[$i].ObjectId.ToString()) {

                   $Wrong_Group_Membership = $True;
                   Break;
            }
        }
    }


# checking to see what is the status of the current group. We export info in TXT file and to CSV

if ($Wrong_Group_Count -eq $True ) {

        Write-host "Group `"$alias`" is not synced correctly due to count mismatch"; 
        "Group with Alias `"$alias`" and E-Mail `"$email`" is not synced correctly due to count mismatch"| Add-Content -Path $path; 
        $data +=New-Object PSObject -Property @{"Alias" = $alias;"Email Address" = $email;"EXO Group ID" = $exo_objectID;"MSOL Group ID" = $msol_objectID; "Status" = "NotSynced due to count mistmatch"};
     }

     elseif ($Wrong_Group_Membership -eq $True ) {

            Write-host "Group `"$alias`" is not synced correctly due to missing members"; 
            "Group with Alias `"$alias`" and E-Mail `"$email`" is not synced correctly due to missing members"| Add-Content -Path $path; 
            $data +=New-Object PSObject -Property @{"Alias" = $alias;"Email Address" = $email; "EXO Group ID" = $exo_objectID; "MSOL Group ID" = $msol_objectID; "Status" = "NotSynced due to missing members"};
     
     
        }

        else {
                "Group with Alias `"$alias`" and E-Mail `"$email`" is OK"| Add-Content -Path $path;
                $data +=New-Object PSObject -Property @{"Alias" = $alias;"Email Address" = $email;"EXO Group ID" = $exo_objectID; "MSOL Group ID" = $msol_objectID; "Status" = "OK"};
    
            }

} 
 # writing the final result to CSV. The Text file is updated along the way. 
 $data | export-csv $fileName -NoTypeInformation;
 
