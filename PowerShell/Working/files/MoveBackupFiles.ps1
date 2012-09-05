## PowerShell: Script To Move File Types From One Location To Another ##
## Usage: Powershell move backup files script – useful for SQL backups or any other files that need to be moved

$file = "F:\temp\Job_logs" ## This will be your source backup folder
$archive = "F:\temp\archive\" ## This will be your destination folder

foreach ($file in gci $file -include *.bak -recurse) ## Change the file type here to suit other backup file types
{
Move-Item -path $file.FullName -destination $archive ## Move the files to the archive folder
}
