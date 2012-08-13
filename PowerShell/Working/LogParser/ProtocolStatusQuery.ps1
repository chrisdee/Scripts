## PowerShell: Using PowerShell To Run Log Parser Queries ## 
## Overview: The Script below is an example of how you can use Log Parser with PowerShell to query IIS logs for Protocol Status messages
## Requirements: Needs Log Parser 2.2 installed on the machine you run the script from
## Usage Example: ./ProtocolStatusQuery.ps1 "\\ServerName\d$\Logs\IIS\*.log"

$iisfiles = dir $args[0] #Variable for the IIS log files
#The 2 variables below make use of the LogParser COM Object
$m = New-Object -comobject MSUtil.LogQuery
$pif = New-Object -comobject MSUtil.LogQuery.IISW3CInputFormat

foreach ($iisfile in $iisfiles) 
{

$SQL = "select DISTINCT cs-username, date, cs-uri-stem, sc-status from $iisfile where (sc-status >= 500 AND sc-status < 600) AND (cs-uri-stem LIKE '%.ASPX') "
$recordSet = $m.Execute($SQL, $pif)

"DATE        USER	   URL      				STATUS"
"====================================================================="
for(; !$recordSet.atEnd(); $recordSet.moveNext())
{
  $record=$recordSet.getRecord(); 
  write-host ($record.GetValue(“date”).toshortdatestring() + “--” + $record.GetValue(“cs-username”) + “--” + $record.GetValue(“cs-uri-stem”) + “--”+ $record.GetValue(“sc-status”));
}

$recordSet.Close(); 

}