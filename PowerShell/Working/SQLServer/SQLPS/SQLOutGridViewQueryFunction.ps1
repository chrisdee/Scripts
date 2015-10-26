## PowerShell: Script that uses SQL Server PowerShell Module (SQLPS) Function to Query a SQL Instance with Grid View Output (Out-GridView) ##

## Overview: Function that uses SQL Server PowerShell Module (SQLPS) Query (Invoke-Sqlcmd) to query a SQL Instance and provides the results in Out-GridView format

## Requires: SQL Server PowerShell Module (SQLPS) on remote clients

## Usage: Edit the parameters in the 'Out-SqlGrid' function to match your requirements and run the script

#Import SQL Server module
Import-Module SQLPS -DisableNameChecking

function Out-SqlGrid(
    [string]$query="EXEC sp_databases", #Copy your SQL query here, and ensure it remains between the double qoutations ""
    [string]$title=$query,
    [string]$ServerInstance="SQLINSTANCENAME", #Provide your SQL Instance here
    [string]$Database="master" #Provide your Database name here
    )
{
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query | Out-GridView -Title $title
}

#Call the function
Out-SqlGrid