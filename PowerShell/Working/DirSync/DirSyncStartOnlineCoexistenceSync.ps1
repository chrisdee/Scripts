## PowerShell: Commandlet to manually start Active Directory Synchronization (Dir Sync) with Office 365 ##

## The 'Add-PSSnapin' method was replaced on later DirSync clients with the 'Import-Module' command below

#Add-PSSnapin "Coexistence-Configuration" -ErrorAction SilentlyContinue

Import-Module Dirsync

Start-OnlineCoexistenceSync

#Start-OnlineCoexistenceSync -FullSync #Use the '-FullSync' parameter to trigger a full sync