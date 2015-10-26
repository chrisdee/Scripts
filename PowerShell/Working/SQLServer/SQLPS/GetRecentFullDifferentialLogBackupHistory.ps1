## PowerShell: Script that uses SQL Server PowerShell Module (SQLPS) Query to Get Recent Full / Differential / Log Backup History from SQL Instances ##

<#

Overview: Script that uses SQL Server PowerShell Module (SQLPS) Query (Invoke-Sqlcmd) to Get Recent Full / Differential / Log Backup History from SQL Instances provided in a text file

Requires: SQL Server PowerShell Module (SQLPS) on remote clients

Usage: Edit the variables in the variables section and save a text file with the SQL Instances you want to query in the location you set in the '$SQLServers' variable, and run the script

Resources: http://www.sqlevo.com/2015/10/sql-database-backup-reports-with.html; http://guidestomicrosoft.com/2015/01/13/install-sql-server-powershell-module-sqlps


#>

### Start Variables ###

## Global Variables
$SQLServers = "C:\BoxBuild\Scripts\SQLServers.txt"
$HTMLReport = "C:\BoxBuild\Scripts\SQLServersBackupReport.html"
$DaysSinceLastFullThreshold = "1" #Change this value to set a threshhold for an 'alert' on how many days since the last Full backup

## Email Variables
$MailTo = "mailto@yourdomain.com"
$MailFrom = "SQLBackupReports@yourdomain.com"
$MailSubject = "SQL Backup Report"
$MailServer = "smtpmail.yourdomain.com"

### End Variables #### 

#Setup HTML
$Header = @"
		<style>
		TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
		TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: green;}
		TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		</style>
		
<title>
SQL Server Backup Report
</title>
"@
$Pre = "<h2>SQL Server Backup Report</h2>"


#Alternate Row Color
Function Set-AlternatingRows {
	<#
	.SYNOPSIS
		Simple function to alternate the row colors in an HTML table
	.DESCRIPTION
		This function accepts pipeline input from ConvertTo-HTML or any
		string with HTML in it.  It will then search for <tr> and replace 
		it with <tr class=(something)>.  With the combination of CSS it
		can set alternating colors on table rows.
		
		CSS requirements:
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		
		Classnames can be anything and are configurable when executing the
		function.  Colors can, of course, be set to your preference.
		
		This function does not add CSS to your report, so you must provide
		the style sheet, typically part of the ConvertTo-HTML cmdlet using
		the -Head parameter.
	.PARAMETER Line
		String containing the HTML line, typically piped in through the
		pipeline.
	.PARAMETER CSSEvenClass
		Define which CSS class is your "even" row and color.
	.PARAMETER CSSOddClass
		Define which CSS class is your "odd" row and color.
	.EXAMPLE $Report | ConvertTo-HTML -Head $Header | Set-AlternateRows -CSSEvenClass even -CSSOddClass odd | Out-File HTMLReport.html
	
		$Header can be defined with a here-string as:
		$Header = @"
		<style>
		TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
		TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
		TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		</style>
		"@
		
		This will produce a table with alternating white and grey rows.  Custom CSS
		is defined in the $Header string and included with the table thanks to the -Head
		parameter in ConvertTo-HTML.
	.NOTES
		Author:         Martin Pugh
		Twitter:        @thesurlyadm1n
		Spiceworks:     Martin9700
		Blog:           www.thesurlyadmin.com
		
		Changelog:
			1.1         Modified replace to include the <td> tag, as it was changing the class
                        for the TH row as well.
            1.0         Initial function release
	.LINK
		http://community.spiceworks.com/scripts/show/1745-set-alternatingrows-function-modify-your-html-table-to-have-alternating-row-colors
    .LINK
        http://thesurlyadmin.com/2013/01/21/how-to-create-html-reports/
	#>
    [CmdletBinding()]
   	Param(
       	[Parameter(Mandatory,ValueFromPipeline)]
        [string]$Line,
       
   	    [Parameter(Mandatory)]
       	[string]$CSSEvenClass,
       
        [Parameter(Mandatory)]
   	    [string]$CSSOddClass
   	)
	Begin {
		$ClassName = $CSSEvenClass
	}
	Process {
		If ($Line.Contains("<tr><td>"))
		{	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
			If ($ClassName -eq $CSSEvenClass)
			{	$ClassName = $CSSOddClass
			}
			Else
			{	$ClassName = $CSSEvenClass
			}
		}
		Return $Line
	}
}

