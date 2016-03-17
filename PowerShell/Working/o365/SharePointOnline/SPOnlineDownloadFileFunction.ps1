## SharePoint Online: PowerShell Function to Download Items from SharePoint Online (SPOnline) Libraries via CSOM ##

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")


 Function Download-File([string]$UserName, [string]$Password,[string]$FileUrl,[string]$DownloadPath)
 {
    if([string]::IsNullOrEmpty($Password)) {
      $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
    }
    else {
      $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    }
    $fileName = [System.IO.Path]::GetFileName($FileUrl)
    $downloadFilePath = [System.IO.Path]::Combine($DownloadPath,$fileName)


    $client = New-Object System.Net.WebClient 
    $client.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
    $client.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
    $client.DownloadFile($FileUrl, $downloadFilePath)
    $client.Dispose()
}

## Example calling the function
Download-File -UserName "User.Name@TenantName.onmicrosoft.com" -Password "UserPassWord" -FileUrl "https://TenantName.sharepoint.com/sites/contentTypeHub/Style%20Library/Images/Search_Arrow.jpg" -DownloadPath "C:\ztemp"