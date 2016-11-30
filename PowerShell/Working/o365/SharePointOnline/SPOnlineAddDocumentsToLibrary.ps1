## SharePoint Online: PowerShell function to upload Documents from a Source folder to a Document Library via CSOM (SPOnline) ##

<#

Overview: PowerShell function to upload Documents from a folder to a Document Library via CSOM in SharePoint Online

Note: The script also preserves the folder structure from the source location

Usage: Provide parameters listed below, and the paths to your SharePoint binaries for the CSOM

Provide the required Parameters below in the Script: 

$Url = "https://contoso.sharepoint.com"
$UserName = "username@contoso.onmicrosoft.com"
$Password = "password"
$TargetListTitle = "Documents"   #Target Library
$SourceFolderPath = "C:\Users\user\Upload"  #Source Path

Provide the paths to your SharePoint DLLs for CSOM under '#Adding the CSOM Assemblies'

Resource: https://gist.github.com/vgrem/cf6cba630dc6b81b1bd8

#>

#Adding the CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

Function Ensure-Folder()
{
Param(
  [Parameter(Mandatory=$True)]
  [Microsoft.SharePoint.Client.Web]$Web,

  [Parameter(Mandatory=$True)]
  [Microsoft.SharePoint.Client.Folder]$ParentFolder, 

  [Parameter(Mandatory=$True)]
  [String]$FolderUrl

)

    $folderNames = $FolderUrl.Trim().Split("/",[System.StringSplitOptions]::RemoveEmptyEntries)
    $folderName = $folderNames[0]
    Write-Host "Creating folder [$folderName] ..."
    $curFolder = $ParentFolder.Folders.Add($folderName)
    $Web.Context.Load($curFolder)
    $web.Context.ExecuteQuery()
    Write-Host "Folder [$folderName] has been created succesfully. Url: $($curFolder.ServerRelativeUrl)"

    if ($folderNames.Length -gt 1)
    {
        $curFolderUrl = [System.String]::Join("/", $folderNames, 1, $folderNames.Length - 1)
        Ensure-Folder -Web $Web -ParentFolder $curFolder -FolderUrl $curFolderUrl
    }
}



Function Upload-File() 
{
Param(
  [Parameter(Mandatory=$True)]
  [Microsoft.SharePoint.Client.Web]$Web,

  [Parameter(Mandatory=$True)]
  [String]$FolderRelativeUrl, 

  [Parameter(Mandatory=$True)]
  [System.IO.FileInfo]$LocalFile

)

    try {
       $fileUrl = $FolderRelativeUrl + "/" + $LocalFile.Name
       Write-Host "Uploading file [$($LocalFile.FullName)] ..."
       [Microsoft.SharePoint.Client.File]::SaveBinaryDirect($Web.Context, $fileUrl, $LocalFile.OpenRead(), $true)
       Write-Host "File [$($LocalFile.FullName)] has been uploaded succesfully. Url: $fileUrl"
    }
    catch {
       write-host "An error occured while uploading file [$($LocalFile.FullName)]"
    }
}




function Upload-Files()
{

Param(
  [Parameter(Mandatory=$True)]
  [String]$Url,

  [Parameter(Mandatory=$True)]
  [String]$UserName,

  [Parameter(Mandatory=$False)]
  [String]$Password, 

  [Parameter(Mandatory=$True)]
  [String]$TargetListTitle,

  [Parameter(Mandatory=$True)]
  [String]$SourceFolderPath

)

    if($Password) {
       $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    }
    else {
      $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString
    }
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName,$SecurePassword)
    $Context.Credentials = $Credentials


    $web = $Context.Web 
    $Context.Load($web)
    $list = $web.Lists.GetByTitle($TargetListTitle);
    $Context.Load($list.RootFolder)
    $Context.ExecuteQuery()


    Get-ChildItem $SourceFolderPath -Recurse | % {
       if ($_.PSIsContainer -eq $True) {
          $folderUrl = $_.FullName.Replace($SourceFolderPath,"").Replace("\","/")   
          if($folderUrl) {
             Ensure-Folder -Web $web -ParentFolder $list.RootFolder -FolderUrl $folderUrl
          }  
       }
       else{
          $folderRelativeUrl = $list.RootFolder.ServerRelativeUrl + $_.DirectoryName.Replace($SourceFolderPath,"").Replace("\","/")  
          Upload-File -Web $web -FolderRelativeUrl $folderRelativeUrl -LocalFile $_ 
       }
    }
}


#Required Parameters

$Url = "https://contoso.sharepoint.com"
$UserName = "username@contoso.onmicrosoft.com"
$Password = "password"
$TargetListTitle = "Documents"   #Target Library
$SourceFolderPath = "C:\Users\user\Upload"  #Source Path 

#Upload files
Upload-Files -Url $Url -UserName $UserName -Password $Password -TargetListTitle $TargetListTitle -SourceFolderPath $SourceFolderPath