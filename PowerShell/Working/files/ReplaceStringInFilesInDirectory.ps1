## PowerShell Script to Search For And Replace Strings In Specific Files In A Directory ##

### Start Variables ###
$FilePath = "C:\BoxBuild\Scripts\Monitors"
$FileType = "ps1" #Replace this with a '*' for all files if you don't want a file type filter
$OriginalString = "email.yourorg.com"
$NewString = "appmail.yourorg.com"

### End Variables ###

cd $FilePath

$configFiles=get-childitem . *.$FileType -recurse
foreach ($file in $configFiles)
{
(Get-Content $file.PSPath) | 
Foreach-Object {$_ -replace $OriginalString, $NewString} | 
Set-Content $file.PSPath
}