## =====================================================================
## Title       : New-IEXTestMailbox
## Description : Use the function to create a test user in the Active Directory and mailbox-enable this new user.
## Author      : Idera
## Date        : 09/15/2009
## Input       : New-IEXTestMailbox [[-Name] <String>] [[-Password] <String>] [[-Database] <String>] [[-OrganizationalUnit] <String>] [[-Count] <Int32>] [-WhatIf] [-Confirm]
##   
## Output      : Microsoft.Exchange.Data.Directory.Management.Mailbox
## Usage       : 
##               1. Create 10 test mailboxes (TestUser01,TestUser02...) in the Test OU  
##               New-IEXTestMailbox -Name TestUser -Server ServerName -StorageGroup 'First Storage Group' -Database 'Mailbox Database' -OrganizationalUnit "domain.com/test" -Count 10            
## Notes       :
## Tag         : Exchange 2007, user, mailbox, lab, new
## Change log  :
## ===================================================================== 
  
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

  
function New-IEXTestMailbox
{ 
 param(
  [string]$Name="Test", 
  [string]$Password='P@ssw0rd',
  [string]$Database=$(Throw "Parameter 'Database' cannot be empty"),
  [string]$OrganizationalUnit,
  [int]$Count=1,
  [switch]$WhatIf,
  [switch]$Confirm
 )
 
 trap {
  Write-Error $_
  continue
 }
 
 $DomainFQDN = ([ADSI]"").distinguishedName -replace 'dc=' -replace ',','.'
 
 if(!$OrganizationalUnit)
 {
  $OrganizationalUnit = "$DomainFQDN/Users"
 } 

 $db = Get-MailboxDatabase | Where-Object {$_.Name -eq $Database}
 if(!$db)
 {
  Throw "Database '$Database' could not be found"
 }
 
 $Pwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
 
 1..$Count | ForEach-Object { 
  $UPN = "$Name{0:00}@$DomainFQDN" -f $_
  $NewName = "$Name{0:00}" -f $_
  New-Mailbox -Name $NewName -Password $Pwd -Database $db -UserPrincipalName $UPN -OrganizationalUnit $OrganizationalUnit -WhatIf:$WhatIf -Confirm:$Confirm
}
 
} 