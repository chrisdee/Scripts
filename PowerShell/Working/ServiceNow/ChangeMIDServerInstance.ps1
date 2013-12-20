## ServiceNow: PowerShell Script To Change The ServiceNow Instance The MID Server Connects To ##

## Overview: Useful script to update the URL of the instance a particular MID Server connects to. The script will also stop and restart the MID Server with the update.
## Important: This script assumes that the same MID server user credentials 'mid.instance.username' exist in each instance you connect to.

##### BEGIN VARIABLES #####
$ServiceNowDirectory = "C:\ServiceNow\MIDServer\agent" #The path to your ServiceNow installation directory
$ConfigXML = "C:\ServiceNow\MIDServer\agent\config.xml" #The path to your config.xml file
$DevInstance = "gfdev" #Dev ServiceNow Instance
$ProdInstance = "theglobalfund" #Prod ServiceNow Instance
##### END VARIABLES #####

Write-Host "Which Instance would you like to connect the MID Server to:" -ForegroundColor Yellow
""
"1. Dev Instance"
"2. Prod Instance"
""

$in = read-host -prompt "Enter Instance Number"

if ($in -like "1") {

cd $ServiceNowDirectory

./stop.bat

(Get-Content $ConfigXML) | 
Foreach-Object {$_ -replace "$ProdInstance", "$DevInstance"} | 
Set-Content $ConfigXML

./start.bat

}

if ($in -like "2") {

cd $ServiceNowDirectory

./stop.bat

(Get-Content $ConfigXML) | 
Foreach-Object {$_ -replace "$DevInstance", "$ProdInstance"} | 
Set-Content $ConfigXML

./start.bat

}

$CurrentInstance = Select-String $ConfigXML -pattern "https://"
Write-Host "Done, the MID server should now be connecting to: $CurrentInstance" -ForegroundColor Gray