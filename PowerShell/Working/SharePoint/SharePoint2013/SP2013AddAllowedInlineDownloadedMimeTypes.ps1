## SharePoint Server: PowerShell Script to Add MIME Types At Web Application Level ##

<#

Overview: PowerShell Script to Check whether MIME Types exist in a SharePoint Web Application, and adds the entry to the 'AllowedInlineDownloadedMimeTypes' list when speciified

Environments: SharePoint Server 2010 / 2013 Farms

Resources:

http://sharepoint.stackexchange.com/questions/39020/how-do-i-prevent-sharepoint-from-asking-to-download-html-files-to-my-local-machi 

http://jasonwarren.ca/add-and-remove-mime-types-from-sharepoint-powershell

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Write-Host "This script will check if a particular MIME Type is excluded from the AllowedInlineDownloadedMimeTypes list when STRICT Browser File Handling Permissions are set on the Web Application" -foregroundcolor Darkcyan
$webAppRequest = Read-Host "What is the name of your Web Application? example: http://WebApp.YourDomain.com"
$webApp = Get-SPWebApplication $webAppRequest
$mimeType = Read-Host "Which MIME Type would you like to confirm is included in the AllowedInlineDownloadedMimeTypes list for $webAppRequest? example: application/pdf or text/html"
If ($webApp.AllowedInlineDownloadedMimeTypes -notcontains "$mimeType")
{
    write-host "$mimeType does not exist in the AllowedInlineDownloadedMimeTypes list" -foregroundcolor Yellow
    $addResponse = Read-Host "Would you like to add it? (Yes/No)"
    if ($addResponse -contains "Yes")
    {
        $webApp.AllowedInlineDownloadedMimeTypes.Add("$mimeType")
        $webApp.Update()
        Write-Host "The MIME Type ' $mimeType ' has now been added" -foregroundcolor Green
        $iisresponse = Read-Host "This change requires an IIS Restart to take affect, do you want to RESET IIS now (Yes/No)"
        if ($iisResponse -contains "Yes")
        {
            IISRESET
            Write-Host "IIS has now been reset" -foregroundcolor Green
        }
        else
        {
            Write-Host "IIS has not been reset, please execute the IISRESET command at a later time" -foregroundcolor Yellow
        }
    }
    else
    {
        Write-Host "The MIME Type ' $mimeType ' was not added" -foregroundcolor Red
    }
}
else
{
    Write-Host "The MIME Type ' $mimeType ' already exists in the AllowedInlineDownloadedMimeTypes list for this Web Application" -foregroundcolor Yellow
    $addResponse = Read-Host "Would you like to remove it? (Yes/No)"
    if ($addResponse -contains "Yes")
    {
        $webApp.AllowedInlineDownloadedMimeTypes.Remove("$mimeType")
        $webApp.Update()
        Write-Host "The MIME Type ' $mimeType ' has now been removed" -foregroundcolor Green
        $iisresponse = Read-Host "This change requires an IIS Restart to take affect, do you want to RESET IIS now (Yes/No)"
        if ($iisResponse -contains "Yes")
        {
            IISRESET
            Write-Host "IIS has now been reset" -foregroundcolor Green
        }
        else
        {
            Write-Host "IIS has not been reset, please execute the IISRESET command at a later time" -foregroundcolor Yellow
        }
    }
    else
    {
        Write-Host "The MIME Type ' $mimeType ' was not removed" -foregroundcolor Red
    }
 
}
