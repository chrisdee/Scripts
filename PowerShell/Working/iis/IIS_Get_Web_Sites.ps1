## IIS Server: PowerShell Script to List All Web Sites within IIS, and Exports these to a CSV file ##

## Overview: Uses the 'WebAdministration' PowerShell module to report on IIS web sites within an IIS server

## Usage: Modify the '-Path' variable to suit your environment and run the script

## Resource: http://technet.microsoft.com/en-us/library/ee790599.aspx

Import-Module WebAdministration

get-website | select name,id,state,physicalpath, 
@{n="Bindings"; e= { ($_.bindings | select -expa collection) -join ';' }} ,
@{n="LogFile";e={ $_.logfile | select -expa directory}}, 
@{n="attributes"; e={($_.attributes | % { $_.name + "=" + $_.value }) -join ';' }} |
Export-Csv -NoTypeInformation -Path "C:\IIS_Web_Sites.csv" #Change this path to suit your environment