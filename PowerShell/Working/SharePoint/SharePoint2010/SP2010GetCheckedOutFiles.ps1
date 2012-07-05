## SharePoint Server 2010: PowerShell Script to get all Checked Out files for all Site Collections in a Farm
## Resource: http://blog.falchionconsulting.com/index.php/2011/06/getting-and-taking-ownership-of-checked-out-files-using-windows-powershell/

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

function Get-CheckedOutFiles() {
    foreach ($web in (Get-SPSite -Limit All | Get-SPWeb -Limit All)) {
        Write-Host "Processing Web: $($web.Url)..."
        foreach ($list in ($web.Lists | ? {$_ -is [Microsoft.SharePoint.SPDocumentLibrary]})) {
            Write-Host "`tProcessing List: $($list.RootFolder.ServerRelativeUrl)..."
            foreach ($item in $list.CheckedOutFiles) {
                if (!$item.Url.EndsWith(".aspx")) { continue }
                $hash = @{
                    "URL"=$web.Site.MakeFullUrl("$($web.ServerRelativeUrl.TrimEnd('/'))/$($item.Url)");
                    "CheckedOutBy"=$item.CheckedOutBy;
                    "CheckedOutByEmail"=$item.CheckedOutByEmail
                }
                New-Object PSObject -Property $hash
            }
            foreach ($item in $list.Items) {
                if ($item.File.CheckOutStatus -ne "None") {
                    if (($list.CheckedOutFiles | where {$_.ListItemId -eq $item.ID}) -ne $null) { continue }
                    $hash = @{
                        "URL"=$web.Site.MakeFullUrl("$($web.ServerRelativeUrl.TrimEnd('/'))/$($item.Url)");
                        "CheckedOutBy"=$item.File.CheckedOutByUser;
                        "CheckedOutByEmail"=$item.File.CheckedOutByUser.Email
                    }
                    New-Object PSObject -Property $hash
                }
            }
        }
        $web.Dispose()
    }
}
Get-CheckedOutFiles | Out-GridView
#Get-CheckedOutFiles | Export-Csv -NoTypeInformation -Path "c:\Checked_Out_Files.csv"