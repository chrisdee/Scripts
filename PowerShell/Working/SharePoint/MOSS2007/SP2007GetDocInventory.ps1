## SharePoint 2007: PowerShell Script to Enumerate All Documents on a MOSS 20007 Farm ##

function Get-DocInventory() {
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
    $farm = [Microsoft.SharePoint.Administration.SPFarm]::Local
    foreach ($spService in $farm.Services) {
        if (!($spService -is [Microsoft.SharePoint.Administration.SPWebService])) {
            continue;
        }

        foreach ($webApp in $spService.WebApplications) {
            if ($webApp -is [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]) { continue }

            foreach ($site in $webApp.Sites) {
                foreach ($web in $site.AllWebs) {
                    foreach ($list in $web.Lists) {
                        if ($list.BaseType -ne "DocumentLibrary") {
                            continue
                        }
                        foreach ($item in $list.Items) {
                            $data = @{
                                "Web Application" = $webApp.ToString()
                                "Site" = $site.Url
                                "Web" = $web.Url
                                "list" = $list.Title
                                "Item ID" = $item.ID
                                "Item URL" = $item.Url
                                "Item Title" = $item.Title
                                "Item Created" = $item["Created"]
                                "Item Modified" = $item["Modified"]
                                "File Size" = $item.File.Length/1KB
								"Item Versions" = $item.Versions.Count
                            }
                            New-Object PSObject -Property $data
                        }
                    }
                    $web.Dispose();
                }
                $site.Dispose()
            }
        }
    }
}
Get-DocInventory | Out-GridView
#Get-DocInventory | Export-Csv -NoTypeInformation -Path c:\inventory.csv