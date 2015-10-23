#Gets the number of CPU Cores and TempDB datafiles outputs to a given file
#Adapted from: http://www.sqlskills.com/BLOGS/PAUL/post/Survey-how-is-your-tempdb-configured.aspx
param
(		
	[String]$OutputFile
)

Add-PSSnapin SqlServerCmdletSnapin100 -EA 0

#SQL query to pass to Invoke-sqlcms
$sqlquery = "SELECT os.Cores, df.Files  FROM (SELECT COUNT(*) AS Cores FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE') AS os, (SELECT COUNT(*) AS Files FROM tempdb.sys.database_files WHERE type_desc = 'ROWS') AS df;"

#Get the values and output to a file
Invoke-sqlcmd -Query $sqlquery | Format-List | Out-File -filePath $OutputFile