#Gets the general config settings for SQL
param
(		
	[String]$OutputFile
)

Add-PSSnapin SqlServerCmdletSnapin100 -EA 0

#Get the setting and output to a file
Invoke-sqlcmd -Query 'exec sp_configure' | Format-List | Out-File -filePath $OutputFile