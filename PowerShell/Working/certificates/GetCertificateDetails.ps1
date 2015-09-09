## PowerShell: Script to list Certificate Details stored in a Local Machine / Currecnt User Certificate Store  ##

Set-Location Cert:\LocalMachine\My #Set the path to the 'Local Computer' Personal certificate store
#Set-Location Cert:\CurrentUser\My #Set the path to the 'Current User' Persoanl Certfiicate store

Get-ChildItem | Format-Table Subject, FriendlyName, Thumbprint