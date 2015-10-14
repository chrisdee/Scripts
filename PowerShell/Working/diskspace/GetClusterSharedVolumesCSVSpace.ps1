## PowerShell Script to Display Disk Information for Cluster Shared Volumes (CSV) ##

Import-Module FailoverClusters

$objs = @()

$csvs = Get-ClusterSharedVolume
foreach ( $csv in $csvs )
{
   $csvinfos = $csv | select -Property Name -ExpandProperty SharedVolumeInfo
   foreach ( $csvinfo in $csvinfos )
   {
      $obj = New-Object PSObject -Property @{
         Name        = $csv.Name
         Path        = $csvinfo.FriendlyVolumeName
         Size        = $csvinfo.Partition.Size
         FreeSpace   = $csvinfo.Partition.FreeSpace
         UsedSpace   = $csvinfo.Partition.UsedSpace
         PercentFree = $csvinfo.Partition.PercentFree
      }
      $objs += $obj
   }
}

$objs | ft -auto Name ,Path, @{ Label = "Size(GB)" ; Expression = { "{0:N2}" -f ($_.Size /1024/ 1024/1024 ) } },@{ Label = "FreeSpace(GB)" ; Expression = { "{0:N2}" -f ($_.FreeSpace/ 1024/1024 /1024) } } ,@{ Label = "UsedSpace(GB)" ; Expression = { "{0:N2}" -f ($_.UsedSpace/1024 /1024/ 1024) } }, @{ Label = "PercentFree" ; Expression = { "{0:N2}" -f ( $_.PercentFree) } } 
