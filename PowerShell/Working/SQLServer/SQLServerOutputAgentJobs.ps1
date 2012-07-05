## SQL Server: PowerShell Script To Output SQL Server Agent Jobs From SQL Servers Defined In A Text File ##
# Author:   John Sansom
# Resource: http://www.johnsansom.com/script-sql-server-agent-jobs-using-powershell
# Description:  PS script to generate all SQL Server Agent jobs on the given instance.
#       		The script accepts an input file of server names.
#				The $OutputFolder where the SQL output goes is currently set to the script location.
# Version:  1.0
#
# Example Execution: .\Create_SQLAentJobSripts.ps1 ServerNameList.txt
 
param([String]$ServerListPath)
 
#Load the input file into an Object array
$ServerNameList = get-content -path $ServerListPath
 
#Load the SQL Server SMO Assemly
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
 
#Create a new SqlConnection object
$objSQLConnection = New-Object System.Data.SqlClient.SqlConnection
 
#For each server in the array do the following..
foreach($ServerName in $ServerNameList)
{
    Try
    {
        $objSQLConnection.ConnectionString = "Server=$ServerName;Integrated Security=SSPI;"
            Write-Host "Trying to connect to SQL Server instance on $ServerName..." -NoNewline
            $objSQLConnection.Open() | Out-Null
            Write-Host "Success."
        $objSQLConnection.Close()
    }
    Catch
    {
        Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
        $errText =  $Error[0].ToString()
            if ($errText.Contains("network-related"))
        {Write-Host "Connection Error. Check server name, port, firewall."}
 
        Write-Host $errText
        continue
    }
 
    #IF the output folder does not exist then create it
    $OutputFolder = ".\$ServerName"
    $DoesFolderExist = Test-Path $OutputFolder
    $null = if (!$DoesFolderExist){MKDIR "$OutputFolder"}
 
    #Create a new SMO instance for this $ServerName
    $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $ServerName
 
    #Script out each SQL Server Agent Job for the server
    $srv.JobServer.Jobs | foreach {$_.Script()} | out-file ".\$OutputFolder\jobs.sql"
}