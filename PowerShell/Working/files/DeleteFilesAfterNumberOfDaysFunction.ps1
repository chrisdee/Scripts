## PowerShell: Function to Delete Files In a Folder older than a Specified Number of Days ##
 
$days=-7 #Change this to reflect the number of days files you wish to retain
(Get-Variable Path).Options="ReadOnly"
$Path="C:\inetpub\logs\LogFiles\W3SVC1" #Change this path to suit your environment
Write-Host "Removing IIS-logs keeping last" $days "days"
CleanTempLogfiles($Path)

function CleanTempLogfiles()
{
param ($FilePath)
    Set-Location $FilePath
    Foreach ($File in Get-ChildItem -Path $FilePath)
    {
        if (!$File.PSIsContainerCopy) 
        {
            if ($File.LastWriteTime -lt ($(Get-Date).Adddays($days))) 

            {
            remove-item -path $File -force
            Write-Host "Removed logfile: "  $File
            }
    }
} 
}
