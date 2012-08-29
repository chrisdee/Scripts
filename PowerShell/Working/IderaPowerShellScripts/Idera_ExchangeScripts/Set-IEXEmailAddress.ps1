## =====================================================================
## Title       : Set-IEXEmailAddress
## Description : Add/remove email address. Set it as primary optionally.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Set-IEXEmailAddress [[-EmailAddress] <String>] [[-DisableEmailAddressPolicy] <Object>] [-Add] [-Remove] [-SetAsPrimary] [-PassThru]
##   
## Output      : Microsoft.Exchange.Data.Directory.Management.Mailbox
## Usage       : 
##               1. Add email address.
##               Get-Mailbox shaytest | Set-IEXEmailAddress -Add -EmailAddress foo@company.com -PassThru | Select-Object -Expand EmailAddresses
##
##               2. Add email address and set it as primary.
##               Get-Mailbox shaytest | Set-IEXEmailAddress -Add -EmailAddress foo@company.com -SetAsPrimary -PassThru -DisableEmailAddressPolicy $true | Select-object -Expand EmailAddresses
##
##               3. Remove email address.
##               Get-Mailbox shaytest | Set-IEXEmailAddress -Remove -EmailAddress  foo@company.com  -PassThru | Select-Object -Expand EmailAddresses
##               (Get-Mailbox shaytest).EmailAddresses
##                                        
## Notes       :
## Tag         : Exchange 2007, email address, set
## Change log  :
## ===================================================================== 

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

filter Set-IEXEmailAddress
{
    param(
    [string]$EmailAddress = $(Throw "EmailAddress cannot be empty"),
    [switch]$Add,
    [switch]$Remove,
    [switch]$SetAsPrimary,
    $DisableEmailAddressPolicy,
    [switch]$PassThru
    ) 

  

    if([Microsoft.Exchange.Data.SmtpProxyAddress]::Parse($EmailAddress).ParseException)
    {
        Throw "Invalid email address: '$EmailAddress'"
    } 

  

    if($DisableEmailAddressPolicy -and $DisableEmailAddressPolicy -isnot [bool])
    {
        Throw "DisableEmailAddressPolicy accept booleans or numbers, use $true, $false, 1 or 0 instead."
    } 

  

    if($Add -and $Remove)
    {
        Throw "Add and Remove cannot be specified together, please choose just one"
    } 

  

    if(!$Add -and ! $Remove)
    {
        Throw "Add or Remove wasn't specified, please choose one"
    } 

  

    if($Remove -and $SetAsPrimary)
    {
        Throw "SetAsPrimary cannot be specified with Remove."
    } 

  

    trap{ Throw $_ } 

  

    if($Add)
    {
        $_.EmailAddresses = $_.EmailAddresses += $EmailAddress
    } 

  

    if($Remove)
    {
        $_.EmailAddresses= $_.EmailAddresses -= $EmailAddress
    } 

  

    if($SetAsPrimary)
    {
        if($DisableEmailAddressPolicy -eq $true)
        {
            $_ | Set-Mailbox -PrimarySmtpAddress $EmailAddress -EmailAddressPolicyEnabled:$false
        } 

        if($DisableEmailAddressPolicy -eq $false)
        {
            $_ | Set-Mailbox -PrimarySmtpAddress $EmailAddress -EmailAddressPolicyEnabled:$true
        }
    }
    else
    {
        $_ | Set-Mailbox
    } 

  

    if($PassThru) { $_ }
} 
