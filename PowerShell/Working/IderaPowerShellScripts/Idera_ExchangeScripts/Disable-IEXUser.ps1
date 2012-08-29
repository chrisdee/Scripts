## =====================================================================
## Title       : Disable-IEXUser
## Description : Disable Active Directory user, move it to specified location and hide it from the address lists
##                   no matter if it's UserMailbox or MailUser
## Author      : Idera
## Date        : 09/15/2009
## Input       : Disable-IEXUser [[-Identity] <String>] [[-NewLocationDN] <String>] [-HideFromAddressLists]
##   
## Output      : None
## Usage       : 
##              1. Disable user TestUser1 and  hide it from the address lists
##              Disable-IEXUser -Identity TestUser1 -HideFromAddressLists
## 
##              2. Disable user TestUser2, hide it from the address lists and move it to DisabledUsers OU 
##              Disable-IEXUser -Identity TestUser2 -NewLocationDN "OU=DisabledUsers,DC=domain,DC=com" -HideFromAddressLists 
##            
## Notes       :
## Tag         : Exchange 2007, user, address list, disable
## Change log  :
## ===================================================================== 

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin


function Disable-IEXUser {
    param (
    [string]$Identity,
    [string]$NewLocationDN,
    [switch]$HideFromAddressLists
    )
    if ($NewLocationDN) {
        if(![ADSI]::Exists("LDAP://$NewLocationDN"))
        {
            Throw "'$NewLocationDN' doesn't exist, please check the value."
        }
        else
        {
            $NewLocation = [ADSI]"LDAP://$NewLocationDN"
        }
    }

    $EXUser = Get-User -Identity $Identity
    $EXUserDN = $EXUser.DistinguishedName
    $ADuser = [adsi]"LDAP://$EXUserDN"

    $ADuser.psbase.invokeSet("AccountDisabled",$true) | Out-Null
    $ADUser.put("info","Disabled on $(Get-Date) by $env:userdomain\$env:username") | Out-Null
    $ADuser.SetInfo() | Out-Null

    if ($NewLocation) {$ADuser.psbase.MoveTo($NewLocation)}

    if ($HideFromAddressLists) {
        switch ($EXUser.RecipientType) {
            'UserMailbox' {Get-Mailbox -Identity $Identity | Set-Mailbox -HiddenFromAddressListsEnabled $true}
            'MailUser' {Get-MailUser -Identity $Identity | Set-MailUser -HiddenFromAddressListsEnabled $true}
        }
    }
} 
