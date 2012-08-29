## =====================================================================
## Title       : Get-IADExchangeAdmin
## Description : Retrieve all Exchange 2003 administrators. 
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input          
##                     
## Output      : System.Management.Automation.PSCustomObject
## Usage       : Get-IADExchangeAdmins
##            
## Notes       : You can read more about Exchange administrative role permissions in Exchange 2003.
##               http://support.microsoft.com/default.aspx/kb/823018
##
## Tag         : administrator, exchange2003, activedirectory
## Change log  :
## =====================================================================

function Get-IADExchangeAdmin 
{


    $dnc = ([ADSI]"").distinguishedName
    $exchange = [ADSI]"LDAP://CN=Microsoft Exchange,CN=Services,CN=Configuration,$dnc"
    $acl = $exchange.psbase.ObjectSecurity
    $rights = $acl.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier])

    $rights | Where-Object {$_.ActiveDirectoryRights.value__ -match '^(983551|131220|197119)$'} | Foreach-Object {

        $obj = $_.IdentityReference.translate([system.security.principal.ntaccount])
        $pso = "" | Select-Object User,Role
        $pso.user = $obj

        switch($_.ActiveDirectoryRights.value__)
        {
            983551 { $pso.role="Exchange Full Administrator" }
            131220 { $pso.role="Exchange View Only Administrator" }
            197119 { $pso.role="Exchange Administrator" }
        }

        $pso
    }
}