## SharePoint Server: PowerShell Script to Report on Content Databases and the Size of Site Collections and Sub-sites (webs) within these ##

# Environments: SharePoint Server 2010 / 2013 Farms
# Example: GetGeneralInfo "http://yourwebapp/yoursitecollection.com" "C:\GeneralInfo.csv"

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

function GetWebSizes ($StartWeb)
{
    $web = Get-SPWeb $StartWeb
    [long]$total = 0
    $total += GetWebSize -Web $web
    $total += GetSubWebSizes -Web $web
    $totalInMb = ($total/1024)/1024
    $totalInMb = "{0:N2}" -f $totalInMb
    $totalInGb = (($total/1024)/1024)/1024
    $totalInGb = "{0:N2}" -f $totalInGb
    #write-host "Total size of all sites below" $StartWeb "is" $total "Bytes,"
    #write-host "which is" $totalInMb "MB or" $totalInGb "GB"
    "Total size for all sites in Bytes  `t $($total) Bytes" | Out-File $OutputFile -Append
    "Total size for all sites in MB `t $($totalInMb) MB" | Out-File $OutputFile -Append
    "Total size for all sites in GB `t $($totalInGb) GB" | Out-File $OutputFile -Append

    $web.Dispose()
}
function GetWebSize ($Web)
{
    [long]$subtotal = 0
    foreach ($folder in $Web.Folders)
    {
        $subtotal += GetFolderSize -Folder $folder
    }
    #write-host "Site" $Web.Title "is" $subtotal "KB"
    "Site $($Web.Title) `t $($subtotal) KB" | Out-File $OutputFile -Append
    return $subtotal
}
function GetSubWebSizes ($Web)
{
    [long]$subtotal = 0
    foreach ($subweb in $Web.GetSubwebsForCurrentUser())
    {
        [long]$webtotal = 0
        foreach ($folder in $subweb.Folders)
        {
            $webtotal += GetFolderSize -Folder $folder
        }
        #write-host "Site" $subweb.Title "is" $webtotal "Bytes"
        "Site $($subweb.Title) `t $($webtotal) Bytes" | Out-File $OutputFile -Append
        $subtotal += $webtotal
        $subtotal += GetSubWebSizes -Web $subweb
    }
    return $subtotal
}

function GetFolderSize ($Folder)
{
    [long]$folderSize = 0 
    foreach ($file in $Folder.Files)
    {
        $folderSize += $file.Length;
    }
    foreach ($fd in $Folder.SubFolders)
    {
        $folderSize += GetFolderSize -Folder $fd
    }
    return $folderSize
}

Function GetGeneralInfo($siteUrl, $OutputFile)
{


#Write CSV- TAB Separated File) Header
"Name `t Value" | out-file $OutputFile

$ContentDB =  Get-SPContentDatabase -site $siteUrl
$ContentDatabaseSize = [Math]::Round(($ContentDatabase.disksizerequired/1GB),2)

"Database Name  `t $($ContentDB.Name)" | Out-File $OutputFile -Append
"Database ID  `t $($ContentDB.ID)" | Out-File $OutputFile -Append
"Site count `t $($ContentDB.CurrentSiteCount)" | Out-File $OutputFile -Append
"Site count `t $($ContentDB.MaximumSiteCount)" | Out-File $OutputFile -Append
"Can Migrate `t $($ContentDB.CanMigrate)" | Out-File $OutputFile -Append
"Content DB Size `t $($ContentDatabaseSize) GB" | Out-File $OutputFile -Append
"Database Servername `t $($ContentDB.Server)" | Out-File $OutputFile -Append
"Connection String `t $($ContentDB.DatabaseConnectionString)" | Out-File $OutputFile -Append
"Display Name `t $($ContentDB.DisplayName)" | Out-File $OutputFile -Append
"Schema `t $($ContentDB.SchemaVersionXml)" | Out-File $OutputFile -Append


GetWebSizes -StartWeb $siteUrl
}


#GetGeneralInfo "http://yourwebapp/yoursitecollection.com" "C:\GeneralInfo.csv"

