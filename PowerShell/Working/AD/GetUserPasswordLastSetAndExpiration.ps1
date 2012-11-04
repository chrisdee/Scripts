## PowerShell: Script to Query Active Directory to Get Password Last Set and Password Expiration Details ##

## Usage Example: get-pwdset DOMAIN\AccountName

Import-Module "activedirectory" -ErrorAction SilentlyContinue

Function get-pwdset{
Param([parameter(Mandatory=$true)][string]$user)
}

$use = get-aduser $user -properties passwordlastset,passwordneverexpires

If($use.passwordneverexpires -eq $true)
{
 write-host $user "last set their password on " $use.passwordlastset  "this account has a non-expiring password" -foregroundcolor yellow
}

Else
{
$til = (([datetime]::FromFileTime((get-aduser $user -properties "msDS-UserPasswordExpiryTimeComputed")."msDS-UserPasswordExpiryTimeComputed"))-(get-date)).days
if($til -lt "5")
{
 write-host $user "last set their password on " $use.passwordlastset "it will expire again in " $til " days" -foregroundcolor red
}
Else
{
 write-host $user "last set their password on " $use.passwordlastset "it will expire again in " $til " days" -foregroundcolor green
}
}