#Set Cell color
Function Set-CellColor
{   <#
    .SYNOPSIS
        Function that allows you to set individual cell colors in an HTML table
    .DESCRIPTION
        To be used inconjunction with ConvertTo-HTML this simple function allows you
        to set particular colors for cells in an HTML table.  You provide the criteria
        the script uses to make the determination if a cell should be a particular 
        color (property -gt 5, property -like "*Apple*", etc).
        
        You can add the function to your scripts, dot source it to load into your current
        PowerShell session or add it to your $Profile so it is always available.
        
        To dot source:
            .".\Set-CellColor.ps1"
            
    .PARAMETER Property
        Property, or column that you will be keying on.  
    .PARAMETER Color
        Name or 6-digit hex value of the color you want the cell to be
    .PARAMETER InputObject
        HTML you want the script to process.  This can be entered directly into the
        parameter or piped to the function.
    .PARAMETER Filter
        Specifies a query to determine if a cell should have its color changed.  $true
        results will make the color change while $false result will return nothing.
        
        Syntax
        <Property Name> <Operator> <Value>
        
        <Property Name>::= the same as $Property.  This must match exactly
        <Operator>::= "-eq" | "-le" | "-ge" | "-ne" | "-lt" | "-gt"| "-approx" | "-like" | "-notlike" 
            <JoinOperator> ::= "-and" | "-or"
            <NotOperator> ::= "-not"
        
        The script first attempts to convert the cell to a number, and if it fails it will
        cast it as a string.  So 40 will be a number and you can use -lt, -gt, etc.  But 40%
        would be cast as a string so you could only use -eq, -ne, -like, etc.  
    .PARAMETER Row
        Instructs the script to change the entire row to the specified color instead of the individual cell.
    .INPUTS
        HTML with table
    .OUTPUTS
        HTML
    .EXAMPLE
        get-process | convertto-html | set-cellcolor -Propety cpu -Color red -Filter "cpu -gt 1000" | out-file c:\test\get-process.html

        Assuming Set-CellColor has been dot sourced, run Get-Process and convert to HTML.  
        Then change the CPU cell to red only if the CPU field is greater than 1000.
        
    .EXAMPLE
        get-process | convertto-html | set-cellcolor cpu red -filter "cpu -gt 1000 -and cpu -lt 2000" | out-file c:\test\get-process.html
        
        Same as Example 1, but now we will only turn a cell red if CPU is greater than 100 
        but less than 2000.
        
    .EXAMPLE
        $HTML = $Data | sort server | ConvertTo-html -head $header | Set-CellColor cookedvalue red -Filter "cookedvalue -gt 1"
        PS C:\> $HTML = $HTML | Set-CellColor Server green -Filter "server -eq 'dc2'"
        PS C:\> $HTML | Set-CellColor Path Yellow -Filter "Path -like ""*memory*""" | Out-File c:\Test\colortest.html
        
        Takes a collection of objects in $Data, sorts on the property Server and converts to HTML.  From there 
        we set the "CookedValue" property to red if it's greater then 1.  We then send the HTML through Set-CellColor
        again, this time setting the Server cell to green if it's "dc2".  One more time through Set-CellColor
        turns the Path cell to Yellow if it contains the word "memory" in it.
        
    .EXAMPLE
        $HTML = $Data | sort server | ConvertTo-html -head $header | Set-CellColor cookedvalue red -Filter "cookedvalue -gt 1" -Row
        
        Now, if the cookedvalue property is greater than 1 the function will highlight the entire row red.
        
    .NOTES
        Author:             Martin Pugh
        Twitter:            @thesurlyadm1n
        Spiceworks:         Martin9700
        Blog:               www.thesurlyadmin.com
          
        Changelog:
            1.5             Added ability to set row color with -Row switch instead of the individual cell
            1.03            Added error message in case the $Property field cannot be found in the table header
            1.02            Added some additional text to help.  Added some error trapping around $Filter
                            creation.
            1.01            Added verbose output
            1.0             Initial Release
    .LINK
        http://community.spiceworks.com/scripts/show/2450-change-cell-color-in-html-table-with-powershell-set-cellcolor
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,Position=0)]
        [string]$Property,
        [Parameter(Mandatory,Position=1)]
        [string]$Color,
        [Parameter(Mandatory,ValueFromPipeline)]
        [Object[]]$InputObject,
        [Parameter(Mandatory)]
        [string]$Filter,
        [switch]$Row
    )
    
    Begin {
        Write-Verbose "$(Get-Date): Function Set-CellColor begins"
        If ($Filter)
        {   If ($Filter.ToUpper().IndexOf($Property.ToUpper()) -ge 0)
            {   $Filter = $Filter.ToUpper().Replace($Property.ToUpper(),"`$Value")
                Try {
                    [scriptblock]$Filter = [scriptblock]::Create($Filter)
                }
                Catch {
                    Write-Warning "$(Get-Date): ""$Filter"" caused an error, stopping script!"
                    Write-Warning $Error[0]
                    Exit
                }
            }
            Else
            {   Write-Warning "Could not locate $Property in the Filter, which is required.  Filter: $Filter"
                Exit
            }
        }
    }
    
    Process {
        ForEach ($Line in $InputObject)
        {   If ($Line.IndexOf("<tr><th") -ge 0)
            {   Write-Verbose "$(Get-Date): Processing headers..."
                $Search = $Line | Select-String -Pattern '<th ?[a-z\-:;"=]*>(.*?)<\/th>' -AllMatches
                $Index = 0
                ForEach ($Match in $Search.Matches)
                {   If ($Match.Groups[1].Value -eq $Property)
                    {   Break
                    }
                    $Index ++
                }
                If ($Index -eq $Search.Matches.Count)
                {   Write-Warning "$(Get-Date): Unable to locate property: $Property in table header"
                    Exit
                }
                Write-Verbose "$(Get-Date): $Property column found at index: $Index"
            }
            If ($Line -match "<tr( style=""background-color:.+?"")?><td")
            {   $Search = $Line | Select-String -Pattern '<td ?[a-z\-:;"=]*>(.*?)<\/td>' -AllMatches
                $Value = $Search.Matches[$Index].Groups[1].Value -as [double]
                If (-not $Value)
                {   $Value = $Search.Matches[$Index].Groups[1].Value
                }
                If (Invoke-Command $Filter)
                {   If ($Row)
                    {   Write-Verbose "$(Get-Date): Criteria met!  Changing row to $Color..."
                        If ($Line -match "<tr style=""background-color:(.+?)"">")
                        {   $Line = $Line -replace "<tr style=""background-color:$($Matches[1])","<tr style=""background-color:$Color"
                        }
                        Else
                        {   $Line = $Line.Replace("<tr>","<tr style=""background-color:$Color"">")
                        }
                    }
                    Else
                    {   Write-Verbose "$(Get-Date): Criteria met!  Changing cell to $Color..."
                        $Line = $Line.Replace($Search.Matches[$Index].Value,"<td style=""background-color:$Color"">$Value</td>")
                    }
                }
            }
            Write-Output $Line
        }
    }
    
    End {
        Write-Verbose "$(Get-Date): Function Set-CellColor completed"
    }
}

