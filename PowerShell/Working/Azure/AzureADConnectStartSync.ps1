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

## Triggers the 'initial' or 'delta' Sync process
.\DirectorySyncClientCmd.exe $ADSyncType

## Launches the AAD Connect Client (miisclient.exe)
Invoke-Item $ADSyncClient

## Azure AD Connect sync: Scheduler for builds 1.1.105.0+ (February 2016) ##

## Note: You no longer have to import the Azure AD Sync PowerShell Module

## Resource: https://docs.microsoft.com/en-us/azure/active-directory/connect/active-directory-aadconnectsync-feature-scheduler

## Get the Ad Sync Scheduler Settings
Get-ADSyncScheduler

Start-ADSyncSyncCycle -PolicyType Delta #Triggers the 'delta' Sync process
#Start-ADSyncSyncCycle -PolicyType Initial #Triggers the 'full' Sync process

## Set the AD Sync Scheduler Cycle

Set-ADSyncScheduler -SyncCycleEnabled $True
#Set-ADSyncScheduler -SyncCycleEnabled $False

