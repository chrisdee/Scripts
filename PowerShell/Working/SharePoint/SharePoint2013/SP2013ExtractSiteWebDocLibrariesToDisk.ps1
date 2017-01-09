## SharePoint Server: PowerShell Script to Download All Document Libraries from a Site Collection or Sub Site (web) ##

<#

Overview: PowerShell Function that downloads all files from all libraries at Site Collection or Web level. Also includes logging in the same directory specified in the Output Location

Environments: SharePoint Server 2013 + Farms

Usage: Run the script and when prompted provide the details for the '$exportPath' and '$URL' variables, or run the script like the example below passing the parameters

./SP2013ExtractSiteWebDocLibrariesToDisk.ps1 -OutputLocation "C:\export" -url "https://portal.sharepointfire.com"

Resource: http://www.sharepointfire.com/2015/12/download-documents-from-a-sharepoint-site-or-web/

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction "silentlycontinue"
 
$exportPath = Read-Host "Enter the export location (eg. C:\export). This directory will be created if it doesn’t exist"
$URL = Read-Host "Enter the url from SharePoint (eg https://portal.sharepointfire.com). This needs to be a site collection or web"
 
function downloadFiles($OutputLocation, $url){
#Create output folders
$rootFolder = createFolder ($OutputLocation + "\Output")
$errorFolder = createFolder ($rootFolder + "\Errors")
 
#Create logging files
$loggingFile = createFile ($rootFolder + "\logging.csv")
$notDownloadedFile = createFile ($rootFolder + "\notDownloaded.csv")
$errorFile = createFile ($rootFolder + "\errors.csv")
 
#Verify that the URL is a web in SharePoint
try{
$web = get-spweb $url -erroraction "silentlycontinue"
$web.dispose()
write-host "Update: Starting downloading specified web" -foregroundcolor green
 
#Start download of specified url
downloadWeb $url $rootFolder
}
catch{
write-host "Error: URL is not a valid web in SharePoint" -foregroundcolor red
}
}
 
function createFolder($folderPath){
#Create directory
#first test if the directory is not longer then 248 characters.
$count = $folderPath | measure-object -character
 
if ($count.characters -le 247){
#verify if the parth exists
if (!(Test-Path -path $folderPath)){
New-Item $folderPath -type directory | out-null
write-host "Folder created: $($folderPath)" -foregroundcolor green
}
else{
write-host "Folder already exists, trying to create a unique folder with random number" -foregroundcolor yellow
 
#create a random to add to the folder name because it already exists
$randomNumber = Get-Random -minimum 1 -maximum 10
if ((Test-Path -path $errorFile) -eq $true){
add-content -value "Folder: $($folderPath) already exists and created a unique folder with number $($randomNumber)" -path $errorFile
}
 
$folderPath = createFolder ($folderPath + $randomNumber)
}
}
else{
#create a folder under errors to download the files to
write-host "Foldername is to long, trying to create a folder under the errors folder" -foregroundcolor yellow
if ((Test-Path -path $errorFile) -eq $true){
add-content -value "Folder: $($folderPath) is to long and documents have been moved to the error folder under $SPWeb.Title" -path $errorFile
}
 
$folderpath = $errorFolder + "\site-" + $SPWeb.Title
New-Item $folderPath -type directory | out-null
}
return $folderPath
}
 
function createFile($filePath){
#Create file
if (!(Test-Path -path $filePath)){
New-Item $filePath -type file | out-null
write-host "File created: $($filePath)" -foregroundcolor green
}
else{
#add a number to the file name if it already exists
write-host "File already exists, trying to create a unique folder with random number" -foregroundcolor yellow
$randomNumber = Get-Random -minimum 1 -maximum 100
add-content -value "File: $($filePath) already exists and created a unique file with number $($randomNumber)" -path $errorFile
$filePath = createFile ($filePath + $randomNumber)
}
return $filePath
}
 
function downloadWeb($startWeb, $rootFolder){
#Get web information with PowerShell
$SPWeb = get-spweb "$startWeb"
 
#Store the full sitefolder url in a variable and create the folder
$siteFolder = createFolder ($rootFolder + "\site-" + $SPweb.Title)
 
#Store the full url in a text file inside the folder
$SPWeb.url | out-file -filepath $siteFolder\siteURL.txt
 
#Loop through all the document libraries
foreach($list in $SPweb.lists){
if($list.BaseType -eq "DocumentLibrary"){
#Get root folder
$listUrl = $web.Url +"/"+ $list.RootFolder.Url
#Download root files
downloadLibrary $list.RootFolder.Url
#Download files in folders
foreach ($folder in $list.Folders){
downloadLibrary $folder.Url
}
}
}
 
#add logging to show which webs have been touched
add-content -value "Downloaded: $($SPWeb.url)" -path $loggingFile
 
#Loop through each subsite of the web
$SPWebs = $SPWeb.webs
foreach($SPweb in $SPwebs){
downloadWeb $SPweb.url $siteFolder
}
 
#dispose web
$SPWeb.dispose()
}
 
function downloadLibrary ($libraryURL){
#Create folder based on document library name
$SPLibrary = $SPWeb.GetFolder($libraryURL)
$libraryFolder = createFolder ($siteFolder + "\lib-" + $SPLibrary.url)
Write-Host "Downloading library: $($SPLibrary.name)" -foreground darkgreen
add-content -value "Downloading library: $($SPLibrary.name)" -path $loggingFile
 
foreach ($file in $SPLibrary.Files){
#Download file
try{
$binary = $file.OpenBinary()
$stream = New-Object System.IO.FileStream($libraryFolder + "\" + $file.Name), Create
$writer = New-Object System.IO.BinaryWriter($stream)
$writer.write($binary)
$writer.Close()
}
catch{
write-host "File: $($file.Name) error" -foregroundcolor red
add-content -value "File: $($SPWeb.url) has not been downloaded" -path $notDownloadedFile
}
}
}
 
downloadFiles -OutputLocation $exportPath -url $url