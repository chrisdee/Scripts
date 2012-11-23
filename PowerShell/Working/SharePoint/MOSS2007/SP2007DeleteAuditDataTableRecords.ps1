## SharePoint Server: Powershell Script to delete AuditData Table Records ##
# Overview: PowerShell script built on the stsadm -o trimauditlog command
# Environments: MOSS 2007 Farms
# Usage: Edit the following two variable to suit your requirements and run the script: '$constantNumberDays', '$newSTSADM2'
# Resource: http://surfpointtech.com/2012/02/01/sharepoint-auditdata-table-is-too-large-powershell-script-to-schedule-stsadm-o-trimauditlog

$currentDate = Get-Date
#Write-Host $currentDate

#Subtract number of days to sync up to the last day we want to keep in the table
$constantNumberDays = -365 #Change the number of days to suite your requirements

$newDateToDelete = $currentDate.AddDays($constantNumberDays)

$newDateString = '{0:yyyyMMdd}' -f $newDateToDelete
#Write-Host $newDateString

$newSTSADM1 = "stsadm -o trimauditlog -date "
$newSTSADM2 = " -databasename WSS_Content" #Change your content database name here
$newSTSADMFinal = "$newSTSADM1$newDateString$newSTSADM2"

invoke-expression "$newSTSADMFinal"