## Active Directory: PowerShell Script to check the Status of AD Replication across a Forest. Includes CSV and HTML Status Output Functionality ##

## Overview: PowerShell Script that checks the status of AD Replication across a Forest and outputs the detailed results to a CSV file, along with a HTML status summary

## Resource: https://balladelli.com/replication-status

# save the location of the current script
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$outfile = $dir + "\" + "replication.csv"

repadmin /showrepl * /csv >$outfile | Out-Null

$replStatus = Import-Csv $outfile #-Header $headers

# change each error code into its corresponding string message
$errCount = 0
Foreach ($status in $replStatus)
{
	if ($status.("Number of Failures") -gt 0)
	{
		$status.("Last Failure Status") = ([ComponentModel.Win32Exception][Int32]$status.("Last Failure Status")).Message
		$errCount++
	}
}

$html = "<style>"
$html += "BODY{background-color:white;}"
$html += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$html += "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:LightBlue}"
$html += "TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:AliceBlue}"
$html += "</style>"

if ($errCount -ne 0)
{
	$title = "<H2>Replication errors as of "+[datetime]::Now+"</H2>"
}
else
{
	$title = "<H2>Replication OK as of "+[datetime]::Now+"</H2>"
}

$replStatus | Where-Object {$_.("Number of Failures") -gt 0} |
Select-Object "Source DC","Source DC Site","Destination DC", "Destination DC Site","Number of Failures", "Last Failure Time","Last Failure Status","Last Success Time","Naming Context"| 
ConvertTo-HTML -head $html -body $title | 
Out-File ($dir + "\Repl.htm")