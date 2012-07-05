## MOSS 2007: PowerShell Script To Set Library Version Settings And Delete Major and Minor Versions
## Resource: http://blogs.sharepointpro.net/2011/04/29/limit-the-number-of-versions-in-sharepoint-2007.aspx

### BEGIN VARIABLES ###
$siteUrl="http://teamsites.training.local/sites/Versions" #Change this to suit your environment
$csvFile=".\TMP\sites.csv" #Change this to suit your environment
$useCsvFile=$false #If set to $true; this will look for the $csvFile specified above 
$outPut="E:\VersionDeletionReport.xml" 
$deleteVersion=$false #CAUTION!!!When set to false will only report on files that would be Deleted, else if $true versions are Deleted.
[Int]$keepMajorVersions=5 #Keeps the number of major versions specified here + 1 version
[int]$keepMinorVersions=2 #Keeps the number of most recent minor versions specified here
$setVersionLimit=$false #When set to $true will set Major Versions to $keepMajorVersions.  If minor versions are enabled, will set number of minor versions to $keepMinorVersions
$libraryExclusions="Style Library" #Type the title of the library to be excluded.  format should be: $libraryExclusions="Style Library","Site Collection Images"
### END VARIABLES ###
[system.reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint") 
 
function DeleteVersion
{
    if($deleteVersion -eq $true)
    {
        for($x=$deleteVersions.Count; $x -ne -1;$x--)
        {
            Try 
            {
                if($file.Versions.GetVersionFromLabel($file.versions[$deleteVersions[$x]].versionlabel))
                {  
                    Start-Sleep -Seconds 1  
                    $fileVersion=$file.Versions.GetVersionFromLabel($file.versions[$deleteVersions[$x]].versionlabel) 
                    $fileVersion.versionLabel
                    $file.name
                    $file.Versions.DeleteByLabel($file.versions[$deleteVersions[$x]].versionLabel)
                } 
            }
            Catch [System.Management.Automation.RuntimeException]
            {
                #Index operation failed. The array index evaluated to null
            }
        }
    } 
    try
    {
        $item.SystemUpdate()
    }
    Catch [System.Exception]
    {
        #No updates were made
    }        
}
function GetVersions 
{
    $deleteVersions=New-Object system.Collections.ArrayList 
    $versionsArray=New-Object system.Collections.ArrayList 
 
    for($i=0;$i -lt $counter;$i++)
    {
        if($file.Versions[$i].VersionLabel)
        {
            $strVersion=($file.Versions[$i].VersionLabel).Split(".")                              
 
                if([int]$($strVersion[0]) -lt ($file.MajorVersion - $keepMajorVersions))
                { 
                      if($file.Versions[$i].IsCurrentVersion -eq $false)
                      {
                        if($strVersion[1] -eq 0)
                        {
                            $versionType="Major" 
                        }
                        else 
                        {
                            $versionType="Minor"
                        }
                        VersionInformation 
                          [Void]$deleteVersions.Add($i) 
                      }
                   }
                if([int]$($strVersion[0]) -ge ($file.MajorVersion - $keepMajorVersions))
                  {
                    if([int]$($strVersion[1]) -ne 0)
                    {          
                        [Void]$versionsArray.Add($i)
                    }
                }
        } 
    } 
    GetMinorVersions
    DeleteVersion
}
 
function Remove-MinorVersions
{
    for($r=0;$r -le $newArray.Count;$r++)
    {
        Try 
        {
            $strCurrentMinorVersion=($file.Versions[$newArray[$r]].versionLabel).Split(".")
            [int]$intCurrentMinorVersion=$strCurrentMinorVersion[1]                    
 
                if($newArray.Count -gt $keepMinorVersions)
                {    
                    if(($intCurrentMinorVersion -gt ($highVersion - $keepMinorVersions)))
                    {
                        ;#Not deleting version
                    }
                    elseif(($intCurrentMinorVersion -le ($highVersion - $keepMinorVersions)))
                    {
                        $i=$newArray[$r]
                        VersionInformation 
                        [Void]$deleteVersions.Add($newArray[$r])                                                        
                    }
                }
        }
        Catch [System.Exception]
        {     ;     }
    }     
}
 
function Find-HighVersion 
{     
    $highVersion=0
    
    for($s=0;$s -le $newArray.Count;$s++)
    {     
        Try 
        {
            $strMinorVersion=($file.Versions[$newArray[$s]].VersionLabel).Split(".")            
            [int]$intHighVersion=$strMinorVersion[1]              
 
                if($intHighVersion -ge $highVersion)
                {                       
                    $highVersion=$intHighVersion                    
                }
        }
        Catch [System.Exception]
        {     ;     }
    }     
    Remove-MinorVersions 
}
 
function GetMinorVersions 
{
    $pVersion="-1000.1000" 
    $pVersion=$pVersion.Split(".")
    $newArray=New-Object system.Collections.ArrayList  
 
        for($t=0;$t -lt $versionsArray.Count;$t++)
         {
            $strMinorVersion=($file.Versions[$versionsArray[$t]].VersionLabel).Split(".") 
 
            if(($t -eq ($versionsArray.Count - 1)) -or(([int]$($strMinorVersion[0]) - [int]$($pVersion[0])) -gt 0))
            {     
                if($t -eq ($versionsArray.Count - 1))
                {                   
                    if(([int]$($strMinorVersion[0]) - [int]$($pVersion[0])) -gt 0) #Checks to see if it is the same Minor version
                    {                                   
                        Find-HighVersion 
                        $newArray.Clear()
                        [Void]$newArray.Add($versionsArray[$t])                           
                    }
                    else 
                    {
                        [Void]$newArray.Add($versionsArray[$t]) 
                    }
                }
                if($newArray.Count -gt 0)
                { 
                    Find-HighVersion 
                }  
                if($t -ne ($versionsArray.Count - 1))
                {               
                    $pVersion=$strMinorVersion
                      $newArray.Clear()
                      [Void]$newArray.Add($versionsArray[$t])
                }
            }
            elseif(([int]$($strMinorVersion[0]) - [int]$($pVersion[0])) -eq 0)
            {  
                [Void]$newArray.Add($versionsArray[$t])    
            } 
    }
}
 
function VersionInformation
{
    $webUrl=$web.url 
    $listName=$list.title 
    $itemUrl=$file.Versions[$i].File.url 
    $itemName=$file.Versions[$i].File.name 
    $versionLabel=$file.Versions[$i].VersionLabel 
    [Int32]$fileSizeBytes=$file.Versions[$i].Size
    $fileSizeKb=$fileSizeBytes / 1024
    [Int32]$global:totalSpaceKb=$totalSpaceKb + $fileSizeKb 
    $itemInfo=@"
<New>
<Site>$webUrl</Site>
<List>$listName</List>
<VersionType>$versionType</VersionType>
<ItemUrl>$itemUrl</ItemUrl>
<ItemName>$itemName</ItemName>
<Action>Deleted Version</Action>
<Version>$versionLabel</Version>
<FileSize>$fileSizeKb</FileSize>
</New>
"@ 
out-file -inputobject $itemInfo -filepath $output -encoding ASCII -append -width 50 
 
}
function Set-VersionLimit
{
    if($list.EnableVersioning -eq $true)
    {
        $list.MajorVersionLimit=$keepMajorVersions
        
        if($list.EnableMinorVersions -eq $true)
        {    
            $list.MajorWithMinorVersionsLimit=$keepMinorVersions
        }
        
        $list.Update()
    }
} 
 
$createXml=@" 
<?xml version="1.0" encoding="ISO-8859-1" ?>
<VersionReport>
"@ 
out-file -inputobject $createxml -filepath $output -encoding ASCII -width 50 
 
$site=New-Object Microsoft.SharePoint.SPSite("$SiteUrl") 
$webs=$site.AllWebs  
 
    :Beginning_Loop foreach($web in $webs)
    {
        if($useCsvFile -eq $true)
        {
            $csvSites=Import-Csv $csvFile 
 
                foreach($csvSite in $csvSites)
                { 
                    if($csvSite.sites -eq $web.title)
                    {
                        write-host Found Match 
                        $foundMatch=$true 
                        break 
                    }
                }
        }
        if(($foundMatch -eq $true) -or ($useCsvFile -eq $false)) 
        {
            foreach($list in $web.lists)
            {
                if($list.baseTemplate -eq "DocumentLibrary")
                { 
                    foreach($libraryExclusion in $libraryExclusions)
                    {
                        if($list.Title -eq $libraryExclusion)
                        {
                            break beginning_loop
                        }
                    }
                    foreach($item in $list.items)
                    { 
                        $file=$item.file
                        $counter=$file.versions.count
                        GetVersions 
                        
                            if($setVersionLimit -eq $true)
                            {
                                Set-VersionLImit
                            }
                    }
                }
            }
        }       
 
    $web.dispose() 
    }
$site.dispose() 
$totalSpaceMb=$totalSpaceKb / 1024 
$totalSpaceGb=$totalSpaceMb / 1024  
 
Write-Host Total Space recovered as Kb is $totalSpaceKb 
Write-Host Total Space recovered as Mb is $totalSpaceMb 
Write-Host TotalSpace recovered as Gb is $totalSpaceGb  
 
out-file -inputobject "</VersionReport>" -filepath $output -encoding ASCII -append -width 50 
(get-content $output) | foreach-object {$_ -replace "&","&amp;"} | set-content $output  
 
$totalSpaceMb=0
$totalSpaceGb=0
$totalSpaceKb=0
$totalSpacebytes=0