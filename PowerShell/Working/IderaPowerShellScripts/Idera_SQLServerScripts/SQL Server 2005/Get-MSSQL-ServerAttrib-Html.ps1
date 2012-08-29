## =====================================================================
## Title       : Get-MSSQL-ServerAttrib-Html
## Description : Connect to SQL Server and output server attributes to HTML
## Author      : Idera
## Date        : 9/1/2008
## Input       : -serverInstance <server\instance>
## 				  -tempDir <file path>
## 				  -verbose 
## 				  -debug	
## Output      : 
## Usage			: PS> .\Get-MSSQL-ServerAttrib-Html -serverInstance MyServer -tempDir C:\TEMP\ -verbose -debug
## Notes			:
## Tag			: SQL Server, Attributes, HTML
## Change log  :
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
	Get-MSSQL-ServerAttrib-Html $serverInstance $tempDir
}

function Get-MSSQL-ServerAttrib-Html($serverInstance, $tempDir)
{
	$outputFile = $tempDir + "SQLServerAttributes.html"
	Write-Debug "Output directory: $outputFile"
	
	# Validate path to temp directory
	if (-not (Test-Path -path $tempDir)) 
	{
		Write-Host Unable to validate path to temp directory: $tempDir
		break
	}
	
	# Load-SMO assemblies
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") 
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
	
	# Create a Server object for default instance
	Write-Debug "Connecting to server: $ServerInstance" 
	$namedInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') ($serverInstance)

	# Get server attributes and convert attribute info to HTML
	# Save to file and overwrite the file if it exists
	
	Write-Debug "Saving $outputFile..."
	# TIP: using PowerShell convert an output stream to formatted HTML
	$namedInstance.EnumServerAttributes() | `
		convertto-html -property attribute_name, attribute_value `
		-title "Server Attributes" -body '<font face="Verdana">' `
		| foreach {$_ -replace "<th>", "<th align=left>"} `
		| Out-File $outputFile
	
	# TIP: Open new browser window and display ServerAttributes.html
	#      requires confirmation
	invoke-item $outputFile -confirm

	# Cleanup
	remove-variable namedInstance 
	remove-variable tempDir
	remove-variable outputFile
}

main 