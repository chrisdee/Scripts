## =====================================================================
## Title       : Backup-SSAS
## Description : Backup all Analysis Server databases
## Author      : Idera
## Date        : 6/27/2008
## Input       : -serverInstance <server\inst>
##               -backupDestination <drive:\x\y | \\unc\path>
##               -retentionDays <n>
##               -logDir <drive:\x\y | \\unc\path>
##               -verbose 
##               -debug	
## Output      : write backup files (*.abf)
## 				  create log file of activity
## Usage			: PS> .\Backup-SSAS -ServerInstance MyServer -BackupDestination C:\SSASbackup 
##                                 -RetentionDays 2 -LogDir C:\SSASLog -verbose -debug
## Notes			: Original script attributed to Ron Klimaszewski
## Tag			: Microsoft Analysis Server, SSAS, backup
## Change Log  :
## =====================================================================
 
param 
( 
	[string]$ServerInstance = "(local)", 
	[string]$BackupDestination, 
	[int]$RententionDays = 2, 
	[string]$LogDir, 
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Backup-SSAS $serverInstance $backupDestination $retentionDays $logDir
}

function Backup-SSAS($serverInstance, $backupDestination, $retentionDays, $logDir)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}
	
	# Force a minimum of two days of retention 
	# TIP: using PS "less than" operator
	if ($RetentionDays -lt 2 ) 
	{
		$RetentionDays = 2 
	} 
	
	# Load Microsoft Analysis Services assembly, output error messages to null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null
	
	# Declare SSAS objects with strongly typed variables
	[Microsoft.AnalysisServices.Server]$SSASserver = New-Object ([Microsoft.AnalysisServices.Server]) 
	[Microsoft.AnalysisServices.BackupInfo]$serverBackup = New-Object ([Microsoft.AnalysisServices.BackupInfo]) 
	
	# Connect to Analysis Server with specified instance
	$SSASserver.Connect($ServerInstance) 
	
	# Set Backup destination to Analysis Server default if not supplied
	# TIP: using PowerShell "equal" operator
	if ($backupDestination -eq "") 
	{
		Write-Debug "Setting the Destination parameter to the BackupDir parameter" 
		$BackupDestination = $SSASserver.ServerProperties.Item("BackupDir").Value 
	} 
	
	# Test for existence of Backup Destination path
	# TIP: using PowerShell ! operator is equivalent to "-not" operator, see below
	if (!(test-path $backupDestination)) 
	{
		Write-Host Destination path `"$backupDestination`" does not exists.  Exiting script. 
		exit 1 
	} 
	else 
	{
		Write-Host Backup files will be written to `"$backupDestination`" 
	} 
	
	# Set Log directory to Analysis Server default if not applied
	if ($logDir -eq "") 
	{
		Write-Debug "Setting the Log directory parameter to the LogDir parameter" 
		$logDir = $SSASserver.ServerProperties.Item("LogDir").Value 
	} 
	
	# Test for existence of Log directory path
	if (!(test-path $logDir)) 
	{
		Write-Host Log directory `"$logDir`" does not exists.  Exiting script. 
		exit 1 
	} 
	else 
	{
		Write-host Logs will be written to $logDir 
	} 
	
	# Test if Log directory and Backup destination paths end on "\" and add if missing
	# TIP: using PowerShell "+=" operator to do a quick string append operation
	if (-not $logDir.EndsWith("\")) 
	{
		$logDir += "\"
	} 
	
	if (-not $backupDestination.EndsWith("\")) 
	{
		$backupDestination += "\"
	} 
	
	# Create Log file name using Server instance
	[string]$logFile = $logDir + "SSASBackup." + $serverInstance.Replace("\","_") + ".log" 
	Write-Debug "Log file name is $logFile"
	
	Write-Debug "Creating database object and set options..."
	$dbs = $SSASserver.Databases 
	$serverBackup.AllowOverwrite = 1 
	$serverBackup.ApplyCompression = 1 
	$serverBackup.BackupRemotePartitions = 1 
	
	# Create backup timestamp
	# TIP: using PowerShell Get-Date to format a datetime string
	[string]$backupTS = Get-Date -Format "yyyy-MM-ddTHHmm" 
	
	# Add message to backup Log file
	# TIP: using PowerShell to output strings to a file
	Write-Debug "Backing up files on $serverInstance at $backupTS"
	"Backing up files on $ServerInstance at $backupTS" | Out-File -filepath $LogFile -encoding oem -append 
	
	# Back up the SSAS databases
	# TIP: using PowerShell foreach loop to enumerate a parent-child object
	foreach ($db in $dbs) 
	{
		$serverBackup.file = $backupDestination + $db.name + "." + $backupTS + ".abf" 
	
		# TIP: using mixed string literals and variable in a Write-Host command
		Write-Host Backing up $db.Name to $serverBackup.File 
		$db.Backup($serverBackup) 
		
		if ($?) {"Successfully backed up " + $db.Name + " to " + $serverBackup.File | Out-File -filepath $logFile -encoding oem -append} 
		else {"Failed to back up " + $db.Name + " to " + $serverBackup.File | Out-File -filepath $logFile -encoding oem -append} 
	} 
	
	# Disconnect from Analysis Server
	$SSASserver.Disconnect() 
	
	# Clear out the old files and files backed up to the Log file
	Write-Host Clearing out old files from $BackupDestination 
	[int]$retentionHours = $retentionDays * 24 * - 1 
	"Deleting old backup files" | Out-File -filepath $logFile -encoding oem -append 
	
	# TIP: using PowerShell get-childitem (get child items for matching location) and pipe to
	#        where-object (selecting certain ones based on a condition) 
	get-childitem ($backupDestination + "*.abf") | where-object {$_.LastWriteTime -le [System.DateTime]::Now.AddHours($RetentionHours)} | Out-File -filepath $logFile -encoding oem -append 
	get-childitem ($backupDestination + "*.abf") | where-object {$_.LastWriteTime -le [System.DateTime]::Now.AddHours($RetentionHours)} | remove-item 
}

main


