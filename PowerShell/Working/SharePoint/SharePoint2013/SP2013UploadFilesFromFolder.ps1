## SharePoint Server: PowerShell Function To Upload Documents From A File Location To A SharePoint Library ##

## Overview: PowerShell Script that takes documents from a file location and adds them to a specified SharePoint library
## Environments: MOSS 2007, and SharePoint Server 2010 / 2013 Farms
## Resource: http://www.sharepointdiary.com/2012/10/bulk-upload-files-to-sharepoint-using.html
## Usage; Change the '$Files' and '$Metadata' variables if required, and call the function like the example below
## Usage Example: UploadAllFilesFromDir "http://YourSiteURL" "DocumentFolderName" "c:\Documents\"
## Important: The source directory file structure cannot contain folders and sub-folders

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null
  
 
#Function to Upload File
function UploadAllFilesFromDir($WebURL, $DocLibName, $FolderPath)
{
 
#Get the Web & Lists to upload the file
 $site = New-Object Microsoft.SharePoint.SPSite($WebURL)
 $web= $site.OpenWeb()
       
 
#Get the Target Document Library to upload
$List = $Web.GetFolder($DocLibName)
  
#Get the Files from Local Folder
$Files = Get-ChildItem $FolderPath #You can filter files by: -filter “*.pdf” 
 
#upload the files
foreach ($File in $Files)
{
    #Get the Contents of the file to FileStream 
    $stream = (Get-Item $file.FullName).OpenRead()
     
    # Set Metadata Hashtable For the file - OPTIONAL
    $Metadata = @{"Country" = "United States"; "Domain" = "Sales"}
     
    #upload the file              
    $uploaded = $List.Files.Add($File.Name, $stream,$Metadata, $TRUE)
     
    #dispose FileStream Object
    $stream.Dispose()
}
  
#Dispose the site object
$site.Dispose()
}

