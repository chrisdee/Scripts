## =====================================================================
## Title       : Get-MSSQL-Port-UsingWMI
## Description : Retrieve SQL Server port configured for use using WMI
## Author      : Idera
## Date        : 1/28/2009
## Input       : -computer <computer name>
## 				  -instance <instance name | default=MSSQLSERVER>
## 				  -verbose 
## 				  -debug	
## Output      : SQL Server Port #
## Usage			: PS> .\Get-MSSQL-Port-UsingWMI -Computer "." -Instance "MSSQLSERVER" -verbose -debug
## Notes			: Adapted from Jakob Bindslet script
## Tag			: SQL Server, WMI, Port, Configuration
## Change log  : WMI Namespace for SQL Server 2008 has changed to 
##               root\Microsoft\SqlServer\ComputerManagement10
## =====================================================================
 
param
(
  	[string]$Computer = ".",
	[string]$Instance = "MSSQLSERVER",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-Port-UsingWMI $computer $instance
}

function Get-MSSQL-Port-UsingWMI($computer, $instance)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}

	# Create a WMI query
	$WQL = "SELECT PropertyStrVal "
	$WQL += "FROM ServerNetworkProtocolProperty "
	$WQL += "WHERE InstanceName = '$instance' AND "
	$WQL += "IPAddressName = 'IPAll' AND "
	$WQL += "PropertyName = 'TcpPort' AND "
	$WQL += "ProtocolName = 'Tcp'"
	Write-Debug $WQL
	
	# Create a WMI namespace for SQL Server
	$WMInamespace = 'root\Microsoft\SqlServer\ComputerManagement10'
	
	# TIP: using PowerShell Get-WmiObject to run a WMI query and
	#      iterate through the the results using ForEach-Object
	Get-WmiObject -query $WQL -computerName $computer -namespace $WMInamespace |
		ForEach-Object { $_.PropertyStrVal }
}

main