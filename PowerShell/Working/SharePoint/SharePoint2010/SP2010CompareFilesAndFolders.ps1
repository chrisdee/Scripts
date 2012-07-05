## SharePoint Server: PowerShell Commands To Compare Files And Folders Between Servers ##
## Usage: Can be used for comparing 'FEATURES' and other directories
## Compare-Object PowerShell commandlet can be used for any other files and folders - not just SharePoint

$Server1 =  Dir "\\spcharon1\c$\Program Files\Common Files\Microsoft Shared\Web Server Extensions\12\TEMPLATE\FEATURES"
$Server2 =  Dir "\\spleda3\c$\Program Files\Common Files\Microsoft Shared\Web Server Extensions\12\TEMPLATE\FEATURES"

Compare-Object $Server1 $Server2
