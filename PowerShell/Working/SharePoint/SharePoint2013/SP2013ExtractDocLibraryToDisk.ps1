## SharePoint Server: PowerShell Script To Extract All Documents From A Library To A File Location ##
## Environments: MOSS 2007, and SharePoint Server 2010 / 2013 Farms
## Important: Use SharePoint Manager to confirm Doc Library names (http://spm.codeplex.com)

<#
.Synopsis
	Use Pull-Documents to copy the entire document library to disk
.Description
	This script iterates recursively over all directories and files in a document library and writes binary data to the disk
	The same folder structure is kept as in the Document library	
.Usage Examples
	1. Run the script and provide parameters for the following variables '$Url', '$Library' when prompted
    2. Call the script with the parameters - example: ./SP2007ExtractDocLibraryToDisk.ps1 "http://YourWebAppURL" "YourDocLibrary"
.Notes
    In SharePoint Server 2013 'Documents' is actually still called 'Shared Documents' via the Object Model
	The files will be saved in the same location where you run the script from
	Keywords: SPList, Documents, Files, SPDocumentLibrary
.Links
	http://sharepointkunskap.wordpress.com
    http://sharepointkunskap.wordpress.com/2012/12/11/powershell-copy-an-entire-document-library-from-sharepoint-2007-to-disk
	https://github.com/mirontoli/sp-lend-id/blob/master/aran-aran/Pull-Documents.ps1
.Inputs
	None
.Outputs
	None
#>
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)][System.String]$Url = $(Read-Host -prompt "Web Url"),
[Parameter(Mandatory=$true)][System.String]$Library = $(Read-Host -prompt "Document Library Name")
)
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

$site = new-object microsoft.sharepoint.spsite($Url)
$web = $site.OpenWeb()
$site.Dispose()

$folder = $web.GetFolder($Library)
$folder # must output it otherwise "doesn't exist" in 2007

if(!$folder.Exists){
	Write-Error "The document library cannot be found"
	$web.Dispose()
	return
}

$directory = $pwd.Path

$rootDirectory = Join-Path $pwd $folder.Name

if (Test-Path $rootDirectory) {
	Write-Error "The folder $Library in the current directory already exists, please remove it"
	$web.Dispose()
	return
}

#progress variables
$global:counter = 0
$global:total = 0
#recursively count all files to pull
function count($folder) {
	if ($folder.Name -ne "Forms") {
		$global:total += $folder.Files.Count
		$folder.SubFolders | Foreach { count $_ }
	}
}
write "counting files, please wait..."
count $folder
write "files count $global:total"

function progress($path) {
	$global:counter++
	$percent = $global:counter / $global:total * 100
	write-progress -activity "Pulling documents from $Library" -status $path -PercentComplete $percent
}

#Write file to disk
function Save ($file, $directory) {
	$data = $file.OpenBinary()
	$path = Join-Path $directory $file.Name
	progress $path
	[System.IO.File]::WriteAllBytes($path, $data)
}

#Forms folder doesn't need to be copied
$formsDirectory = Join-Path $rootDirectory "Forms"

function Pull($folder, [string]$directory) {
	$directory = Join-Path $directory $folder.Name
	if ($directory -eq $formsDirectory) {
		return
	}
	mkdir $directory | out-null
	
	$folder.Files | Foreach { Save $_ $directory }

	$folder.Subfolders | Foreach { Pull $_ $directory }
}

Write "Copying files recursively"
Pull $folder $directory

$web.Dispose()