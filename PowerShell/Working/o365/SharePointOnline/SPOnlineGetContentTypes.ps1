## SPOnline PowerShell Script to Get All Content Types from a CTHub via CSOM ##

$libPath = "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\" #Change this to match your environment

$OutputFilePath = "C:\BoxBuild\Scripts\SPOnlinePublishCTHubContentTypes\ContentTypesAll.csv" #Change this to match your environment

## Usage Example: ListContentTypes -webUrl https://YourTenant.sharepoint.com/sites/ContentTypeHub/ 

# the path here may need to change if you used e.g. C:\Lib.. 
Add-Type -Path $libPath"Microsoft.SharePoint.Client.dll" 
Add-Type -Path $libPath"Microsoft.SharePoint.Client.Runtime.dll" 

function ListContentTypes { 

    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$True,Position=1)]
       [string]$webUrl
    )

    # connect/authenticate to SharePoint Online and get ClientContext object.. 
    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl) 
    try{
        
        $credentials = Get-Credential

        $clientContext.Credentials =  New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($credentials.UserName, $credentials.Password) 

        if (!$clientContext.ServerObjectIsNull.Value) 
        { 
            Write-Host "Connected to SharePoint Online site: '$webUrl'" -ForegroundColor Green 

            $web = $clientContext.Web
            $clientContext.Load($web)
            $clientContext.Load($web.ContentTypes)
            $clientContext.ExecuteQuery()
            
            #Write-Host $web.ContentTypes.Count

            $cts = @()
            $web.ContentTypes | ForEach-Object {
 
                $ct = New-Object PSObject -Property  @{ Name = $_.Name; Id = $_.Id; Group = $_.Group}
                $ct | export-csv $OutputFilePath -notypeinformation -Delimiter "," -Append
                 
            }
                       
        } 

    }finally{
        $clientContext.Dispose()
    }

}
