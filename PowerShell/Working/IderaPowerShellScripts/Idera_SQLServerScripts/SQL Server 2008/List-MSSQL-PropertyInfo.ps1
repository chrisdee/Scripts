## =====================================================================
## Title       : List-MSSQL-PropertyInfo
## Description : List Properties of a SQL Server instance using WMI
## Author      : Idera
## Date        : 1/28/2009
## Input       : -serverInstance <server\instance>
## 				  -verbose 
## 				  -debug	
## Output      : List of SQL Server instance advanced properties and settings
## Usage			: PS> .\List-MSSQL-PropertyInfo -serverInstance MyServer -verbose -debug
## Notes			:
## Tag			: SQL Server, Advanced Properties, WMI
## Change log  : WMI Namespace for SQL Server 2008 has changed to 
##               root\Microsoft\SqlServer\ComputerManagement10
## =====================================================================
 
param
(
  	[string]$serverInstance = ".",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	List-MSSQL-PropertyInfo $serverInstance
}

function List-MSSQL-PropertyInfo($serverInstance)
{
	# Retrieve SQL Server advanced properties and settings using WMI
	Get-WmiObject sqlserviceadvancedproperty `
		-namespace "root\Microsoft\SqlServer\ComputerManagement10" -computername $serverInstance | 
		Select-Object -Property PropertyName, PropertyNumValue, PropertyStrValue
}

main