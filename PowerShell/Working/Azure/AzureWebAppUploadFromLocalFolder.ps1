## Azure: PowerShell Script to Upload Files to an Azure Web App From a Local Folder ##

<#

Overview: PowerShell Script that Uploads files from a local file location to an Azure Web App via the Kudu API using the Publish Profile Credentials

Usage: Modify the variables below to suit your environment and run the script

Note: To upload files to a different location than the Azure web app 'wwwroot' folder, modify the path on the '$kuduApiUrl' variable

Important: The Script currently only uploads 'flat' files in a directory and not folders and sub-folders

Resource: http://blog.octavie.nl/index.php/2017/03/03/copy-files-to-azure-web-app-with-powershell-and-kudu-api

#>


### Start Variables ###
$tempFolder = "C:\YourFolderName" #Provide the path to your files here
$resourceGroupName = "YourAzureResourceGroupName"
$webAppName = "YourAzureWebAppName"
### End Variables ###

Login-AzureRmAccount

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

$localFiles = Get-ChildItem $tempFolder
 
$accessToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webappName
     
$localFiles | % {
    Write-Host "Uploading $($_.Name)" -NoNewline
    Upload-FileToWebApp $accessToken $webappName $_.Name $_.FullName 
    Write-Host -f Green " [Done]"
}