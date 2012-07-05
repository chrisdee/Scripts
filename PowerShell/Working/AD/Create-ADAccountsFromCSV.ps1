    ## PowerShell Script to create Functions using the ActiveDirectory module to create AD accounts and Groups imported from a CSV file ##
	## Resource: http://get-spscripts.com/2011/08/creating-bulk-active-directory-user-and.html
	
	#Import the PowerShell module containing AD cmdlets
    Import-Module ActiveDirectory
       
    #Read a CSV file with the user or group details and create an account in AD for each entry
    Function Create-ADAccountsFromCSV {
        Param (
            [parameter(Mandatory=$true)][string]$CSVPath,
            [parameter(Mandatory=$true)][string]$Type,
            [parameter(Mandatory=$true)][string]$OrgUnit
            )
     
        if (($Type -ne "Group") -and ($Type -ne "User"))
        {
            Throw New-Object System.ArgumentException("Type parameter must be specified as either 'User' or 'Group'.")
        }
     
        #Read the CSV file
        $csvData = Import-CSV $CSVPath
        foreach ($line in $csvData) {
           
            #Create a hash table of the account details
            $accountTable = @{
                'givenName'=$line.FirstName
                'sn'= $line.LastName
                'displayName'= $line.DisplayName
                'sAMAccountName'= $line.sAMAccountName
                'password' = $line.Password
                'description' = $line.Description
                'ou' = $OrgUnit 
            }
                   
            if ($Type -eq "User")
            {
                #Call the function to create a user account
                CreateUser -AccountInfo $accountTable
            }
     
            if ($Type -eq "Group")
            {
                #Call the function to create a group account
                CreateGroup -AccountInfo $accountTable
               
                #Get new group
                $groupFilterString = "samAccountName -like `"" + $line.sAMAccountName + "`""
                $group = Get-ADGroup -Filter $groupFilterString
               
                #Walk through each member column associated with this group
                $memberColumnNumber = 1
                $memberColumn = "Member" + $memberColumnNumber
               
                #While a member column still exists, add the value to a group
                while ($line.$memberColumn)
                {
                    #Check if user is already a member of the group
                    $member = Get-ADGroupMember $group | where { $_.samAccountName -eq $line.$memberColumn }
                   
                    #If not already a member, add user to the group
                    if ($member -eq $null)
                    {
                        write-host "Adding" $line.$memberColumn "as a member to group" $group.Name
                        try
                        {
                            $userFilterString = "samAccountName -like `"" + $line.$memberColumn + "`""
                            $user = Get-ADUser -Filter $userFilterString
                            Add-ADGroupMember -Identity $group -Members $user
                        }
                        catch
                        {
                            write-host "There was a problem adding" $line.$memberColumn "as a member to group" $group.Name "-" $_ -ForegroundColor red
                        }
                    }
                    else
                    {
                        write-host "User" $line.$memberColumn "not added to group" $group.Name "as it is already a member" -ForegroundColor blue
                    }
                   
                    $memberColumnNumber = $memberColumnNumber + 1
                    $memberColumn = "Member" + $memberColumnNumber
                }
            }
        }
    }        

    #Create an Active Directory user
    Function CreateUser {
      Param($AccountInfo)
     
        try
        {
            #Check to see if the user already exists
            $userFilterString = "samAccountName -like `"" + $AccountInfo['sAMAccountName'] + "`""
            $user = Get-ADUser -Filter $userFilterString
           
            #If user not already created, create them
            if ($user -eq $null)
            {
                write-host "Creating user account:" $AccountInfo['sAMAccountName']
               
                #Create the user account object
                New-ADUser -SamAccountName $AccountInfo['sAMAccountName'] `
                           -Name $AccountInfo['displayName'] `
                           -DisplayName $AccountInfo['displayName'] `
                           -GivenName $AccountInfo['givenName'] `
                           -Surname $AccountInfo['sn'] `
                           -Path $AccountInfo['ou'] `
                           -ChangePasswordAtLogon $true `
                           -AccountPassword (ConvertTo-SecureString $AccountInfo['password'] -AsPlainText -Force) `
                           -Description $AccountInfo['description'] `
                           -Enabled $false
           
                #Set 'User must change password at next logon' to true after user has been created
                #For some reason, the option wasn't set during New-ADUser - could be a bug?
                $user = Get-ADUser -Filter $userFilterString
                Set-ADUser $user -ChangePasswordAtLogon $true          
            }
            else
            {
                write-host "User" $AccountInfo['sAMAccountName'] "not created as it already exists" -ForegroundColor blue
            }
        }
        catch
        {
            write-host "There was a problem creating the user" $AccountInfo['sAMAccountName'] "-" $_ -ForegroundColor red
        }
    }

    #Create an Active Directory group
    Function CreateGroup {
        Param($AccountInfo)
     
        try
        {
            #Check to see if the group already exists
            $groupFilterString = "samAccountName -like `"" + $AccountInfo['sAMAccountName'] + "`""
            $group = Get-ADGroup -Filter $groupFilterString
           
            if ($group -eq $null)
            {  
                write-host "Creating group account:" $AccountInfo['sAMAccountName']
               
                #Create the group account object
                New-ADGroup -SamAccountName $AccountInfo['sAMAccountName'] `
                            -Name $AccountInfo['sAMAccountName'] `
                            -Path $AccountInfo['ou'] `
                            -GroupScope Global `
                            -GroupCategory Security
            }
            else
            {
                write-host "Group" $AccountInfo['sAMAccountName'] "not created as it already exists" -ForegroundColor blue
            }
        }
        catch
        {
            write-host "There was a problem creating the group" $AccountInfo['sAMAccountName'] "-" $_ -ForegroundColor red
        }  
    }
	
	## Usage examples: Edit parameters to suit your environment and 'uncomment' the one you want to use to create your Users or Groups to assign Members to
	
	#Create-ADAccountsFromCSV -CSVPath "C:\Scripts\UserAccounts.csv" -OrgUnit "OU=Staff,DC=acme,DC=local” -Type "User"
	#Create-ADAccountsFromCSV -CSVPath "C:\Scripts\GroupAccounts.csv" -OrgUnit "OU=Groups,DC=acme,DC=local” -Type "Group"