## Azure: PowerShell Script to Upload Files to an Azure Web App from an Azure Storage Account File Service Share ##

<#

Overview: PowerShell Script that Uploads files from an Azure Storage Account File Service Share to an Azure Web App via the Kudu API using the Publish Profile Credentials

Usage: Modify the 'Setting variables' below to suit your environment and run the script

Note: To upload files to a different location than the Azure web app 'wwwroot' folder, modify the path on the '$kuduApiUrl' variable

Important: The Script currently only uploads 'flat' files in a directory and not folders and sub-folders

Resource: http://blog.octavie.nl/index.php/2017/03/03/copy-files-to-azure-web-app-with-powershell-and-kudu-api

#>

#Requires -Version 3.0

Login-AzureRmAccount

#
#
# Functions
#

function Get-PublishingProfileCredentials($resourceGroupName, $webAppName){

	$resourceType = "Microsoft.Web/sites/config"
	$resourceName = "$webAppName/publishingcredentials"

	$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force

   	return $publishingCredentials
}

function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName){

    $publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName

    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}

function Upload-FileToWebApp($kuduApiAuthorisationToken, $webAppName, $fileName, $localPath ){

	$kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$fileName" #Change this path to another Azure web app folder location if required
    
    $result = Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method PUT `
                        -InFile $localPath `
                        -ContentType "multipart/form-data"
}

Write-Host
Write-Host -f White "Upload Files to Web App - v1.0"
Write-Host -f DarkMagenta "(c) 2017 - Mavention"
Write-Host

#
#
# Setting variables
#
$resourceGroupName = "YourAzureResourceGroupName"
$storageAccountName = "YourAzureStorageAccountName"
$shareName = "yourazuresharename" #Note: Azure shares need to be in lower case
$folderName = "YourFolderName"
$webApps = @( "YourAzureWebAppName1", "YourAzureWebAppName2")

#
#
# Source Location
#
Write-Host "Retrieving files from $storageAccountName"
$context = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
$share = Get-AzureStorageShare -Name $shareName -Context $context
$files = Get-AzureStorageFile $share -Path $folderName | Get-AzureStorageFile

if( $files.Count -gt 0 )
{
	# Download the files to a local temp folder
	Write-Host "Creating local temp folder"
	$parent = [System.IO.Path]::GetTempPath()
	[string] $name = [System.Guid]::NewGuid()
	$tempFolder = (Join-Path $parent $name)
	$tf = New-Item -ItemType Directory -Path $tempFolder

	Write-Host "Downloading files to $tempFolder"
	$files | Get-AzureStorageFileContent -Destination $tempFolder
	Write-Host "Finished downloading $($files.count) files"

	$localFiles = Get-ChildItem $tempFolder


	#
	#
	# Destination(s)
	#


	$webApps | % {

		$webappName = $_

		Write-Host
		Write-Host -f Yellow $webappName
		$accessToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webappName
	
		$localFiles | % {
			Write-Host "Uploading $($_.Name)" -NoNewline
			Upload-FileToWebApp $accessToken $webappName $_.Name $_.FullName 
			Write-Host -f Green " [Done]"
		}
	}

	# Remove Temp Folder
	Write-Host
	Write-Host "Removing local temp folder $tempFolder"
	Remove-Item $tempFolder -Recurse -Force
}
else
{

	Write-Host -ForegroundColor Yellow "No files exist."

}

Write-Host 
Write-Host -ForegroundColor Green "Finished"
Write-Host