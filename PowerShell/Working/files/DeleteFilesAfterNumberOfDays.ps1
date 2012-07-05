## PowerShell: Script To Delete File Types from Folders Older Than a Specified Number of Days ##
## Usage: Goes through specified folders and sub-folders deleting all specified file types older than a specified date 
#--- Start define parameters ---#
#--- get current date ---#
$Now = Get-Date 
#--- define amount of days ---#
$Days = "7"
#--- define folders where the files are located (add additional ones with commas like: ,"C:\ztemp\Logs1" ---#
$TargetFolders = "C:\ztemp\Logs","C:\ztemp\Logs1"
#--- define extensions (add additional ones with commas like: ,"*.csv" ---#
$Extensions = "*.log","*.csv" 
#--- define LastWriteTime parameter based on $Days ---#
$LastWrite = $Now.AddDays(-$Days)
#--- End define parameters ---#

#--- get files based on lastwrite filter and specified folder ---#
$Files = Get-Childitem $TargetFolders -Include $Extensions -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}

foreach ($File in $Files) 
 {
 if ($File -ne $NULL)
 {
 write-host "Deleting file $File" -ForegroundColor "White"
 Remove-Item $File.FullName | out-null
 }
 else
 {
 Write-Host "No recent files to delete!" -foregroundcolor "Green"
 }
 }