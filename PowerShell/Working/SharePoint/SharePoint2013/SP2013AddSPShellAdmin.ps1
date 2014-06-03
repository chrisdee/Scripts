## SharePoint Server: Powershell Script To Assign An Account Access To The SPShell Access Role 'SharePoint_Shell_Access' For A Specific Database ##

<#

Overview: The PowerShell script below adds a specified user to a specified content database with the SQL Server 'SharePoint_Shell_Access' role. The commandlet also adds the account to the 'WSS_ADMIN_WPG' server role

Environments: SharePoint Server 2013 Farms

Usage: Edit the following variables to match your environment and run the script: '$UserAccount'; '$contentDB'

Resources: http://andersrask.sharepointspace.com/Lists/Posts/Post.aspx?ID=12; http://technet.microsoft.com/en-us/library/ff607596(v=office.15).aspx

Add-SPShellAdmin [-UserName] <String>
[-AssignmentCollection <SPAssignmentCollection>]
[-Confirm [<SwitchParameter>]]
[-database <SPDatabasePipeBind>]
[-WhatIf [<SwitchParameter>]] [<CommonParameters>]

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$UserAccount = "DOMAIN\YourAccount" #Change this to match your user name
$contentDB = Get-SPDatabase | ?{$_.Name -eq "Your_Database_Name"} #Change your database name here

Add-SPShellAdmin -UserName $UserAccount -database $contentDB