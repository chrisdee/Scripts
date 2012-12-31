################################################################################################################################
#
# Name: PowerShell Script to check and fix SQL Server Index Fragmentation on a Database
#
# Overview: Uses SQL Server SMO to determine index fragmentation. Then Reorganizes or Rebuilds depending on '%' of fragmentation
#
# Usage: Set the '$sqlserver' and '$database' variables to suit your environment
#
# Source: http://www.youdidwhatwithtsql.com/managing-index-fragmentation-with-powershell
# 
# Version History:
# 1.0 06/06/2011 - Initial release
#
################################################################################################################################
# Load SMO
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null;
 
# Set sql server and database name here
$sqlserver = "localhost\sql2005"; #Change your SQL Server Instance here
$database = "AdventureWorks"; #Change your Database name here
 
$srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" $sqlserver;
$db = New-Object ("Microsoft.SqlServer.Management.SMO.Database");
$db = $srv.Databases[$database];
 
# Get table count
$table_count = $db.Tables.Count;
$i = 0;
 
# First script out the drops
foreach($table in $db.Tables)
{
    Write-Progress -Activity "Checking table $table" -PercentComplete (($i / $table_count) * 100) -Status "Processing indexes" -Id 1;
    $i++;
    foreach($index in $table.Indexes)
    {
        $index_name = $index.Name;
        Write-Progress -Activity "Checking table $table" -PercentComplete (($i / $table_count) * 100) -Status "Processing index $index_name" -Id 1;
        # Get the fragmentation stats
        $frag_stats = $index.EnumFragmentation();
 
        # Get the properties we need to work with the index
        $frag_stats | ForEach-Object {
                        $Index_Name = $_.Index_Name;
                        $Index_Type = $_.Index_Type;
                        $Average_Fragmentation = $_.AverageFragmentation;
                                    };
        Write-Host -ForegroundColor Green "$Index_Type $Index_Name has a fragmentation percentage of $Average_Fragmentation";
 
        # Here we decide what to do based on the level on fragmentation
        if ($Average_Fragmentation -gt 40.00) #Percentage Average Fragmentation to prompt an Index Rebuild
        {
            Write-Host -ForegroundColor Red "$Index_Name is more than 40% fragmented and will be rebuilt.";
            $index.Rebuild();
            Write-Host -ForegroundColor Green "$Index_Name has been rebuilt.";
        }
        elseif($Average_Fragmentation -ge 10.00 -and $Average_Fragmentation -le 40.00) #Percentage Average Fragmentation to prompt an Index Reorganize
        {
            Write-Host -ForegroundColor Red "$Index_Name is between 10-40% fragmented and will be reorganized.";
            $index.Reorganize();
            Write-Host -ForegroundColor Green "$Index_Name has been reorganized.";
        }
        else
        {
            Write-Host -ForegroundColor White "$Index_Name is healthy, with $Average_Fragmentation% fragmentation, and will be left alone.";
        }
 
    }
}
Write-Progress -Activity "Finished processing `"$database`" indexes." -PercentComplete 100 -Status "Done" -Id 1;
Start-Sleep -Seconds 2;