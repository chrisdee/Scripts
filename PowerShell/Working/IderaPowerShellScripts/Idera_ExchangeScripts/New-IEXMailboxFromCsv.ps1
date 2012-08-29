## =====================================================================
## Title       : New-IEXMailboxFromCsv
## Description : Create mailbox using data from CSV file.
## Author      : Idera
## Date        : 09/15/2009
## Input       :  New-IEXMailboxFromCsv [[-CsvFilePath] <String>] [-ResetPasswordOnNextLogon] [-WhatIf] [-Confirm]
##   
## Output      : Microsoft.Exchange.Data.Directory.Management.Mailbox
## Usage       :
##               1. Check what would happen if you try to create mailboxes using c:\users.csv as input file.
##               New-IEXMailboxFromCsv -CsvFilePath c:\users.csv -WhatIf
##
##               2. Create mailboxes using data from c:\users.csv, set "User must change password at next log on", and ask for confirmation.
##               New-IEXMailboxFromCsv -CsvFilePath c:\users.csv -ResetPasswordOnNextLogon -Confirm            
##                             
## Notes       :
## Tag         : Exchange 2007, mailbox, create
## Change log  :
## =====================================================================

## sample CSV file
# Name,SamAccountName,Password,FirstName,LastName,Database,OrganizationalUnit
# Test1,Test1,P@ssw0rd,Test,User1,Mailbox Database,"domain.com/users"
# Test2,Test2,P@ssw0rd,Test,User2,Mailbox Database,
# Test3,Test3,P@ssw0rd,Test,User3,Mailbox Database,"cn=users,dc=domain,dc=com"


#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function New-IEXMailboxFromCsv
{ 

    param(
    [string]$CsvFilePath = $(Throw "Parameter 'CsvFilePath' cannot be empty"),
    [switch]$ResetPasswordOnNextLogon,
    [switch]$WhatIf,
    [switch]$Confirm
    )

    trap {
        Write-Error $_
        continue
    }

    if(Test-Path -Path $CsvFilePath -PathType Leaf)
    {

        $DomainFQDN = ([ADSI]"").distinguishedName -replace 'dc=' -replace ',','.'

        Import-Csv -Path $CsvFilePath | Foreach-Object {
            $line = $_

            if(!$_.OrganizationalUnit) {  
                Write-Warning "OU name was not specified, '$DomainFQDN/Users'  will be used ins."
                $_.OrganizationalUnit = "$DomainFQDN/Users" 
            }

            $db = Get-MailboxDatabase | Where-Object {$_.Name -eq $line.Database}

            if(!$db)
            {
                Throw "Database '$Database' could not be found"
            }

            $Pwd = ConvertTo-SecureString -String $_.Password -AsPlainText -Force

            $UPN = "{0}@$DomainFQDN" -f $_.name

            New-Mailbox -Name $_.Name -FirstName $_.FirstName -LastName $_.LastName -SamAccountName $_.SamAccountName -Password $Pwd -Database $db -UserPrincipalName $UPN -OrganizationalUnit $_.OrganizationalUnit -ResetPasswordOnNextLogon:([bool]$ResetPasswordOnNextLogon) -WhatIf:$WhatIf -Confirm:$Confirm
        }
    }
    else
    {
        Throw "File: '$CsvFilePath' cannot be found"
    }
}