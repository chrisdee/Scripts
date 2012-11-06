## PowerShell: Script to Query Active Directory to Get Password Last Set and Password Expiration Details ##

## Usage Example: Get-UserDetails 'cdee'

Import-Module ActiveDirectory

function Get-UserDetails([string]$user) {
Get-ADUser $user -Properties PasswordLastSet, PasswordNeverExpires #Tip: Use a '*' after properties to get all available attributes related to a user
}
