## =====================================================================
## Title       : Get-MSSQL-ServerAttrib-Csv
## Description : Connect to SQL Server and output server attributes to CSV
## Author      : Idera
## Date        : 1/28/2009
## Input       : -serverInstance <server\instance>
## 				  -tempDir <output path>
## 				  -verbose 
## 				  -debug	
## Output      : CSV file with server attributes
## Usage			: PS> .\Get-MSSQL-ServerAttrib-Csv -serverInstance MyServer -tempDir C:\TEMP\ -verbose -debug
## Notes			: 
## Tag			: SQL Server, Attributes, CSV
## Change log  : Revised SMO Assemblies
## =====================================================================
 
param
(
	[string]$serverInstance = "(local)",
  	[string]$tempDir = "C:\TEMP\",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-ServerAttrib-Csv $serverInstance $tempDir
}

function Get-MSSQL-ServerAttrib-Csv($serverInstance, $tempDir)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}

	# Create fully qualified output filename
	$outputFile = $tempDir + "SQLServerAttributes.csv"
	Write-Debug "Output directory: $outputFile"
	
	# Validate path to temp directory
	if (-not (Test-Path -path $tempDir)) 
	{
		Write-Host Unable to validate path to temp directory: $tempDir
		break
	}
	
	# Load SMO assemblies
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
	
	# Create a Server object for default instance
	Write-Debug "Connecting to server: $ServerInstance" 
	$NamedInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') ($serverInstance)

	# Get server attributes with EnumServerAttributes() method and output to CSV
	#   and overwrite existing file
	Write-Debug "Outputing $outputFile..."
	$NamedInstance.EnumServerAttributes() | Export-Csv -path $outputFile
	
	# Cleanup
	# TIP: variables will go out of scope when the function ends
	#      this is a why to specifically dispose them
	remove-variable NamedInstance 
	remove-variable TempDir
	remove-variable OutputFile
}

main

