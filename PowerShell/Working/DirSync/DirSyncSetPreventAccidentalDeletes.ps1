## DirSync: PowerShell Commands to Configure Accidental Deletion Functionality (Prevent Accidental Deletes) ##

#Import the DirSync Module
Import-Module Dirsync

#Disable the Accidental Deletion Functionality
Set-PreventAccidentalDeletes –Disable

#Trigger a Full DirSync
Start-OnlineCoexistenceSync -FullSync

#Enable
Set-PreventAccidentalDeletes -Enable –ObjectDeletionThreshold 500 #Change the threshold value to match your requirements