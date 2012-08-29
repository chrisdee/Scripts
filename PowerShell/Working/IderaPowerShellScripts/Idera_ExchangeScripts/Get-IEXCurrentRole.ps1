## =====================================================================
## Title       : Get-IEXCurrentRole 
## Description : Retrieve the role of the currently logged on user.
## Author      : Idera
## Date        : 09/15/2009
## Input       : No input
##   
## Output      : Microsoft.Exchange.Management.RecipientTasks.DelegateUser
## Usage       : Get-IEXCurrentRole 
##                        
## Notes       :
## Tag         : Exchange 2007, role, user, get
## Change log  :
## ===================================================================== 
  
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
 
function Get-IEXCurrentRole  
{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    Get-ExchangeAdministrator -Identity $user
} 
  
