## PowerShell: Script to manually start Azure Active Directory Synchronization (Azure AD Connect) with Azure / o365 ##

## Overview: PowerShell script to trigger a full or incremental sync for the Azure AD Connect tool. Also launches the Azure AD Connect Client

## Note: Replaces the 'Start-OnlineCoexistenceSync' command

### Start Variables ###
$ADSyncLocation = "C:\Program Files\Microsoft Azure AD Sync\Bin\"
$ADSyncType = "initial" ## 'initial' for Full Sync or 'delta' for Incremental Sync
$ADSyncClient = "C:\Program Files\Microsoft Azure AD Sync\UIShell\miisclient.exe"
### End Variables ###

## Changes directory path to the AAD Connect application 'Bin'
cd $ADSyncLocation

## Trigegrs the 'initial' or 'delta' Sync process
.\DirectorySyncClientCmd.exe $ADSyncType

## Launches the AAD Connect Client (miisclient.exe)
Invoke-Item $ADSyncClient