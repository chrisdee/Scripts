## PowerShell: Script to Move Files to Folders Sorted By Year and Month ##

<#

Overview: PowerShell script that takes all the files from a Source Folder and sorts them into Yearly Folders with Monthly Sub Folders 

Resource: http://www.thomasmaurer.ch/2015/03/move-files-to-folder-sorted-by-year-and-month-with-powershell

Usage: Edit the following variables to match your environment and run the script: '$files'; '$targetPath' 

#>

# Get the files which should be moved, without folders
$files = Get-ChildItem '\\SERVER1\d$\Logs\IIS\W3SVC558284704' -Recurse | where {!$_.PsIsContainer}
 
# List Files which will be moved
$files
 
# Target Filder where files should be moved to. The script will automatically create a folder for the year and month.
$targetPath = '\\SERVER2\d$\Logs\IIS\Archive'
 
foreach ($file in $files)
{
# Get year and Month of the file
# I used LastWriteTime since this are synced files and the creation day will be the date when it was synced
$year = $file.LastWriteTime.Year.ToString()
$month = $file.LastWriteTime.Month.ToString()
 
# Out FileName, year and month
$file.Name
$year
$month
 
# Set Directory Path
$Directory = $targetPath + "\" + $year + "\" + $month
# Create directory if it doesn't exsist
if (!(Test-Path $Directory))
{
New-Item $directory -type directory
}
 
# Move File to new location
$file | Move-Item -Destination $Directory
}