#import SQL Server module
Import-Module SQLPS -DisableNameChecking

function Get-DBBackup-Type{

    #List of servers from text file
    $serverlist = Get-Content -Path $SQLServers

    #Loop through each server and create SMO object)
foreach ($serverName in $serverlist){

        #create smo object
        $SQLServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $ServerName

            $Query = "SELECT      [ServerName],
            [DatabaseName],
            [BackupSystem],
            [FullBackup] = MAX([FullBackup]),
            [DifferentialBackup] = MAX([DifferentialBackup]),
            [LogBackup] = MAX([LogBackup]),
            [DaysSinceLastFull] = DATEDIFF(DAY,MAX([FullBackup]),GETDATE())
FROM
(
        SELECT      [ServerName]    = @@SERVERNAME,
                    [DatabaseName]  = [A].[database_name],
                    [BackupSystem]  = [A].[name],
                    [FullBackup]    = MAX([A].[backup_finish_date]),
                    [DifferentialBackup] = NULL,
                    [LogBackup] = NULL
        FROM        [msdb].[dbo].[backupset] A INNER JOIN
                    [master].[dbo].[sysdatabases] B ON [A].[database_name] = [B].[name]
        WHERE       [A].[type] = 'D'
        GROUP BY    [A].[database_name],
                    [A].[name]
        UNION ALL
        SELECT      [ServerName]    = @@SERVERNAME,
                    [DatabaseName]  = [A].[database_name],
                    [BackupSystem]  = [A].[name],
                    [FullBackup]    = NULL,
                    [DifferentialBackup] = MAX([A].[backup_finish_date]),
                    [LogBackup] = NULL
        FROM        [msdb].[dbo].[backupset] A INNER JOIN
                    [master].[dbo].[sysdatabases] B ON [A].[database_name] = [B].[name]
        WHERE       [A].[type] = 'I'
        GROUP BY    [A].[database_name],
                    [A].[name]
        UNION ALL
        SELECT      [ServerName]    = @@SERVERNAME,
                    [DatabaseName]  = [A].[database_name],
                    [BackupSystem]  = [A].[name],
                    [FullBackup]    = NULL,
                    [DifferentialBackup] = NULL,
                    [LogBackup] = MAX([A].[backup_finish_date])
        FROM        [msdb].[dbo].[backupset] A INNER JOIN
                    [master].[dbo].[sysdatabases] B ON [A].[database_name] = [B].[name]
        WHERE       [A].[type] = 'L'
        GROUP BY    [A].[database_name],
                    [A].[name] ) B
--WHERE BackupSystem IN ('NetAppBackup','CommVault Galaxy Backup','SQL Native')
GROUP BY    [ServerName],
            [DatabaseName],
            [BackupSystem]
ORDER BY    [DatabaseName],
            [BackupSystem]
"

Invoke-Sqlcmd -ServerInstance $serverName -Database msdb -Query $Query

    }
}




Get-DBBackup-Type | Select ServerName, DatabaseName, BackupSystem, FullBackup, DifferentialBackup, LogBackup, DaysSinceLastFull | ConvertTo-Html -Head $Header -PreContent $Pre | Set-CellColor -Property DaysSinceLastFull -Color red -Filter "DaysSinceLastFull -ge $DaysSinceLastFullThreshold" | Set-AlternatingRows -CSSEvenClass even -CssOddClass Odd | Out-File $HTMLReport



Send-MailMessage -to $MailTo -from $MailFrom -Subject $MailSubject -SmtpServer $MailServer -Attachments "$HTMLReport" -BodyAsHtml (Get-Content $HTMLReport | Out-String)
          