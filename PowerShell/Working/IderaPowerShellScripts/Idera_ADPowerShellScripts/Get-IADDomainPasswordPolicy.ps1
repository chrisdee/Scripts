## =====================================================================
## Title       : Get-IADDomainPasswordPolicy
## Description : Retrieve the domain password policy.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input                 
##                     
## Output      : System.Management.Automation.PSCustomObject 
## Usage       : Get-IADDomainPasswordPolicy
##            
## Notes       :
## Tag         : password, policy, domain, security, activedirectory
## Change log  :
## =====================================================================

  
function Get-IADDomainPasswordPolicy 

{  
 
 $domain = [ADSI]"WinNT://$env:userdomain"
 
 $Name = @{Name="DomainName";Expression={$_.Name}}
 $MinPassLen = @{Name="Minimum Password Length (Chars)";Expression={$_.MinPasswordLength}}
 $MinPassAge = @{Name="Minimum Password Age (Days)";Expression={$_.MinPasswordAge.value/86400}}
 $MaxPassAge = @{Name="Maximum Password Age (Days)";Expression={$_.MaxPasswordAge.value/86400}}
 $PassHistory = @{Name="Enforce Password History (Passwords remembered)";Expression={$_.PasswordHistoryLength}}
 $AcctLockoutThreshold = @{Name="Account Lockout Threshold (Invalid logon attempts)";Expression={$_.MaxBadPasswordsAllowed}}
 $AcctLockoutDuration =  @{Name="Account Lockout Duration (Minutes)";Expression={if ($_.AutoUnlockInterval.value -eq -1) {'Account is locked out until administrator unlocks it.'} else {$_.AutoUnlockInterval.value/60}}}
 $ResetAcctLockoutCounter = @{Name="Reset Account Lockout Counter After (Minutes)";Expression={$_.LockoutObservationInterval.value/60}}
 
 $domain | Select-Object $Name,$MinPassLen,$MinPassAge,$MaxPassAge,$PassHistory,$AcctLockoutThreshold,$AcctLockoutDuration,$ResetAcctLockoutCounter
} 