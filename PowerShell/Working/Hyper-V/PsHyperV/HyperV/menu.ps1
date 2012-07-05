

Function Show-HypervMenu
{<#
    .SYNOPSIS
        Displays a menu to manage hyperv    
    .PARAMETER Server
        The Server to manage (by default, the local Computer)
#>

 Param ( $server="." )
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)}    
    $Host.UI.RawUI.WindowTitle = "Hyper-V Management" 
        Do {
      Clear-host
           $VSMSSD           = Get-WmiObject -ComputerName $Server -NameSpace $HyperVNamespace -Class "MsVM_VirtualSystemManagementServiceSettingData"
           [object[]]$VM     = Get-vm -server $Server | sort ElementName 
           [object[]]$switch = get-vmSwitch -server $server
           $FreeNic      = Get-WmiObject -ComputerName $Server -Namespace $HyperVNamespace -query "Select * from Msvm_ExternalEthernetPort where isbound=false"  
           
           if ($host.name -notmatch "\sISE\s")  {
              $heading = "Configuring $($VSMSSD.__server)"
              $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + (("-" * ($host.ui.RawUI.WindowSize.width-1))) + "`n"
                write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading 
           }                             
           Else {Write-host ("-------------------------------------------------------------------------------"+
                           "`n                       Configuring $($VSMSSD.__server)"  +
                           "`n-------------------------------------------------------------------------------")
           }
           Write-host     ("[ 1] Select a different Server" +
                         "`n[ 2] Manage Server settings" +
                        ("`n                     MAC address  range [ {0,24} - {0,-23} ]" -f $VSMSSD.MinimumMacAddress,$VSMSSD.MaximumMacAddress) +
                        ("`n                     Default  VM folder [ {0,-50} ]  " -f $VSMSSD.DefaultExternalDataRoot)    +              
                        ("`n                     Default VHD folder [ {0,-50} ]  " -f $VSMSSD.DefaultVirtualHardDiskPath) +
                         "`n[ 3] Manage Network settings ")
           $switch  | Foreach-object{
               write-host ("                        Virtual Network [ {0,-50} ]" -f $_.elementname)
           }
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           write-host      "[ 4] Cluster Networks for Live Migration "
           get-VMLiveMigrationNetwork | ForEach-Object{
           write-host (                                "     {0,-35}[ {1,-50} ]" -f $_.name,$_.address)}}
           Write-host (  "`n[ 5] Manage Virtual Disk files" )
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           if ((Get-Cluster $server).enableSharedvolumes -ne "enabled") {write-host "     Cluster shared Volumes are disabled"} else {
           write-host "     Cluster Shared Volumes"
           foreach ($vol in (Get-ClusterSharedVolume)) {foreach ($sharedVol in $vol.sharedvolumeinfo) { 
               write-host ("     {1,-35}[ {0,-34} {2,15}]" -f $vol.name,$sharedvol.FriendlyVolumeName, ($sharedVol.partition.freespace / 1gb).tostring("#,###.## GB Free")) }}  
           }}
           
           Write-host (  "`n[ 6] Create Virtual Machine" + 
                         "`n[ 7] Import Virtual Machine" )
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           Write-host      "[ 8] Live migrate Virtual Machines" }
           write-host    "`n     Manage Virtual Machines ..."
           $global:count=10 ;  $vm | select-object -first 10 |  ForEach-Object {
               write-host ("[{0,2}] {1,-34} [ {2,-10} ]" -f ($Global:count ++) , $_.elementName, [vmState]$_.enabledState )  }
           if ($vm.Count -gt 10) {
              Write-host "`n[20] More Virtual Machines ..." 
           } 
           Write-host    "`n[99] Exit this menu"
           $selection= [int](read-host -Prompt "`nPlease enter a selection") 
           switch ($selection) {
                1  {    $newServer = Read-Host "Enter the name of the server you want to connect to"
                        if ($newServer) {
                            $temp = Get-WmiObject -ComputerName $NewServer -NameSpace $HyperVNamespace -Class "MsVM_VirtualSystemManagementServiceSettingData"
                            if ($?) {$Server=$newServer}  else {$null = Read-host "Can not Contact that server. Press [Enter] to continue"}
                        }
                   }
                2  {    $ExtdataPath = Read-host "Please enter the path to the new VM data folder, or press [enter] to leave unchanged"
                        if (-not $ExtdataPath) {$ExtdataPath = $VSMSSD.DefaultExternalDataRoot }
                        $VHDPath = Read-host "Please enter the path to the new VHD folder, or press [enter] to leave unchanged"
                        if (-not $VHDPath) {$VHDPath = $VSMSSD.DefaultVirtualHardDiskPath }
                        $minMac = Read-host "Please enter the lowest MAC address to assign, as 12 hex digits, or press [enter] to leave unchanged"
                        if (-not $minMac) {$minMac = $VSMSSD.MinimumMacAddress }
                        $maxMac = Read-host "Please enter the highest MAC address to assign, as 12 hex digits, or press [enter] to leave unchanged"
                        if (-not $maxMac) {$maxMac = $VSMSSD.MaximumMacAddress }
                        if (($ExtdataPath -ne $VSMSSD.DefaultExternalDataRoot) -or ($VHDPath -ne $VSMSSD.DefaultVirtualHardDiskPath) -or
                            ($minMac -ne $VSMSSD.MinimumMacAddress) -or ($maxMac -ne $VSMSSD.MaximumMacAddress )) { 
                               set-vmhost -Confirm -Server $server -ExtDataPath $ExtdataPath -vhdPath $VHDPath -MINMac $minMac -MaxMac $maxMac | Out-Null
                        }
                        read-host "Press enter to continue"
                        $VSMSSD.get()
                   } 
                3  {   if ($switch  ) { 
                           $Switchinfo =  foreach ($s in (get-vmSwitch -server $server)) {
                               $Swinfo = new-object psobject -Property @{"SwitchName"=$s.ElementName}
                               $ac = Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$s} where resultClass=Msvm_SwitchPort" | 
                                   Foreach-object {Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$_} where AssocClass=Msvm_ActiveConnection"} 
                               if ($ac) { add-member -InputObject $swinfo -MemberType NoteProperty -Name "ExternalNetworkName" -Value ($ac | 
                                              Foreach-Object {Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$_} where resultClass=Msvm_ExternalEthernetPort"}  ).elementName
                                          add-member -InputObject $swinfo -MemberType NoteProperty -Name "InternalNetworkName" -Value ($ac | 
                                              Foreach-Object {Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$_} where resultClass=Msvm_InternalEthernetPort"} ).elementName
                                }
                                if     (($swInfo.InternalNetworkName) -and   ($swInfo.ExternalNetworkName))   {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "External"}
                                elseif (                                     ($swInfo.ExternalNetworkName))   {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "External - no parent access"}
                                elseif (($swInfo.InternalNetworkName)                                     )   {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "Internal"}
                                else                                                                          {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "Private"}
                                $swinfo
                            }    
                            Format-Table -AutoSize -InputObject $switchInfo -property SwitchName, NetworkType,ExternalNetworkName | out-host
                            $SwitchChoice = Select-Item -TextChoice "&Cancel", "&Add a new Virtual Network","&Remove a Virtual Network" -default 0 -Caption "Virtual Network configuration" 
                       }
                       else {$switchChoice = 1}
                       if ($switchChoice -eq 1) {
                           if ($freeNic) {$SwitchType = Select-Item -TextChoice "&Cancel", "&Private", "&Internal" , "&External" -default 0 -Caption "Virtual Network Creatation" -Message "Which kind of Virtual network would you like to create"}
                           else          {$SwitchType = Select-Item -TextChoice "&Cancel", "&Private", "&Internal"               -default 0 -Caption "Virtual Network Creatation" -Message "Which kind of Virtual network would you like to create"}
                           if ($switchType)             {$switchName   = Read-host "Please enter a name for the new Virtual Network"}
                           if (($switchType -eq 3) -and ($switchName)) {$nic = Select-List -InputObject $freenic -Property name
                                                                        New-VMExternalSwitch -virtualSwitchName $switchName -server $server -ExternalEthernet $nic}
                           if (($switchType -eq 2) -and ($switchName)) {New-VMInternalSwitch -virtualSwitchName $switchName -server $server }
                           if (($switchType -eq 1) -and ($switchName)) {New-VMPrivateSwitch  -virtualSwitchName $switchName -server $server }
                       }                              
                       if ($switchChoice -eq 2) {
                           $switchOff = ($Switchinfo | Select-List -Property SwitchName).switchName
                           If ($switchOff) {Remove-VMSwitch -virtualSwitch $switchoff -server $server -confirm}
                       }                                           
                   }
                4  {   Select-VMLiveMigrationNetwork -confirm }
                5  {   show-vhdMenu $server}
                6  {   $VMName = Read-host "Please enter the Display name for the new VM. To cancel, press [Enter] with no name."
                       if ($VMName) {$Path = Read-host "Enter the folder to hold the VMs configuration, or press [Enter] to use $($VSMSSD.DefaultExternalDataRoot) "
                                     if ($path) {$VM = New-VM -Name $vmname -Server $server -path $path -Confirm } else {$VM = New-VM -Name $vmname -Server $server -path $path -Confirm }
                                      
                                     if ($VM) {Show-VMMenu $vm}}
                   }
                7  {   $Path = Read-host "Please enter the Path to the folder holding the exported files you want to import."
                       if ($Path) {$ReUse=[boolean](Select-Item -Caption "Importing VM" -Message "Do you wish to re-use IDs" -TextChoices "No", "Yes")
                                   Import-VM -path $path -Server $server -Wait -ReuseIDs:$Reuse -Confirm | Out-Null
                       }   
                   }
                8  {   $HA_VMs =  Get-cluster -name $server |  Get-ClusterGroup |
                             where-object { (Get-ClusterResource -input $_ | where {$_.resourcetype -like "Virtual Machine*"})}
                       $HA_VMs |  format-table -autosize -property Name,State,OwnerNode
                       $RunningNodes = Get-Clusternode -cluster $server | where {$_.state -eq "Up"}
                       if ($RunningNodes.count -lt 2) {write-warning "Migration needs two cluster nodes to be running"} else {
                          $HA_VMs =  $HA_VMS | where-object { $_.state -eq "Online"}
                          If (-not $HA_VMs) {Write-warning "No High Availabilty VMs are on-line on the cluster"}
                          else { 
                                 $sources =  $HA_VMs | group ownernode
                                 if ($sources -is [array]) {  Write-host "FROM which node do you want to migrate" }
	                         $SourceNode =  ($sources | Select-List -property name,@{Name="Running VMs"; expression={$_.count}})
                                 if ($sourceNode) {
                                     Write-host "Moving From: $($sourceNode.Name)"
 	                             if ($RunningNodes.count -gt 2) {  Write-host "TO which node do you want to migrate" }
                                     $destinationNode = ($RunningNodes | where {$_.name -ne $sourceNode.name} | Select-List -Property name).name 
                                     if ($destinationNode) {
                                         write-host "Moving To:   $destinationNode "
                                         $HA_VMs = ($HA_VMs | where {$_.ownerNode.name -eq $sourcenode.name} )
                                         if (($HA_vms.count -gt 1) -and (select-item -Caption "Do you want to migrate" -TextChoices "&All VMs","&Selected VMs"  -Message "")) {
                                             $HA_VMs | select-list -Property name -multi |Move-ClusterVirtualMachineRole -Node $destinationNode | out-Default} 
                                         else {$HA_VMs | Move-ClusterVirtualMachineRole -Node $destinationNode | out-default }
                                         Get-cluster -name $server | Get-ClusterGroup | 
                                               where-object { (Get-ClusterResource -input $_ | where {$_.resourcetype -like "Virtual Machine*"})} |  format-table -autosize -property Name,State,OwnerNode
                                     }
                                 } 
                          }
                       }
                       Read-host "Press [Enter] to continue." 
                   }

                                                    
                {($_ -ge 10) -and ($_ -le 19)} 
                   {   Show-VMMenu -VM $vm[($_ -10)] }
                20 {   Select-vm -Server $server | Show-VMMenu }
           }   
    } until ($Selection -gt 30) 
}  


Function Show-VHDMenu 
{<#
    .SYNOPSIS
        Displays a menu to manage hyperv Virtual hard disks    
    .PARAMETER Server
        The Server holding the VHDs (by default, the local Computer)
#> 
    param ($server=".") 
    
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)}    
    $folder = Get-VhdDefaultPath -server $server
    Do {
           Clear-host          
           $vhd = Get-vhd -Path $folder -server $server    
           if ($host.name -notmatch "\sISE\s")  {
                $heading = "Configuring Virtual Disks on $($VSMSSD.__server)"
                $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + (("-" * ($host.ui.RawUI.WindowSize.width-1))) + "`n"
                write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading 
           }                             
           Else {Write-host ("-------------------------------------------------------------------------------"+
                           "`n                  Configuring disks on server $server"  +
                           "`n-------------------------------------------------------------------------------")
           }
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           if ((Get-Cluster $server).enableSharedvolumes -ne "enabled") {write-host "     Cluster shared Volumes are disabled"} else {
           write-host "Cluster Shared Volumes"
           foreach ($vol in (Get-ClusterSharedVolume)) {foreach ($sharedVol in $vol.sharedvolumeinfo) { 
               write-host ("{1,-35} :{0,-34} {2,15}" -f $vol.name,$sharedvol.FriendlyVolumeName, ($sharedVol.partition.freespace / 1gb).tostring("#,###.## GB Free"))}}
           }}

           Write-host   ("`n[ 1] Change current folder (from $Folder )"      +
                         "`n[ 2] List current Virtual Floppy disk (VFD) files" +
                         "`n[ 3] Create a new Virtual Floppy disk (VFD) file" +
                         "`n[ 4] Create a new Virtual  Hard  disk (VHD) file" +
                       "`n`n     Inspect / Edit VHD files in $folder")
           
                         
           $global:count=10 ;  $vhd | select-object -first 10 |  ForEach-Object {
               write-host ("[{0,2}] {1} " -f ($Global:count ++) , ($_.Name -replace ($folder+"\").replace("\","\\"),""))  }
           if ($vhd.Count -gt 10) {
               Write-host ("     $folder contains too many VHD files to show `n" +
                           "[20] Select a VHD file from a full list `n" )
               Write-host  "[21] Enter the path to VHD file"
           } 
           Write-host    "`n[99] Exit this menu"
           $selection= [int](read-host -Prompt "`nPlease enter a selection") 
           switch ($selection) {
                1  {    $newFolder = Read-Host "Please enter the name of the folder you want to connect to "
                        if ($newFolder) {
                           $newFolder = $newFolder -replace '\\$',''
                            $d = get-wmiobject -ComputerName $server -query ("select * from Win32_Directory where name='{0}'" -f $NewFolder.replace('\','\\') )
                            if ($d) { $vhd = Get-WmiObject -Query "associators of {$d} where resultClass=cim_datafile"  | where-object {$_.extension -eq "VHD"} |sort-object -Property name 
                                      $folder = $NewFolder }
                            else    { $null = Read-host "The specified directory can not be found`nPress [Enter] to continue" }
                        }
                   }
                2  {     $d = get-wmiobject -ComputerName $server -query ("select * from Win32_Directory where name='{0}'" -f $Folder.replace('\','\\') )
                         if ($d) { $v = Get-WmiObject -Query "associators of {$d} where resultClass=cim_datafile"  | sort-object -Property name  | foreach-object {
                             if  ($_.extension -eq "VFD") {write-host ($_.Name -replace ($folder+"\").replace("\","\\"),"")}
                         }}
                         $null = Read-host "Press [Enter] to continue"
                   }      
                3  {    $vfdPath   = Read-Host "Please enter the name for the VFD file" 
                        if ($vfdpath )   {
                            if ($VfDPath -notmatch "\w+\\\w+")  {$vfdPath = ($folder + '\' +  $vfdPath) }
                         }
                         if ($vfdpath )   {   
                            if ($vfdPath -notmatch ".VFD$") {$vfdPath += ".VFD"}
                            New-VFD -vfdPath $VfdPath -server $server -wait | out-null
                            $null = Read-host "Press [Enter] to continue"
                        }     
                   }
                4  {    $vhdType= Select-Item -TextChoices "&Cancel","Dynamically &Expanding", "&Fixed Size", "&Differencing" -Caption "Which type of VHD would you like to create ?" 
                        If ($VhdType) {
                            $VHDPath       = Read-Host "Please enter the name for the VHD file" 
                            if ($VHDPath -notmatch "\w+\\\w+") {$VHDPath = ($folder + '\' +  $VHDPath)  }
                            if ($vhdPath)  {
                                if ($vhdPath -notmatch ".VHD$") {$vhdPath += ".VHD"}
                                switch ($vhdType) {
                                     {@(1,2) -contains $_}  
                                        { $Fixed = ($_ -eq 2) 
                                          $size = [single](Read-host "Please enter the size of the new VHD in GB") * 1GB
                                          if ($size) { New-VHD  -server $server -VHDPath $VHDPath -Fixed:$fixed -Size $size -wait | out-null 
                                          } 
                                        }
                                     3  { $ParentPath = Read-Host "Please enter the name for the Parent VHD file" 
                                          if ($ParentPath)  {
                                              if ($ParentPath -notmatch ".VHD$")    {$ParentPath += ".VHD"}
                                              if ($ParentPath -notmatch "\w+\\\w+") {$ParentPath = ($folder + '\' +  $ParentPath) }
                                               if (Get-WmiObject -query ("Select * from cim_datafile where name='{0}' " -f $parentPath.replace("\","\\") )) {
                                                    New-VHD  -VHDPath $VHDPath -parentVHD $parentPath -server $server -wait | out-null
                                               }
                                               else {$null = Read-host "The specified parent VHD file can not be found.`nPress [Enter] to continue" }
                                           }
                                        } #2
                                }  #switch                            
                            } #vhdpath
                        }#vhd typ
                   }  #4
             {10..19 -contains $_}
                   {  $SelectedVHD = ($vhd[$_ -10]).name }
              20   {  $SelectedVHD = (Select-List -InputObject $vhd -Property ,@{Name="Name"; expression={$_.Name -replace ($folder+"\").replace("\","\\"),""}}).name     }
              21   {  
                      $SelectedVHD = Read-Host "Please enter the name of the VHD file" 
                      if ($SelectedVHD)  {
                          if ($SelectedVHD -notmatch ".VHD$")    {$SelectedVHD += ".VHD"}
                          if ($SelectedVHD -notmatch "\w+\\\w+") {$SelectedVHD = ($folder + '\' +  $SelectedVHD) }
                           if (-not (Get-WmiObject -query ("Select * from cim_datafile where name='{0}' " -f $SelectedVHD.replace("\","\\") ))) {
                               $SelectedVHD = $null
                               $null = Read-host "The specified VHD file can not be found.`nPress [Enter] to continue"
                           }
                       }              
                   } 
            {(10..21 -contains $_) -and $SelectedVHD} 
                   {  $VHDTestResult = Test-vhd -Server $server -VHDPath $SelectedVHD
                      $VHDInfo       = Get-VHDInfo -server $server -VHDPath $SelectedVHD  
                      $VHDInfo | out-host
                      if     ([vhdtype]$vhdinfo.type -eq [vhdtype]::dynamic)  {
                            $VHDSelect = select-item -TextChoices "&Return to previous menu", "Convert VHD &Type", "&ExpandVHD", "&Compact VHD" -Caption "VHD maintenance" -Message "Would you like to: "  
                      }
                      elseif ([vhdtype]$vhdinfo.type -eq [vhdtype]::fixed)  {
                            $VHDSelect = select-item -TextChoices "&Return to previous menu",  "Convert VHD &Type", "&ExpandVHD"  -Caption "VHD maintenance" -Message "Would you like to: "
                      }
                      elseif ([vhdtype]$vhdinfo.type -eq [vhdtype]::differencing -and $vhdTestResult)  {
                             $VHDSelect = select-item -TextChoices "&Return to previous menu",  "Convert VHD &Type"  -Caption "VHD maintenance" -Message "Would you like to: "
                      }
                      elseif ($vhdinfo.type -eq [vhdtype]::differencing )  {
                             $VHDSelect = 4 * (select-item -TextChoices "&No",  "&Yes" -default 1 -Caption "VHD maintenance" -Message "Would you like to reconnect the parent disk ?"  )
                      }
                      switch ($vhdSelect) {
                            1 { $vhdType = $null
                                if ([vhdtype]$vhdinfo.type -eq "differencing")  { $vhdType= if (Select-Item -TextChoices "Dynamically &Expanding", "&Fixed Size" -Caption "Which type of VHD would you like to Convert to ?") {[vhdtype]::fixed} else {[vhdtype]::Dynamic}  }
                                if ([vhdtype]$vhdinfo.type -eq "dynamic"     )  { $vhdType= [vhdtype]::fixed   }
                                if ([vhdtype]$vhdinfo.type -eq "fixed"       )  { $vhdType= [vhdtype]::dynamic }   
                                If ($VhdType) {
                                    $DestPath       = Read-Host "Please enter the name for the VHD file" 
                                    if ($DestPath)  {
                                        if ($DestPath -notmatch "\w+\\\w+") {$DestPath = ($folder + '\' +  $DestPath) }
                                        if ($DestPath -notmatch ".VHD$")    {$DestPath += ".VHD"}
                                        Convert-VHD -Server $server -VHDPath $selectedVHD -DestPath $DestPath -Type $vhdType  
                                   }
                                }
                              }
                            2 { $size = [single](Read-host "Please enter the size of the new VHD in GB") * 1GB
                                if ($size -gt $VHDinfo.MaxInternalSize) { Expand-VHD  -Server $server -VHDPath $selectedVHD -size $size -Wait | out-null    }
                                else                                    { Write-host "Current size is $($VHDinfo.MaxInternalSize /1GB)GB. You must enter a larger size."}
                              }
                            3 { compact-VHD -Server $server -VHDPath $selectedVHD  }                              
                            4 { $ParentPath = Read-Host "Please enter the name for the Parent VHD file" 
                                if ($ParentPath)  {
                                    if ($ParentPath -notmatch ".VHD$")     {$ParentPath += ".VHD"}
                                    if ($ParentPath -notmatch "\w+\\\w+")  {$ParentPath = ($folder + '\' +  $ParentPath) }
                                    if (Get-WmiObject -query ("Select * from cim_datafile where name='{0}' " -f $parentPath.replace("\","\\") )) {
                                         Connect-VHDParent -Server $server -VHDPath $selectedVHD -ParentPath $parentPath -Wait 
                                         
                                    }
                                }    
                                else {Write-host "The specified parent VHD file can not be found." }
                              }  
                            
                      }        
                      if ($vhdSelect) {$null = Read-host "Press [Enter] to continue" }
                   }                    
            }  #switch
    }   until ($Selection -gt 30) 
}

Function Show-VMDiskMenu 
{<#
    .SYNOPSIS
        Displays a menu to manage an individual VM's disks
   .PARAMETER VM
        The virtual Machine to manage
   .PARAMETER VMSCSI
        The SCSI controllers on the VM
   .PARAMETER VMDisk
        The disks controllers on the VM     
#>
param ($vm , $vmScsi , $vmdisk)                    
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)}    
    do { 
        $ChangeScsiHD=([boolean][int](Get-WmiObject -computerName $vm.__server -class "win32_operatingsystem").version.split(".")[1] ) -and  ($vmScsi.count -ge 1) 
        $dvdDrivePresent = [boolean]($vmdisk  | where {$_.driveName -like "DVD*"}) 
        if ($vm.EnabledState -eq [vmstate]::Stopped) {
            if ( ($vmdisk | where { $_.controllername -like "ide*" } | measure-object).count -lt 4)  {$AddIDEDrive = $true}
            if (  [boolean]($vmdisk | where {$_.controllername -like "ide*"}))                       {$ChangeIDEDrive = $true}
            if (  $vmScsi.count -ge 1 ) { $ChangeScsiHD = $true }
        }   
        if ($host.name -notmatch "\sISE\s") {
                               $heading = "Configuring Disk for VM : $($VM.ElementName) on server $($VM.__Server)"
                               $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + 
                                         ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + 
                                         (("-" * ($host.ui.RawUI.WindowSize.width-1))
                                        ) + "`n"
                               Clear-host
                               write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading
        }
        else                  {Write-host   "     -------------------------------------------------------------------------------"
                               write-host   "           Configuring Disk for VM : $($VM.ElementName) on server $($VM.__Server)"
                               write-host   "     -------------------------------------------------------------------------------`n"
        }
        $vmdisk | format-table -AutoSize -Property  ControllerName, DriveLun, driveName, diskimage  
        If  ($ChangeScsiHD)    {Write-host  "[ 1] Add Hard drive to a SCSI Contoller  "}         else {write-host   "[--] -----"}
        If  ($ChangeScsiHD -and ($vmdisk | 
              where {$_.controllername -like "*SCSI*"})) {
                               Write-host   "[ 2] Change disk image attached to SCSI hard drive"
                               Write-host   "[ 3] Remove SCSI Drive" }                           else {write-host   "[--] -----`n[--] -----"
        }
        if  ($AddIDEDrive)     {Write-host "`n[ 4] Add a Hard drive to an IDE Controller "}      else {write-host "`n[--] -----"}
        if  ($ChangeIDEDrive ) {Write-host   "[ 5] Change disk image attached to IDE hard drive"
                                Write-host   "[ 6] Remove IDE Hard drive or IDE DVD drive"}      else {write-host   "[--] -----`n[--] -----"}
        if  ($AddIDEDrive)     {Write-host "`n[ 7] Add IDE DVD drive"}                           else {write-host   "[--] -----"}
        if  ($dvdDrivePresent) {Write-host   "[ 8] Change disk (image) attached to DVD drive"}   else {write-host   "[--] -----"}
                                Write-host   "[10] Manage VHD files"  
                                Write-host "`n[99] Return to previous menu`n"
        $selection =       [int](read-host   "     Please select an option "  )
        switch ($selection) {
            1  { $controller = $vmscsi | select-list -Property @{Name="Controller"; expression={$_.ElementName}},
                                                               @{Name="Drive(s) Attached";expression={(Get-VMDriveByController $_ | measure-Object).count}}
                 if ($controller) { 
                    Get-VMDriveByController $controller | foreach -begin {$addresses = @() } -process {$addresses += $_.address }
                    do { $lun= Read-host "Please enter the LUN for the new disk" 
                         if ($addresses -Contains $lun) {write-host "That lun is already in use"}
                       }  until ($addresses -notContains $Lun)
                    $respool = get-wmiobject -Namespace root\virtualization -query "Select * from Msvm_ResourcePool where ResourceSubType = 'Microsoft Physical Disk Drive'"
                    $hostPassThroughDisks= (get-wmiobject -Namespace root\virtualization -query "associators of {$respool} where resultClass=Msvm_DiskDrive" )
                    if ($lun -and $hostPassThroughDisks ) {
                          $passThrough = Select-Item -TextChoices @("&VHD File","&Physical Disk") -Caption "Connecting Hard drive" -Message "Do wish to connect the new disk to"
                    }
                    if ($passThrough) {Add-VMPassThrough -LUN $lun -ControllerRASD $controller -PhysicalDisk (Select-List -InputObject $hostPassThroughDisks -Property @("elementName") )}
                    Elseif ($lun)     { 
                        $drive  =  Add-VMDrive -Confirm  -ControllerRASD $controller -LUN ($lun.replace("Lun ",""))
                        if ($drive)  {$Path = Read-host "Please enter a path to the image to mount in the new drive"
                                      If ($path) {Add-VMDisk -DriveRASD $drive -Path $path | out-null } 
                        }
                    } 
                 }    
               } 
            3  { $DriveID =  ($vmDisk | where {$_.controllerName -like "*SCSI*"} | 
                                  Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\") 
                 if ($DriveID) {$wql= "select * from MSVM_ResourceAllocationSettingData where instanceId='$DriveID' " 
                                Remove-VMRasd -VM $vm -rasd (Get-WmiObject -ComputerName $vm.__SERVER -Namespace $HyperVNamespace -Query $WQL) -Confirm
                 }
               }    
            6  { $DriveID =  ($vmDisk | where {$_.controllerName -like "*IDE*"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\") 
                 if ($DriveID) {$wql= "select * from MSVM_ResourceAllocationSettingData where instanceId='$DriveID' " 
                                Remove-VMRasd -VM $vm -rasd (Get-WmiObject -ComputerName $vm.__SERVER -Namespace $HyperVNamespace -Query $WQL) -Confirm
                 }
               }
            {@(2,5,8) -contains $_}
               { if ($_ -eq 2) {$DriveID =  ($vmDisk | where {$_.controllerName -like "*SCSI*"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\") 
                 }
                 if ($_ -eq 5) {$DriveID =  ($vmDisk | where {$_.controllerName -like "*IDE*" -and $_.DriveName -eq "Hard Drive"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\")
                 }
                 if ($_ -eq 8) {$DriveID =  ($vmDisk | where  {$_.DriveName -eq "DVD Drive"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\")              
                 }
                 if ($DriveID) {$Path = Read-host "Please enter a path to the new image to mount in the drive"
                                $wql= "select * from MSVM_ResourceAllocationSettingData where instanceId='$DriveID' " 
                                $drive=(Get-WmiObject -ComputerName $vm.__SERVER -Namespace $HyperVNamespace -Query $WQL)     
                                if ($path)  {if (Get-VMDiskByDrive -Drive $drive) {Set-VMDisk -DriveRASD $drive -Path $path -Confirm | out-null }
                                             else                                 {add-vmDisk -DriveRASD $drive -Path $path -OpticalDrive:$($_ -eq 8) -Confirm | out-null }
                                }
                                elseif ($_ -eq 8 -and (Get-VMDiskByDrive -Drive $drive)) { write-host "Removing Optical disk from the drive."
                                                                                           Remove-VMdrive -DriveRASD $drive -Diskonly 
                                }
                 }
               }
            {@(4,7) -contains $_ } 
               { $optical = [boolean]($_ -eq 7)
                 if (-not $optical) {Write-host -ForegroundColor red "If you need to create a VHD file, go back to the previous menu to do so"}    
                 $controller = (Get-VMDiskController -ide -vm $vm | 
                     where-object {(Get-VMDriveByController $_ | measure-Object).count -lt 2} | 
                         Select-List -Property @{Name="Controller"; expression={$_.ElementName}}  )
                 if ($controller) {
                     Get-VMDriveByController $controller |  foreach -begin {$addresses = @() }  -process {$addresses += $_.address } 
                     $lun = ($(foreach ($l in (0..1 | where {$addresses -notContains $_} )) {
                                    Add-Member -InputObject ( New-Object -TypeName System.Object ) -PassThru -name lun -MemberType noteproperty -Value $l |  
                                        Add-Member -PassThru -name lunName -MemberType noteproperty -Value "Lun $l" }) |  select-list -property @("LunName")).lun
                     $path = $null 
                     $respool = get-wmiobject -Namespace root\virtualization -query "Select * from Msvm_ResourcePool where ResourceSubType = 'Microsoft Physical Disk Drive'"
                     $hostPassThroughDisks= (get-wmiobject -Namespace root\virtualization -query "associators of {$respool} where resultClass=Msvm_DiskDrive" )
                     if (-not $optical -and $hostPassThroughDisks ) {
                          $passThrough = Select-Item -TextChoices @("&VHD File","&Physical Disk") -Caption "Connecting Hard drive" -Message "Do wish to connect the new disk to"
                     }
                     if ($passThrough) {Add-VMPassThrough -Confirm -LUN $lun -ControllerRASD $controller -PhysicalDisk (Select-List -InputObject $hostPassThroughDisks -Property @("elementName") ) | out-null}
                     Else   {
                         $drive =  Add-VMDrive -Confirm -OpticalDrive:$optical  -ControllerRASD $controller -LUN $lun
                         if ($drive) { 
                              $hostOpticalDrives = Get-WmiObject -ComputerName $vm.__SERVER -Query "Select * From win32_cdromdrive"
                              if ($optical -AND $hostOpticalDrives) {
                                 switch (Select-Item -TextChoices @("&ISO File","&Physical Disk", "Decide &Later") -Caption "Connecting DVD drive" -Message "Do wish to connect the new disk to") {
                                     1 {$path=(Select-List -InputObject $hostOpticalDrives -Property ID,mediatype,caption).deviceID}
                                     0 {$Path = Read-host "Please enter a path to the image to mount in the new drive"}
                                 }
                              }
                              Else {$Path = Read-host "Please enter a path to the image to mount in the new drive"}
                              If   ($path) {Add-VMDisk -DriveRASD $drive -Path $path -OpticalDrive:$optical -confirm| out-null }
                              elseif (-not $optical) {$null = Read-host "It is not supported to have a hard disk without an image or pass through disk."} 
                         }                      
                     }                                                 
                 }
               } 
           10  {Show-vhdMenu $vm.__Server}                                                                               
       }
       $null = Read-host "Press [enter] to continue"
       [Object[]]$vmDisk = Get-VMDisk $vm
   } until ($selection -ge 20)
   
}


Function Show-VMMenu
{<#
    .SYNOPSIS
        Displays a menu to manage and individual VM
   .PARAMETER VM
        The virtual Machine to manage
   .PARAMETER Server
        If a VM Name is passed, the name of the server where it is found. By default the local computer
#>
   Param(
      [parameter(Position=0 , mandatory=$true, ValueFromPipeline = $true)]
      $VM ,
      
      $Server="." 
     )
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    $Refreshneeded = $True
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)} 
    if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
    if ($vm.__CLASS -eq 'Msvm_ComputerSystem'){ do {    
          if ($RefreshNeeded) {
              Write-Progress -Activity "Configuring VM $($VM.ElementName) " -Status "Gathering Data" 
              $VMCG       = Get-vmClusterGroup $vm
              $vmsd       = Get-VMSettingData $vm  
              $VSGSD      = get-wmiobject  -computername $vm.__SERVER -namespace $HyperVNamespace  -Query "associators of {$vm} where resultclass=Msvm_VirtualSystemGlobalSettingData"
              $VMcpu      = Get-VMCPUCount $vm
              $vmMemory   = Get-VMMemory $vm  
              $VMFloppy   = Get-VMFloppyDisk $vm 
    [Object[]]$vmScsi     = Get-VMDiskController $vm -SCSI 
    [Object[]]$vmDisk     = Get-VMDisk $vm
              $vmComPort  = Get-VMSerialPort $vm 
              $vmNic      = Get-VMNic $vm
              $VmSnap     = Get-VMSnapshottree $vm
    [Object[]]$vmNic      = Get-VMNic $vm
              $vmICs      = Get-VMIntegrationComponent $vm
              $vmRFX      = Get-VMRemoteFXController $VM
              Write-Progress -Activity "Configuring VM $($VM.ElementName) " -Status "Gathering Data" -Completed
              $Refreshneeded = $false
          }                       
          if ($host.name -notmatch "\sISE\s") {
              $heading = "Configuring VM : $($VM.ElementName) on server $($VM.__Server)"
              $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + (("-" * ($host.ui.RawUI.WindowSize.width-1))) + "`n"
              Clear-host
              write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading
         }
         else                               { 
              Write-host  "     -------------------------------------------------------------------------------"
              write-host  "               Configuring VM : $($VM.ElementName) on server $($VM.__Server)"
              write-host  "     -------------------------------------------------------------------------------"
         }
          write-host     ("[ 1] Change VM State          :                  [ {0,-61} ]"             -f [vmState]$vm.enabledState)
          write-host     ("[ 2] Rename                   :                  [ {0,-61} ]"             -f $vmsd.elementName)                    
          ([bootmedia[]]$vmsd.BootOrder) | % -begin {$b=""} -process {$b += $_.tostring() +", "} `
    -end {write-host     ("[ 3] Boot order               :                  [ {0,-61} ]"             -f ($b -replace ", $",""))}
          write-host     ("[ 4] Notes                    :                  [ {0,-61} ]"             -f $vmsd.NOTES)
          write-host     ("[ 5] Recovery and             :                  [ On service fail:{0,-16}, On Host shutdown:{1,-10} ]"`
                                                                                                    -f [RecoveryAction]$vsgsd.AutomaticRecoveryAction ,
                                                                                                        [ShutdownAction]$vsgsd.AutomaticShutdownAction) 
          write-host     ("     Startup options                             [ On Host boot   :{0,-16}, Delay {1,4} seconds          ]" `
                                                                                                    -f [StartUpAction]$vsgsd.AutomaticStartupAction, 
                                                                                                       [System.Management.ManagementDateTimeconverter]::ToTimeSpan($VSGSD.AutomaticStartupActionDelay).Seconds )
          write-host     ("[ 6] Snapshots                :")                                         
          $VmSnap | foreach-object {
              write-host ("                              $_" )
          }            
          write-host     ("[ 7] Export VM                "  )                                                         
          write-host     ("[ 8] Delete VM  "  )                                                          
          write-host     ("[ 9] Integration Components   :                  [ {0}/{1} Enabled                                       ]" -f ($vmics | where {$_.enabledState -eq [VMState]::running} | Measure-Object ).count ,
                                                                                                      ($vmics | Measure-Object ).count)
          Write-Host     ("[10] CPU                      :   {0} Processor(s) [ Reserve:{1,7}/100000 - Limit:{2,7}/100000 - Weight:{3,-4}   ]" `
                                                                                                   -f $VMcpu.VirtualQuantity, $VMcpu.Reservation, $VMcpu.Limit, $VMcpu.Weight) 
          write-host     ("[11] Memory                   :        {0, 6} MB [ Buffer :{1,7}%       - Limit:    {2,7} MB - Weight:{3,-6} ]"           -f $VMMemory.virtualQuantity,$vmMemory.TargetMemoryBuffer, $VmMemory.limit , $vmMemory.weight )
          if ($vmscsi.count -lt 4)   {
              write-host ("[12] SCSI Controllers         :                  [ {0} Present                                                     ]"     -f ([int]$vmscsi.count) )  
              write-host ("[13] IDE and SCSI Disks       : ") 
          }
          else {
              write-host ("[13] IDE and SCSI Disks       :                 [ Max 4 SCSI Controllers present                                    ]" )     
          }        
          if ($vmdisk) { $vmDisk | foreach-object {
              write-host ("     {0,-25                  }: {1,15         }: [ {2,-61} ]"             -f ($_.controllerName +" LUN:"+ $_.DriveLUN) , $_.DriveName, $_.diskimage)}
          }
          write-host     ("[14] Floppy Disk              :           Image: [ {0,-61} ]"             -f $(if ($vmFloppy.Connection) {$VMFloppy.connection[0]} else {""}))
          $Global:count=15 ;                   
          $vmComPort | foreach-object {if ($_) {
              write-host ("[{2,2}] {0,-25               }:      Connection: [ {1,-61} ]"             -f $_.ElementName, $_.connection[0],($Global:count ++))
          }}
          if ($vmRFX) {      
          Write-Host     ("[18] Remote FX                :     {0} Monitor(s) [ {1,-61} ]"           -f $vmRFX.MaximumMonitors, ([RemoteFxResoultion]$vmRFX.MaximumScreenResolution) )}
          elseif ((Get-WmiObject -ComputerName $vm.__server -class win32_operatingsystem).version -gt "6.1.7600"){
          Write-Host     ("[18] Add Remote FX controller :")}
          if ((($vmNic | where {$_.type -eq "synthetic"} | measure-object).count -lt 8) -or (($vmnic | where {$_.type -eq "emulated"} | measure-object).count -lt 4) ){
              write-host ("[19] Add Network interface    : ")
          }
          $Global:count=20
          $vmnic     | foreach-object {if ($_) {
              write-host ("[{3,2}] {0,-25               }: MAC:{1         } [ {2} ] "            -f $_.ElementName,$_.address,(Get-VMnicSwitch $_).elementname ,($Global:count ++))
          }}
          if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
          write-host   ("`n[30] Cluster status           :                  [ {0,-61} ]"           -f  $VMCG.state)
          }
          write-host   ("`n[40] Refresh data")
          write-host   ("`n[99] Exit this menu`n")
          $selection = [int](read-host    "Enter a selection")
        
          if ($?) {switch ($selection) {
              1 {  switch ($vm.enabledState ) {
                       {$_ -eq [vmstate]::Suspended} {   
                           Switch (select-item -TextChoices @("&Delete Saved state", "&Start VM", "&Cancel") -Caption "$($vm.elementname) is Suspended" -Message "Do you want to:" -default 2) {
                               0 {stop-vm  -Confirm -VM $vm ; $null = read-host "Press [enter] to continue" ; $vm.get() }
                               1 {Start-Vm          -VM $vm ; $null = read-host "Press [enter] to continue" ; $vm.get() }
                           }        
                       }    
                       {$_ -eq [vmstate]::Stopped }  {
                           if ((select-item -TextChoices @("&Start VM", "&Cancel") -Caption "$($vm.elementname) is Stopped" -Message "Do you want to:" -default 1) -eq 0) {
                                Start-VM $vm 
                                $null = read-host "Press [enter] to continue"  
                                $vm.get()
                           }
                       }
                       {$_ -eq [vmstate]::Running }  {
                            switch (select-item -TextChoices @("&Save VM","&Turn off VM", "Shut &Down the OS", "&Cancel")  -Caption "$($vm.elementname) is running" -Message "Do you want to:" -default 3) {
                                0 {Save-VM                    -VM $vm ; $null = read-host "Press [enter] to continue"  ;$vm.get()  } 
                                1 {Stop-VM           -Confirm -VM $vm ; $null = read-host "Press [enter] to continue"  ;$vm.get()  }
                                2 {Invoke-VMShutdown -Confirm -vm $vm ; $null = read-host "Press [enter] to continue"  ;$vm.get()  }
                            }     
                       }
                   } 
                } 
              2 {  $name=read-host "Enter the new name for the VM [leave blank to remain as $($vm.elementName)]"  
                   if ($name -ne "") { 
                        Set-vm -confirm -VM $vm -name $Name 
                        $vm.get()
                        $vmsd.get()
                   }        
                }
              3 { $vm.get(); if ($vm.EnabledState -eq [vmstate]::Stopped)  {
                       Write-host "Select the devices which in the order you want to boot from them. `n Any you don't select will be added in the order Floppy,CD,IDE,NET"
                       $newbootOrder = ($vmsd.BootOrder | select-object @{name="Device"; Expression={[bootMedia]$_}} | select-list -multiple -property Device  | %{$_.device} )
                       if ($newbootOrder -is [array]) {"Floppy","CD","IDE","NET" | ForEach-Object -process {if ($newbootOrder -notcontains $_) {$newbootOrder = $newBootOrder + $_}} `
                                                                                                      -end {set-vm -confirm -VM $vm -bootOrder ([bootmedia[]]$newbootOrder)}}
                       else                           {write-host "You need to enter at least 2 devices." }                                               
                       $null = read-host "Press [enter] to continue" ; $vmsd.get()
                   }
                   else {$null = read-host "You can change the boot order only when the VM is stopped.`nPress [enter] to continue"}
                }
              4 {  $Notes=read-host "Enter the new notes for the VM [leave blank to keep notes unchanged}"  
                   if ($Notes -ne "") { Set-vm -confirm -VM $vm -notes $Notes  ; $vmsd.get() }        
                }
              5 {   Write-host "Please select the action to be taken if the virtual machine worker process terminates abnormally"
                    $autoRecovery = Select-EnumType -EType RecoveryAction -default $vsgsd.AutomaticRecoveryAction
                    Write-host "Please select the action to be taken if the host OS is shutdown with the VM running"
                    $autoShutdown = Select-EnumType -EType ShutdownAction -default $vsgsd.AutomaticShutdownAction
                    Write-host "Please select the action to be when the host OS is Starts with the VM running"
                    $autoStartup  = Select-EnumType -EType StartupAction -default $vsgsd.AutomaticStartupAction  
                    if ($autostartup -ne [startupAction]::none) {$autoDelay= Read-host "Please enter the time in seconds to delay the automatic start up"   } 
                    if (-not $autoDelay) {$autoDelay = [System.Management.ManagementDateTimeconverter]::ToTimeSpan($VSGSD.AutomaticStartupActionDelay).Seconds }
                    if (     ($autoRecovery -ne $vsgsd.AutomaticRecoveryAction) -or ($autoShutdown -ne $vsgsd.AutomaticShutdownAction     ) `
                         -or ($autoStartup  -ne $vsgsd.AutomaticStartupAction ) -or ($autoDelay    -ne $vsgsd.AutomaticStartupActionDelay )) {
                        Set-vm -Confirm -vm $vm -AutoRecovery $autoRecovery -AutoShutDown $autoShutdown -autoStartup $autoStartup -AutoDelay $autoDelay
                        $null = read-host "Press [enter] to continue" 
                        $vsgsd.get() 
                    }    
                 }
               6 { if ($vmSnap -ne "-") {$action = select-item -TextChoices @("Create a &New snapshot" ,"&Apply a SnapShot","&Delete a SnapShot" , "&Rename a SnapShot" , 
                                                  "&Update a snapshot" , "&Cancel") -Caption "What do you want to do:" -default 5 
                   }
                   else                 {$action = 0 ; Write-host "No existing Snapshots, creating new Snapshot" }
                   switch ($action) {
                       0   {$note = Read-Host "Enter a note to describe the snapshot [optional]" 
                            New-VMSnapshot -VM $vm -note $note -wait -Confirm
                           }
                       {1..4 -contains $_}
                           {$snap = Select-VMSnapshot $vm} 
                       1   {Restore-VMsnapshot -SnapShot $snap -wait -Confirm ;  $refreshNeeded = $true  } 
                       2   {$Tree = [boolean](select-item -TextChoices @("&No" ,"&Yes") -Caption "Deleting Snapshot(s)" -message "Do you want to delete children of the select snapshot, if any ?" )
                            Remove-VMSnapshot  -snapshot $Snap -Tree:$tree -wait -Confirm
                           }
                       3   {$name = Read-Host "Please enter the new name for the snapshot"
                            if ($name) {rename-vmsnapshot  -snapshot $snap -newName $name}
                           }
                       4   {Update-VMSnapshot -VM $vm -snapName $snap.elementName -Confirm}
                       {0..4 -contains $_}    
                           {$null = read-host "Press [enter] to continue" ; $VmSnap = Get-VMSnapshottree $vm}
                   }                           
                 }
               7 { if (($vm.EnabledState -eq [vmstate]::Stopped) -or ($vm.EnabledState -eq [vmstate]::suspended)) {
                        $path = Read-host "Please enter path to store the exported files"
                        if ($path) { 
                            $CopyState = [boolean](select-item -TextChoices @("&Configuration data only","&Machine State and Configuration data") -Caption "What do you want to export:" -default 1 )
                            Export-VM -VM $vm -path $path -copyState:$copyState  -confirm
                            $null = read-host "Press [enter] to continue" 
                        }
                        else {$null = read-host "You can add export only when the VM is saved or stopped.`nPress [enter] to continue"}  
                   }
                 }  
               8 { if ((remove-vm -Confirm -VM $vm) -eq [ReturnCode]::OK) {return $null} } 
               9 { Write-host "Switch integration components between 'Running' (enabled) status and 'Stopped' (disabled status)"
                   $vmics | select-list -multiple -Property elementName, @{name="State";expression={[vmstate]$_.enabledstate}}  | 
                       Foreach-Object -begin   {$c=@()} `
                                      -process {$c += $_.elementName} `
                                      -end     {if ($c) {$null=Set-VMIntegrationComponent -vm $vm -Confirm -componentName $C 
                                                         $vmics = Get-VMIntegrationComponent -vm $vm
                                      }}
                 }
              10 { $vm.get() 
                   if ($vm.EnabledState -eq [vmstate]::Stopped)  {
                       $cpucount = Read-host "Enter the new number of Virtual CPUs [Leave blank to remain as $($VMcpu.VirtualQuantity)]" 
                   }
                   else {Write-host "You can change the number of processors only when the VM is stopped."}
                   if (-not $cpucount) {$cpuCount = $VMcpu.VirtualQuantity}
                   if ($vm.EnabledState -ne [vmstate]::Suspended)  {
                       $limit  = Read-host "Enter the new CPU limit (0 - 100000) [Leave blank to remain as $($VMcpu.Limit)]"
                       if (-not $limit) {$limit = $VMcpu.limit} 
                       $Reservation  = Read-host "Enter the new CPU Reservation (0 - 100000) [Leave blank to remain as $($VMcpu.Reservation)]"
                       if (-not $Reservation) {$Reservation = $VMcpu.Reservation} 
                       $Weight  = Read-host "Enter the new CPU Weight (default=100) [Leave blank to remain as $($VMcpu.weight)]"
                       if (-not $Weight) {$Weight = $VMcpu.Weight ; write-debug "Weight"} 
                           if ( ($Weight -ne $VMcpu.Weight) -or ($Reservation -ne $VMcpu.Reservation) -or ($limit -ne $VMcpu.limit) -or ($cpuCount -ne $VMcpu.VirtualQuantity)) {
                                if ($vm.EnabledState -eq [vmstate]::Stopped)  {Set-VMCPUCount -Confirm -VM $vm -CPUCount $CpuCount -Limit $limit -Reservation $reservation -Weight $weight }
                                else                                          {Set-VMCPUCount -Confirm -VM $vm                     -Limit $limit -Reservation $reservation -Weight $weight }
                           $null = read-host "Press [enter] to continue"
                           $vmCpu.get()
                       }
                   }
                   else {$null=Read-host "CPU weightings can not be changed on a saved VM``nPress [Enter] to continue"}
                 }
              11 { $vm.get()
                   $DynamicMemoryEnabled = $vmmemory.DynamicMemoryEnabled
                   $MemoryLimit = 0 
                   if ((Get-WmiObject -ComputerName $vm.__server -class win32_operatingsystem).version -gt "6.1.7600"){
                      if ($vm.EnabledState -eq [vmstate]::Stopped) {
                          if ($vmmemory.DynamicMemoryEnabled) {
                              $DynamicMemoryEnabled = [boolean](select-item -TextChoices @("&Disabled","&Enabled") -Caption "Dynamic Memory is Enabled "-Message "Should it be:" -default 1 )
                          }
                          Else {
                              $DynamicMemoryEnabled = [boolean](select-item -TextChoices @("&Disabled","&Enabled") -Caption "Dynamic Memory is Disabled "-Message "Should it be:" -default 0 )    
                          } 
                          $Memory=[int](Read-host "Please enter the new amount of memory in MB - or nothing to leave it as $($VMMemory.virtualQuantity)")
                          if ($Memory -eq 0 )     {$memory      = $VMMemory.virtualQuantity}
                          if ($DynamicMemoryEnabled) {
                                $MemoryLimit=[int](Read-host "Please enter the new  memory Limit in MB - or nothing to leave it as $($VMMemory.Limit)")
                          }
                          if ($MemoryLimit -eq 0) {$MemoryLimit = $VMMemory.Limit }
                      }
                      else {write-host "You can change the memory size only when the VM is stopped."
                            if (-not $DynamicMemoryEnabled) {$null = read-host "Press [enter] to continue"}
                      }
                      if ($DynamicMemoryEnabled) {
                                $MemoryBuffer=[int](Read-host "Please memory buffer Percentage between 5 and 2000 - or nothing to leave as $($VMMemory.TargetMemoryBuffer)")
                                if ($memoryBuffer -eq 0) {$MemoryBuffer = $VMMemory.TargetMemoryBuffer}
                                $memoryWeight=[int](Read-host "Please memory weighting between 1 and 10000 - or nothing to leave as $($VMMemory.Weight)")
                                if ($memoryWeight -eq 0) {$memoryWeight = $VMMemory.Weight}
                                if ($vm.EnabledState -eq [vmstate]::Stopped) {Set-VMMemory -Confirm -VM $vm -Dynamic -Weight $memoryWeight -BufferPercentage $memoryBuffer -Memory $memory -limit $MemoryLimit  |
                                                                                out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get()}
                                else                                         {Set-VMMemory -Confirm -VM $vm -Dynamic  -Weight $memoryWeight -BufferPercentage $memoryBuffer |
                                                                                out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get()}       
                      } 
                      elseif ((($memory -ne  $VMMemory.virtualQuantity) -or ($vmmemory.DynamicMemoryEnabled -ne $DynamicMemoryEnabled)  ) -and ($vm.EnabledState -eq [vmstate]::Stopped) )
                                                                             {Set-VMMemory -Confirm -VM $vm -Memory $memory | out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get() }
                  }
                  else {     
                       if ($vm.EnabledState -eq [vmstate]::Stopped) {
                            $Memory=[int](Read-host "Please enter the new amount of memory in MB - or nothing to leave it as $($VMMemory.virtualQuantity)")
                                
                            if ($memory) {Set-VMMemory -Confirm -VM $vm -Memory $memory | out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get() }
                        }
                        else {$null = read-host "You can change the memory size only when the VM is stopped.`nPress [enter] to continue"}
                   }     
                 } 
              12 { $vm.get()
                   if ($vm.EnabledState -eq [vmstate]::Stopped) {
                      if      (-not $vmScsi.count)  {$selection = 0}
                      elseif  ($vmScsi.count -eq 4) {$Selection = 1}
                      else   { $selection = Select-item -TextChoices "&Add a SCSI Controller","&Remove a SCSI controller","&Cancel" -Caption "SCSI Controllers" -Message "Would you like to:" }   
                      if ($Selection -eq 0) {
                           $nameSuffix = Read-host "By default all SCSI Controllers use the same display name.`nEnter a suffix to identify this SCSI controller [optional]"
                           add-vmscsicontroller -vm $vm -name ($lstr_VMBusSCSILabel + $namesuffix) -confirm | out-Null
                           $null = read-host "Press [enter] to continue"
                      }
                      if ($selection -eq 1) {$rasd =($vmscsi | select-list -Property @{Name="Controller"; expression={$_.ElementName}},
                                                                                     @{Name="Drive(s) Attached";expression={(Get-VMDriveByController $_ | measure-Object).count}}) 
                                             if ($rasd) {Remove-VMRasd -confirm -VM $vm -rasd $rasd                                         
                                                         $null = read-host "Press [enter] to continue" 
                                             }
                      }
                   }                             
                   else  {$null = read-host "You can add hardware only when the VM is stopped.`nPress [enter] to continue"}  
                   [Object[]]$vmScsi = Get-VMDiskController $vm -SCSI 
                 }
              13 { Show-VMdiskMenu -vm $vm -vmDisk $vmDisk -vmscsi $vmScsi 
                   [Object[]]$vmDisk  = Get-VMDisk $vm
                 }
              14 { if ($vmFloppy.Connection) { Remove-VMFloppyDisk -Confirm $vm}
                    Else                     { $path = Read-host "Please enter path to the VFD file."
                                                if ($path) {Add-VMFloppyDisk -VM $vm -Path $path}
                    }
                    $null = read-host "Press [enter] to continue" ; 
                    $VMFloppy   = Get-VMFloppyDisk $vm          
                 }
{($_ -eq 15)`
-or ($_ -eq 16)} { $port = ($_ - 14) 
                   $path = Read-host "Please enter the path for the named pipe to use as connection for COM$Port or blank to disconnect."
                   $null = Set-VMSerialPort -Confirm -vm $vm -PortNumber $port -Connection $path 
                   $null = read-host "Press [enter] to continue" ; $vmComPort= Get-VMSerialPort -vm $vm
                 }
              18 {  if ($vm.EnabledState -eq [vmstate]::Stopped)  {
                        if ($vmRFX) {$RFXResolution = $vmrfx.MaximumScreenResolution 
                                     $RFXMonitors   = $vmrfx.MaximumMonitors
                                     $action = select-item -TextChoices @("&Remove Remote FX controller","&Configure Remote FX controller") -Caption "What do you want to do:" -default 1}
                        else        {$RFXResolution = 0
                                     $RFXMonitors   = 1
                                     $action = 1 }
                        if ($action -eq 0) {Remove-VMRemoteFXController -Confirm -VM $vm ; $null = read-host "Press [enter] to continue"
                                          $vmRFX = $null }
                        else             {Write-host "Select the new resolution (Default $([RemoteFxResoultion]$RFXResolution) )"
                                          $RFXResolution = Select-EnumType RemoteFxResoultion -default $RFXResolution
                                          $RFXM = [int](Read-host "Please enter the new Number of monitors - or nothing to leave it as $RFXMonitors")
                                          if ($RFXM -eq 0) {$RFXM = $RFXMonitors }
                                          
                                          $vmRFX = Set-VMRemoteFXController -Confirm -VM $vm -Monitors $RFXM -Resolution $RFXResolution 
                                          $null = read-host "Press [enter] to continue"}
                    }
                    
                    else  {$null = read-host "You can configure RemoteFX only when the VM is stopped.`nPress [enter] to continue"}         
                 }   
              19 { if ($vm.EnabledState -eq [vmstate]::Stopped) {
                       if ((($vmNic | where {$_.type -eq "synthetic"} | measure-object).count -lt 8) -and (($vmnic | where {$_.type -eq "emulated"} | measure-object).count -lt 4) )
                            {$legacy = [boolean]( select-item -TextChoices @("&Synthetic / VMbus NIC","&Emulated / Legacy NIC") -caption "Which type of Network Interface Card ?" -default 0 )}
                       else {$legacy =  (($vmnic | where {$_.type -eq "emulated"} | measure-object).count -lt 4)}
                       Write-host "Please select a new switch for the NIC" 
                       $switch = Select-VMSwitch -Server $Vm.__server 
                       $nic = Add-VMNIC -VM $vm -legacy:$legacy -Virtualswitch $Switch -Confirm
                       $vmnic = Get-VMNic $vm
                   }
                   else  {$null = read-host "You can add hardware only when the VM is stopped.`nPress [enter] to continue"}         
                 }
{($_ -ge 20)`
-and $_ -lt 30}  { $nic = $vmNic[($_ -20)]
                   if ($vm.EnabledState -eq [vmstate]::Stopped) { $action = select-item -TextChoices @("&Connect to a different network", "Change &MAC", "&Delete NIC") -Caption "What do you want to do:" -default 0 }
                   else                                         { $action = 0 ; Write-host "You can delete or change the MAC address of a NIC only when the VM is stopped"}
                   switch ($action) {
                        0 { Write-host "Please select a new switch for the NIC" 
                            $switch = Select-VMSwitch -Server $nic.__server 
                            Set-VMNICSwitch -nic $nic -Virtualswitch $switch -Confirm | out-null
                          }  
                        1 { Set-VMNICAddress -Nic $nic -mac (Read-host "Please enter the new MAC address") -Confirm  }
                        2 { Remove-VMNIC -Nic $nic -confirm}   
                    }
                    $vmnic = Get-VMNic $vm
                 }
             30  { if (-not $VMCG) {if (select-item -TextChoices @("&No" ,"&Yes") -Caption "Configuring Clustering" -message "Do you want to configure this virtual machine for High Availablity ?" ) {
                                        Add-ClusterVirtualMachineRole -Name $vm.ElementName -VirtualMachine $vm.ElementName -Cluster $vm.__SERVER | out-null
                                        $VMCG = Get-vmClusterGroup $vm
                   }}
                   Else {  $RunningNodes = Get-Clusternode -cluster $vm.__SERVER | Where-Object {$_.state -eq "Up" -and $_.name -ne $VMCG.OwnerNode}
                           if ($RunningNodes -and $VMCG.state -eq "Online") {if (select-item -TextChoices @("&No" ,"&Yes") -Caption "Configuring Clustering" -message "Do you want to Live migrate virtual machine to another node ?" ) {
                                                                             $destination = (Select-list $runningNodes -property Name)
                                                                             move-vm -VM $vm -Destination $destination | out-null ; Start-Sleep -Seconds 5 ; return}}
                           if ($RunningNodes -and $VMCG.state -eq "Offline") {if (select-item -TextChoices @("&No" ,"&Yes") -Caption "Configuring Clustering" -message "Do you want move this virtual machine to another node ?" ) {
                                                                             $destination = (Select-list $runningNodes -property Name)
                                                                             Move-ClusterGroup -Cluster $vm.__SERVER -name $vmcg -node $destination | out-null ; Start-Sleep -Seconds 5 ; return} }                                                 
                           if (-not $runningNodes) {Read-host "There are no nodes available to take this VM.`nPress [Enter] to Continue"} 
                           }
                                                          
                 } 
             40  {$vm.get()
                  $refreshneeded = $true
                  if ($VMCG) {Sync-vmClusterConfig -vm $vm -force | out-null}
                 }
          }} 
    } while ($selection -le 50) }           
}


Function Show-HypervMenu
{<#
    .SYNOPSIS
        Displays a menu to manage hyperv    
    .PARAMETER Server
        The Server to manage (by default, the local Computer)
#>

 Param ( $server="." )
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)}    
    $Host.UI.RawUI.WindowTitle = "Hyper-V Management" 
        Do {
      Clear-host
           $VSMSSD           = Get-WmiObject -ComputerName $Server -NameSpace $HyperVNamespace -Class "MsVM_VirtualSystemManagementServiceSettingData"
           [object[]]$VM     = Get-vm -server $Server | sort ElementName 
           [object[]]$switch = get-vmSwitch -server $server
           $FreeNic      = Get-WmiObject -ComputerName $Server -Namespace $HyperVNamespace -query "Select * from Msvm_ExternalEthernetPort where isbound=false"  
           
           if ($host.name -notmatch "\sISE\s")  {
              $heading = "Configuring $($VSMSSD.__server)"
              $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + (("-" * ($host.ui.RawUI.WindowSize.width-1))) + "`n"
                write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading 
           }                             
           Else {Write-host ("-------------------------------------------------------------------------------"+
                           "`n                       Configuring $($VSMSSD.__server)"  +
                           "`n-------------------------------------------------------------------------------")
           }
           Write-host     ("[ 1] Select a different Server" +
                         "`n[ 2] Manage Server settings" +
                        ("`n                     MAC address  range [ {0,24} - {0,-23} ]" -f $VSMSSD.MinimumMacAddress,$VSMSSD.MaximumMacAddress) +
                        ("`n                     Default  VM folder [ {0,-50} ]  " -f $VSMSSD.DefaultExternalDataRoot)    +              
                        ("`n                     Default VHD folder [ {0,-50} ]  " -f $VSMSSD.DefaultVirtualHardDiskPath) +
                         "`n[ 3] Manage Network settings ")
           $switch  | Foreach-object{
               write-host ("                        Virtual Network [ {0,-50} ]" -f $_.elementname)
           }
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           write-host      "[ 4] Cluster Networks for Live Migration "
           get-VMLiveMigrationNetwork | ForEach-Object{
           write-host (                                "     {0,-35}[ {1,-50} ]" -f $_.name,$_.address)}}
           Write-host (  "`n[ 5] Manage Virtual Disk files" )
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           if ((Get-Cluster $server).enableSharedvolumes -ne "enabled") {write-host "     Cluster shared Volumes are disabled"} else {
           write-host "     Cluster Shared Volumes"
           foreach ($vol in (Get-ClusterSharedVolume)) {foreach ($sharedVol in $vol.sharedvolumeinfo) { 
               write-host ("     {1,-35}[ {0,-34} {2,15}]" -f $vol.name,$sharedvol.FriendlyVolumeName, ($sharedVol.partition.freespace / 1gb).tostring("#,###.## GB Free")) }}  
           }}
           
           Write-host (  "`n[ 6] Create Virtual Machine" + 
                         "`n[ 7] Import Virtual Machine" )
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           Write-host      "[ 8] Live migrate Virtual Machines" }
           write-host    "`n     Manage Virtual Machines ..."
           $global:count=10 ;  $vm | select-object -first 10 |  ForEach-Object {
               write-host ("[{0,2}] {1,-34} [ {2,-10} ]" -f ($Global:count ++) , $_.elementName, [vmState]$_.enabledState )  }
           if ($vm.Count -gt 10) {
              Write-host "`n[20] More Virtual Machines ..." 
           } 
           Write-host    "`n[99] Exit this menu"
           $selection= [int](read-host -Prompt "`nPlease enter a selection") 
           switch ($selection) {
                1  {    $newServer = Read-Host "Enter the name of the server you want to connect to"
                        if ($newServer) {
                            $temp = Get-WmiObject -ComputerName $NewServer -NameSpace $HyperVNamespace -Class "MsVM_VirtualSystemManagementServiceSettingData"
                            if ($?) {$Server=$newServer}  else {$null = Read-host "Can not Contact that server. Press [Enter] to continue"}
                        }
                   }
                2  {    $ExtdataPath = Read-host "Please enter the path to the new VM data folder, or press [enter] to leave unchanged"
                        if (-not $ExtdataPath) {$ExtdataPath = $VSMSSD.DefaultExternalDataRoot }
                        $VHDPath = Read-host "Please enter the path to the new VHD folder, or press [enter] to leave unchanged"
                        if (-not $VHDPath) {$VHDPath = $VSMSSD.DefaultVirtualHardDiskPath }
                        $minMac = Read-host "Please enter the lowest MAC address to assign, as 12 hex digits, or press [enter] to leave unchanged"
                        if (-not $minMac) {$minMac = $VSMSSD.MinimumMacAddress }
                        $maxMac = Read-host "Please enter the highest MAC address to assign, as 12 hex digits, or press [enter] to leave unchanged"
                        if (-not $maxMac) {$maxMac = $VSMSSD.MaximumMacAddress }
                        if (($ExtdataPath -ne $VSMSSD.DefaultExternalDataRoot) -or ($VHDPath -ne $VSMSSD.DefaultVirtualHardDiskPath) -or
                            ($minMac -ne $VSMSSD.MinimumMacAddress) -or ($maxMac -ne $VSMSSD.MaximumMacAddress )) { 
                               set-vmhost -Confirm -Server $server -ExtDataPath $ExtdataPath -vhdPath $VHDPath -MINMac $minMac -MaxMac $maxMac | Out-Null
                        }
                        read-host "Press enter to continue"
                        $VSMSSD.get()
                   } 
                3  {   if ($switch  ) { 
                           $Switchinfo =  foreach ($s in (get-vmSwitch -server $server)) {
                               $Swinfo = new-object psobject -Property @{"SwitchName"=$s.ElementName}
                               $ac = Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$s} where resultClass=Msvm_SwitchPort" | 
                                   Foreach-object {Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$_} where AssocClass=Msvm_ActiveConnection"} 
                               if ($ac) { add-member -InputObject $swinfo -MemberType NoteProperty -Name "ExternalNetworkName" -Value ($ac | 
                                              Foreach-Object {Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$_} where resultClass=Msvm_ExternalEthernetPort"}  ).elementName
                                          add-member -InputObject $swinfo -MemberType NoteProperty -Name "InternalNetworkName" -Value ($ac | 
                                              Foreach-Object {Get-WmiObject -Namespace $HyperVNamespace -Query "associators of {$_} where resultClass=Msvm_InternalEthernetPort"} ).elementName
                                }
                                if     (($swInfo.InternalNetworkName) -and   ($swInfo.ExternalNetworkName))   {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "External"}
                                elseif (                                     ($swInfo.ExternalNetworkName))   {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "External - no parent access"}
                                elseif (($swInfo.InternalNetworkName)                                     )   {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "Internal"}
                                else                                                                          {add-member -InputObject $swinfo -MemberType NoteProperty -Name "NetworkType" -Value "Private"}
                                $swinfo
                            }    
                            Format-Table -AutoSize -InputObject $switchInfo -property SwitchName, NetworkType,ExternalNetworkName | out-host
                            $SwitchChoice = Select-Item -TextChoice "&Cancel", "&Add a new Virtual Network","&Remove a Virtual Network" -default 0 -Caption "Virtual Network configuration" 
                       }
                       else {$switchChoice = 1}
                       if ($switchChoice -eq 1) {
                           if ($freeNic) {$SwitchType = Select-Item -TextChoice "&Cancel", "&Private", "&Internal" , "&External" -default 0 -Caption "Virtual Network Creatation" -Message "Which kind of Virtual network would you like to create"}
                           else          {$SwitchType = Select-Item -TextChoice "&Cancel", "&Private", "&Internal"               -default 0 -Caption "Virtual Network Creatation" -Message "Which kind of Virtual network would you like to create"}
                           if ($switchType)             {$switchName   = Read-host "Please enter a name for the new Virtual Network"}
                           if (($switchType -eq 3) -and ($switchName)) {$nic = Select-List -InputObject $freenic -Property name
                                                                        New-VMExternalSwitch -virtualSwitchName $switchName -server $server -ExternalEthernet $nic}
                           if (($switchType -eq 2) -and ($switchName)) {New-VMInternalSwitch -virtualSwitchName $switchName -server $server }
                           if (($switchType -eq 1) -and ($switchName)) {New-VMPrivateSwitch  -virtualSwitchName $switchName -server $server }
                       }                              
                       if ($switchChoice -eq 2) {
                           $switchOff = ($Switchinfo | Select-List -Property SwitchName).switchName
                           If ($switchOff) {Remove-VMSwitch -virtualSwitch $switchoff -server $server -confirm}
                       }                                           
                   }
                4  {   Select-VMLiveMigrationNetwork -confirm }
                5  {   show-vhdMenu $server}
                6  {   $VMName = Read-host "Please enter the Display name for the new VM. To cancel, press [Enter] with no name."
                       if ($VMName) {$Path = Read-host "Enter the folder to hold the VMs configuration, or press [Enter] to use $($VSMSSD.DefaultExternalDataRoot) "
                                     if ($path) {$VM = New-VM -Name $vmname -Server $server -path $path -Confirm } else {$VM = New-VM -Name $vmname -Server $server -path $path -Confirm }
                                      
                                     if ($VM) {Show-VMMenu $vm}}
                   }
                7  {   $Path = Read-host "Please enter the Path to the folder holding the exported files you want to import."
                       if ($Path) {$ReUse=[boolean](Select-Item -Caption "Importing VM" -Message "Do you wish to re-use IDs" -TextChoices "No", "Yes")
                                   Import-VM -path $path -Server $server -Wait -ReuseIDs:$Reuse -Confirm | Out-Null
                       }   
                   }
                8  {   $HA_VMs =  Get-cluster -name $server |  Get-ClusterGroup |
                             where-object { (Get-ClusterResource -input $_ | where {$_.resourcetype -like "Virtual Machine*"})}
                       $HA_VMs |  format-table -autosize -property Name,State,OwnerNode
                       $RunningNodes = Get-Clusternode -cluster $server | where {$_.state -eq "Up"}
                       if ($RunningNodes.count -lt 2) {write-warning "Migration needs two cluster nodes to be running"} else {
                          $HA_VMs =  $HA_VMS | where-object { $_.state -eq "Online"}
                          If (-not $HA_VMs) {Write-warning "No High Availabilty VMs are on-line on the cluster"}
                          else { 
                                 $sources =  $HA_VMs | group ownernode
                                 if ($sources -is [array]) {  Write-host "FROM which node do you want to migrate" }
	                         $SourceNode =  ($sources | Select-List -property name,@{Name="Running VMs"; expression={$_.count}})
                                 if ($sourceNode) {
                                     Write-host "Moving From: $($sourceNode.Name)"
 	                             if ($RunningNodes.count -gt 2) {  Write-host "TO which node do you want to migrate" }
                                     $destinationNode = ($RunningNodes | where {$_.name -ne $sourceNode.name} | Select-List -Property name).name 
                                     if ($destinationNode) {
                                         write-host "Moving To:   $destinationNode "
                                         $HA_VMs = ($HA_VMs | where {$_.ownerNode.name -eq $sourcenode.name} )
                                         if (($HA_vms.count -gt 1) -and (select-item -Caption "Do you want to migrate" -TextChoices "&All VMs","&Selected VMs"  -Message "")) {
                                             $HA_VMs | select-list -Property name -multi |Move-ClusterVirtualMachineRole -Node $destinationNode | out-Default} 
                                         else {$HA_VMs | Move-ClusterVirtualMachineRole -Node $destinationNode | out-default }
                                         Get-cluster -name $server | Get-ClusterGroup | 
                                               where-object { (Get-ClusterResource -input $_ | where {$_.resourcetype -like "Virtual Machine*"})} |  format-table -autosize -property Name,State,OwnerNode
                                     }
                                 } 
                          }
                       }
                       Read-host "Press [Enter] to continue." 
                   }

                                                    
                {($_ -ge 10) -and ($_ -le 19)} 
                   {   Show-VMMenu -VM $vm[($_ -10)] }
                20 {   Select-vm -Server $server | Show-VMMenu }
           }   
    } until ($Selection -gt 30) 
}  


Function Show-VHDMenu 
{<#
    .SYNOPSIS
        Displays a menu to manage hyperv Virtual hard disks    
    .PARAMETER Server
        The Server holding the VHDs (by default, the local Computer)
#> 
    param ($server=".") 
    
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)}    
    $folder = Get-VhdDefaultPath -server $server
    Do {
           Clear-host          
           $vhd = Get-vhd -Path $folder -server $server    
           if ($host.name -notmatch "\sISE\s")  {
                $heading = "Configuring Virtual Disks on $($VSMSSD.__server)"
                $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + (("-" * ($host.ui.RawUI.WindowSize.width-1))) + "`n"
                write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading 
           }                             
           Else {Write-host ("-------------------------------------------------------------------------------"+
                           "`n                  Configuring disks on server $server"  +
                           "`n-------------------------------------------------------------------------------")
           }
           if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
           if ((Get-Cluster $server).enableSharedvolumes -ne "enabled") {write-host "     Cluster shared Volumes are disabled"} else {
           write-host "Cluster Shared Volumes"
           foreach ($vol in (Get-ClusterSharedVolume)) {foreach ($sharedVol in $vol.sharedvolumeinfo) { 
               write-host ("{1,-35} :{0,-34} {2,15}" -f $vol.name,$sharedvol.FriendlyVolumeName, ($sharedVol.partition.freespace / 1gb).tostring("#,###.## GB Free"))}}
           }}

           Write-host   ("`n[ 1] Change current folder (from $Folder )"      +
                         "`n[ 2] List current Virtual Floppy disk (VFD) files" +
                         "`n[ 3] Create a new Virtual Floppy disk (VFD) file" +
                         "`n[ 4] Create a new Virtual  Hard  disk (VHD) file" +
                       "`n`n     Inspect / Edit VHD files in $folder")
           
                         
           $global:count=10 ;  $vhd | select-object -first 10 |  ForEach-Object {
               write-host ("[{0,2}] {1} " -f ($Global:count ++) , ($_.Name -replace ($folder+"\").replace("\","\\"),""))  }
           if ($vhd.Count -gt 10) {
               Write-host ("     $folder contains too many VHD files to show `n" +
                           "[20] Select a VHD file from a full list `n" )
               Write-host  "[21] Enter the path to VHD file"
           } 
           Write-host    "`n[99] Exit this menu"
           $selection= [int](read-host -Prompt "`nPlease enter a selection") 
           switch ($selection) {
                1  {    $newFolder = Read-Host "Please enter the name of the folder you want to connect to "
                        if ($newFolder) {
                           $newFolder = $newFolder -replace '\\$',''
                            $d = get-wmiobject -ComputerName $server -query ("select * from Win32_Directory where name='{0}'" -f $NewFolder.replace('\','\\') )
                            if ($d) { $vhd = Get-WmiObject -Query "associators of {$d} where resultClass=cim_datafile"  | where-object {$_.extension -eq "VHD"} |sort-object -Property name 
                                      $folder = $NewFolder }
                            else    { $null = Read-host "The specified directory can not be found`nPress [Enter] to continue" }
                        }
                   }
                2  {     $d = get-wmiobject -ComputerName $server -query ("select * from Win32_Directory where name='{0}'" -f $Folder.replace('\','\\') )
                         if ($d) { $v = Get-WmiObject -Query "associators of {$d} where resultClass=cim_datafile"  | sort-object -Property name  | foreach-object {
                             if  ($_.extension -eq "VFD") {write-host ($_.Name -replace ($folder+"\").replace("\","\\"),"")}
                         }}
                         $null = Read-host "Press [Enter] to continue"
                   }      
                3  {    $vfdPath   = Read-Host "Please enter the name for the VFD file" 
                        if ($vfdpath )   {
                            if ($VfDPath -notmatch "\w+\\\w+")  {$vfdPath = ($folder + '\' +  $vfdPath) }
                         }
                         if ($vfdpath )   {   
                            if ($vfdPath -notmatch ".VFD$") {$vfdPath += ".VFD"}
                            New-VFD -vfdPath $VfdPath -server $server -wait | out-null
                            $null = Read-host "Press [Enter] to continue"
                        }     
                   }
                4  {    $vhdType= Select-Item -TextChoices "&Cancel","Dynamically &Expanding", "&Fixed Size", "&Differencing" -Caption "Which type of VHD would you like to create ?" 
                        If ($VhdType) {
                            $VHDPath       = Read-Host "Please enter the name for the VHD file" 
                            if ($VHDPath -notmatch "\w+\\\w+") {$VHDPath = ($folder + '\' +  $VHDPath)  }
                            if ($vhdPath)  {
                                if ($vhdPath -notmatch ".VHD$") {$vhdPath += ".VHD"}
                                switch ($vhdType) {
                                     {@(1,2) -contains $_}  
                                        { $Fixed = ($_ -eq 2) 
                                          $size = [single](Read-host "Please enter the size of the new VHD in GB") * 1GB
                                          if ($size) { New-VHD  -server $server -VHDPath $VHDPath -Fixed:$fixed -Size $size -wait | out-null 
                                          } 
                                        }
                                     3  { $ParentPath = Read-Host "Please enter the name for the Parent VHD file" 
                                          if ($ParentPath)  {
                                              if ($ParentPath -notmatch ".VHD$")    {$ParentPath += ".VHD"}
                                              if ($ParentPath -notmatch "\w+\\\w+") {$ParentPath = ($folder + '\' +  $ParentPath) }
                                               if (Get-WmiObject -query ("Select * from cim_datafile where name='{0}' " -f $parentPath.replace("\","\\") )) {
                                                    New-VHD  -VHDPath $VHDPath -parentVHD $parentPath -server $server -wait | out-null
                                               }
                                               else {$null = Read-host "The specified parent VHD file can not be found.`nPress [Enter] to continue" }
                                           }
                                        } #2
                                }  #switch                            
                            } #vhdpath
                        }#vhd typ
                   }  #4
             {10..19 -contains $_}
                   {  $SelectedVHD = ($vhd[$_ -10]).name }
              20   {  $SelectedVHD = (Select-List -InputObject $vhd -Property ,@{Name="Name"; expression={$_.Name -replace ($folder+"\").replace("\","\\"),""}}).name     }
              21   {  
                      $SelectedVHD = Read-Host "Please enter the name of the VHD file" 
                      if ($SelectedVHD)  {
                          if ($SelectedVHD -notmatch ".VHD$")    {$SelectedVHD += ".VHD"}
                          if ($SelectedVHD -notmatch "\w+\\\w+") {$SelectedVHD = ($folder + '\' +  $SelectedVHD) }
                           if (-not (Get-WmiObject -query ("Select * from cim_datafile where name='{0}' " -f $SelectedVHD.replace("\","\\") ))) {
                               $SelectedVHD = $null
                               $null = Read-host "The specified VHD file can not be found.`nPress [Enter] to continue"
                           }
                       }              
                   } 
            {(10..21 -contains $_) -and $SelectedVHD} 
                   {  $VHDTestResult = Test-vhd -Server $server -VHDPath $SelectedVHD
                      $VHDInfo       = Get-VHDInfo -server $server -VHDPath $SelectedVHD  
                      $VHDInfo | out-host
                      if     ([vhdtype]$vhdinfo.type -eq [vhdtype]::dynamic)  {
                            $VHDSelect = select-item -TextChoices "&Return to previous menu", "Convert VHD &Type", "&ExpandVHD", "&Compact VHD" -Caption "VHD maintenance" -Message "Would you like to: "  
                      }
                      elseif ([vhdtype]$vhdinfo.type -eq [vhdtype]::fixed)  {
                            $VHDSelect = select-item -TextChoices "&Return to previous menu",  "Convert VHD &Type", "&ExpandVHD"  -Caption "VHD maintenance" -Message "Would you like to: "
                      }
                      elseif ([vhdtype]$vhdinfo.type -eq [vhdtype]::differencing -and $vhdTestResult)  {
                             $VHDSelect = select-item -TextChoices "&Return to previous menu",  "Convert VHD &Type"  -Caption "VHD maintenance" -Message "Would you like to: "
                      }
                      elseif ($vhdinfo.type -eq [vhdtype]::differencing )  {
                             $VHDSelect = 4 * (select-item -TextChoices "&No",  "&Yes" -default 1 -Caption "VHD maintenance" -Message "Would you like to reconnect the parent disk ?"  )
                      }
                      switch ($vhdSelect) {
                            1 { $vhdType = $null
                                if ([vhdtype]$vhdinfo.type -eq "differencing")  { $vhdType= if (Select-Item -TextChoices "Dynamically &Expanding", "&Fixed Size" -Caption "Which type of VHD would you like to Convert to ?") {[vhdtype]::fixed} else {[vhdtype]::Dynamic}  }
                                if ([vhdtype]$vhdinfo.type -eq "dynamic"     )  { $vhdType= [vhdtype]::fixed   }
                                if ([vhdtype]$vhdinfo.type -eq "fixed"       )  { $vhdType= [vhdtype]::dynamic }   
                                If ($VhdType) {
                                    $DestPath       = Read-Host "Please enter the name for the VHD file" 
                                    if ($DestPath)  {
                                        if ($DestPath -notmatch "\w+\\\w+") {$DestPath = ($folder + '\' +  $DestPath) }
                                        if ($DestPath -notmatch ".VHD$")    {$DestPath += ".VHD"}
                                        Convert-VHD -Server $server -VHDPath $selectedVHD -DestPath $DestPath -Type $vhdType  
                                   }
                                }
                              }
                            2 { $size = [single](Read-host "Please enter the size of the new VHD in GB") * 1GB
                                if ($size -gt $VHDinfo.MaxInternalSize) { Expand-VHD  -Server $server -VHDPath $selectedVHD -size $size -Wait | out-null    }
                                else                                    { Write-host "Current size is $($VHDinfo.MaxInternalSize /1GB)GB. You must enter a larger size."}
                              }
                            3 { compact-VHD -Server $server -VHDPath $selectedVHD  }                              
                            4 { $ParentPath = Read-Host "Please enter the name for the Parent VHD file" 
                                if ($ParentPath)  {
                                    if ($ParentPath -notmatch ".VHD$")     {$ParentPath += ".VHD"}
                                    if ($ParentPath -notmatch "\w+\\\w+")  {$ParentPath = ($folder + '\' +  $ParentPath) }
                                    if (Get-WmiObject -query ("Select * from cim_datafile where name='{0}' " -f $parentPath.replace("\","\\") )) {
                                         Connect-VHDParent -Server $server -VHDPath $selectedVHD -ParentPath $parentPath -Wait 
                                         
                                    }
                                }    
                                else {Write-host "The specified parent VHD file can not be found." }
                              }  
                            
                      }        
                      if ($vhdSelect) {$null = Read-host "Press [Enter] to continue" }
                   }                    
            }  #switch
    }   until ($Selection -gt 30) 
}

Function Show-VMDiskMenu 
{<#
    .SYNOPSIS
        Displays a menu to manage an individual VM's disks
   .PARAMETER VM
        The virtual Machine to manage
   .PARAMETER VMSCSI
        The SCSI controllers on the VM
   .PARAMETER VMDisk
        The disks controllers on the VM     
#>
param ($vm , $vmScsi , $vmdisk)                    
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)}    
    do { 
        $ChangeScsiHD=([boolean][int](Get-WmiObject -computerName $vm.__server -class "win32_operatingsystem").version.split(".")[1] ) -and  ($vmScsi.count -ge 1) 
        $dvdDrivePresent = [boolean]($vmdisk  | where {$_.driveName -like "DVD*"}) 
        if ($vm.EnabledState -eq [vmstate]::Stopped) {
            if ( ($vmdisk | where { $_.controllername -like "ide*" } | measure-object).count -lt 4)  {$AddIDEDrive = $true}
            if (  [boolean]($vmdisk | where {$_.controllername -like "ide*"}))                       {$ChangeIDEDrive = $true}
            if (  $vmScsi.count -ge 1 ) { $ChangeScsiHD = $true }
        }   
        if ($host.name -notmatch "\sISE\s") {
                               $heading = "Configuring Disk for VM : $($VM.ElementName) on server $($VM.__Server)"
                               $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + 
                                         ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + 
                                         (("-" * ($host.ui.RawUI.WindowSize.width-1))
                                        ) + "`n"
                               Clear-host
                               write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading
        }
        else                  {Write-host   "     -------------------------------------------------------------------------------"
                               write-host   "           Configuring Disk for VM : $($VM.ElementName) on server $($VM.__Server)"
                               write-host   "     -------------------------------------------------------------------------------`n"
        }
        $vmdisk | format-table -AutoSize -Property  ControllerName, DriveLun, driveName, diskimage  
        If  ($ChangeScsiHD)    {Write-host  "[ 1] Add Hard drive to a SCSI Contoller  "}         else {write-host   "[--] -----"}
        If  ($ChangeScsiHD -and ($vmdisk | 
              where {$_.controllername -like "*SCSI*"})) {
                               Write-host   "[ 2] Change disk image attached to SCSI hard drive"
                               Write-host   "[ 3] Remove SCSI Drive" }                           else {write-host   "[--] -----`n[--] -----"
        }
        if  ($AddIDEDrive)     {Write-host "`n[ 4] Add a Hard drive to an IDE Controller "}      else {write-host "`n[--] -----"}
        if  ($ChangeIDEDrive ) {Write-host   "[ 5] Change disk image attached to IDE hard drive"
                                Write-host   "[ 6] Remove IDE Hard drive or IDE DVD drive"}      else {write-host   "[--] -----`n[--] -----"}
        if  ($AddIDEDrive)     {Write-host "`n[ 7] Add IDE DVD drive"}                           else {write-host   "[--] -----"}
        if  ($dvdDrivePresent) {Write-host   "[ 8] Change disk (image) attached to DVD drive"}   else {write-host   "[--] -----"}
                                Write-host   "[10] Manage VHD files"  
                                Write-host "`n[99] Return to previous menu`n"
        $selection =       [int](read-host   "     Please select an option "  )
        switch ($selection) {
            1  { $controller = $vmscsi | select-list -Property @{Name="Controller"; expression={$_.ElementName}},
                                                               @{Name="Drive(s) Attached";expression={(Get-VMDriveByController $_ | measure-Object).count}}
                 if ($controller) { 
                    Get-VMDriveByController $controller | foreach -begin {$addresses = @() } -process {$addresses += $_.address }
                    do { $lun= Read-host "Please enter the LUN for the new disk" 
                         if ($addresses -Contains $lun) {write-host "That lun is already in use"}
                       }  until ($addresses -notContains $Lun)
                    $respool = get-wmiobject -Namespace root\virtualization -query "Select * from Msvm_ResourcePool where ResourceSubType = 'Microsoft Physical Disk Drive'"
                    $hostPassThroughDisks= (get-wmiobject -Namespace root\virtualization -query "associators of {$respool} where resultClass=Msvm_DiskDrive" )
                    if ($lun -and $hostPassThroughDisks ) {
                          $passThrough = Select-Item -TextChoices @("&VHD File","&Physical Disk") -Caption "Connecting Hard drive" -Message "Do wish to connect the new disk to"
                    }
                    if ($passThrough) {Add-VMPassThrough -LUN $lun -ControllerRASD $controller -PhysicalDisk (Select-List -InputObject $hostPassThroughDisks -Property @("elementName") )}
                    Elseif ($lun)     { 
                        $drive  =  Add-VMDrive -Confirm  -ControllerRASD $controller -LUN ($lun.replace("Lun ",""))
                        if ($drive)  {$Path = Read-host "Please enter a path to the image to mount in the new drive"
                                      If ($path) {Add-VMDisk -DriveRASD $drive -Path $path | out-null } 
                        }
                    } 
                 }    
               } 
            3  { $DriveID =  ($vmDisk | where {$_.controllerName -like "*SCSI*"} | 
                                  Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\") 
                 if ($DriveID) {$wql= "select * from MSVM_ResourceAllocationSettingData where instanceId='$DriveID' " 
                                Remove-VMRasd -VM $vm -rasd (Get-WmiObject -ComputerName $vm.__SERVER -Namespace $HyperVNamespace -Query $WQL) -Confirm
                 }
               }    
            6  { $DriveID =  ($vmDisk | where {$_.controllerName -like "*IDE*"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\") 
                 if ($DriveID) {$wql= "select * from MSVM_ResourceAllocationSettingData where instanceId='$DriveID' " 
                                Remove-VMRasd -VM $vm -rasd (Get-WmiObject -ComputerName $vm.__SERVER -Namespace $HyperVNamespace -Query $WQL) -Confirm
                 }
               }
            {@(2,5,8) -contains $_}
               { if ($_ -eq 2) {$DriveID =  ($vmDisk | where {$_.controllerName -like "*SCSI*"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\") 
                 }
                 if ($_ -eq 5) {$DriveID =  ($vmDisk | where {$_.controllerName -like "*IDE*" -and $_.DriveName -eq "Hard Drive"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\")
                 }
                 if ($_ -eq 8) {$DriveID =  ($vmDisk | where  {$_.DriveName -eq "DVD Drive"} | 
                                    Select-List -Property ControllerName,DriveLun,drivename,DiskImage).DriveInstanceID.replace("\","\\")              
                 }
                 if ($DriveID) {$Path = Read-host "Please enter a path to the new image to mount in the drive"
                                $wql= "select * from MSVM_ResourceAllocationSettingData where instanceId='$DriveID' " 
                                $drive=(Get-WmiObject -ComputerName $vm.__SERVER -Namespace $HyperVNamespace -Query $WQL)     
                                if ($path)  {if (Get-VMDiskByDrive -Drive $drive) {Set-VMDisk -DriveRASD $drive -Path $path -Confirm | out-null }
                                             else                                 {add-vmDisk -DriveRASD $drive -Path $path -OpticalDrive:$($_ -eq 8) -Confirm | out-null }
                                }
                                elseif ($_ -eq 8 -and (Get-VMDiskByDrive -Drive $drive)) { write-host "Removing Optical disk from the drive."
                                                                                           Remove-VMdrive -DriveRASD $drive -Diskonly 
                                }
                 }
               }
            {@(4,7) -contains $_ } 
               { $optical = [boolean]($_ -eq 7)
                 if (-not $optical) {Write-host -ForegroundColor red "If you need to create a VHD file, go back to the previous menu to do so"}    
                 $controller = (Get-VMDiskController -ide -vm $vm | 
                     where-object {(Get-VMDriveByController $_ | measure-Object).count -lt 2} | 
                         Select-List -Property @{Name="Controller"; expression={$_.ElementName}}  )
                 if ($controller) {
                     Get-VMDriveByController $controller |  foreach -begin {$addresses = @() }  -process {$addresses += $_.address } 
                     $lun = ($(foreach ($l in (0..1 | where {$addresses -notContains $_} )) {
                                    Add-Member -InputObject ( New-Object -TypeName System.Object ) -PassThru -name lun -MemberType noteproperty -Value $l |  
                                        Add-Member -PassThru -name lunName -MemberType noteproperty -Value "Lun $l" }) |  select-list -property @("LunName")).lun
                     $path = $null 
                     $respool = get-wmiobject -Namespace root\virtualization -query "Select * from Msvm_ResourcePool where ResourceSubType = 'Microsoft Physical Disk Drive'"
                     $hostPassThroughDisks= (get-wmiobject -Namespace root\virtualization -query "associators of {$respool} where resultClass=Msvm_DiskDrive" )
                     if (-not $optical -and $hostPassThroughDisks ) {
                          $passThrough = Select-Item -TextChoices @("&VHD File","&Physical Disk") -Caption "Connecting Hard drive" -Message "Do wish to connect the new disk to"
                     }
                     if ($passThrough) {Add-VMPassThrough -Confirm -LUN $lun -ControllerRASD $controller -PhysicalDisk (Select-List -InputObject $hostPassThroughDisks -Property @("elementName") ) | out-null}
                     Else   {
                         $drive =  Add-VMDrive -Confirm -OpticalDrive:$optical  -ControllerRASD $controller -LUN $lun
                         if ($drive) { 
                              $hostOpticalDrives = Get-WmiObject -ComputerName $vm.__SERVER -Query "Select * From win32_cdromdrive"
                              if ($optical -AND $hostOpticalDrives) {
                                 switch (Select-Item -TextChoices @("&ISO File","&Physical Disk", "Decide &Later") -Caption "Connecting DVD drive" -Message "Do wish to connect the new disk to") {
                                     1 {$path=(Select-List -InputObject $hostOpticalDrives -Property ID,mediatype,caption).deviceID}
                                     0 {$Path = Read-host "Please enter a path to the image to mount in the new drive"}
                                 }
                              }
                              Else {$Path = Read-host "Please enter a path to the image to mount in the new drive"}
                              If   ($path) {Add-VMDisk -DriveRASD $drive -Path $path -OpticalDrive:$optical -confirm| out-null }
                              elseif (-not $optical) {$null = Read-host "It is not supported to have a hard disk without an image or pass through disk."} 
                         }                      
                     }                                                 
                 }
               } 
           10  {Show-vhdMenu $vm.__Server}                                                                               
       }
       $null = Read-host "Press [enter] to continue"
       [Object[]]$vmDisk = Get-VMDisk $vm
   } until ($selection -ge 20)
   
}


Function Show-VMMenu
{<#
    .SYNOPSIS
        Displays a menu to manage and individual VM
   .PARAMETER VM
        The virtual Machine to manage
   .PARAMETER Server
        If a VM Name is passed, the name of the server where it is found. By default the local computer
#>
   Param(
      [parameter(Position=0 , mandatory=$true, ValueFromPipeline = $true)]
      $VM ,
      
      $Server="." 
     )
    $hiBack= $host.UI.RawUI.ForegroundColor
    $hiFore= $host.UI.RawUI.BackgroundColor
    $Refreshneeded = $True
    if ($hiFore -eq -1) {$hiFore = ($HiBack -bxor 15)} 
    if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
    if ($vm.__CLASS -eq 'Msvm_ComputerSystem'){ do {    
          if ($RefreshNeeded) {
              Write-Progress -Activity "Configuring VM $($VM.ElementName) " -Status "Gathering Data" 
              $VMCG       = Get-vmClusterGroup $vm
              $vmsd       = Get-VMSettingData $vm  
              $VSGSD      = get-wmiobject  -computername $vm.__SERVER -namespace $HyperVNamespace  -Query "associators of {$vm} where resultclass=Msvm_VirtualSystemGlobalSettingData"
              $VMcpu      = Get-VMCPUCount $vm
              $vmMemory   = Get-VMMemory $vm  
              $VMFloppy   = Get-VMFloppyDisk $vm 
    [Object[]]$vmScsi     = Get-VMDiskController $vm -SCSI 
    [Object[]]$vmDisk     = Get-VMDisk $vm
              $vmComPort  = Get-VMSerialPort $vm 
              $vmNic      = Get-VMNic $vm
              $VmSnap     = Get-VMSnapshottree $vm
    [Object[]]$vmNic      = Get-VMNic $vm
              $vmICs      = Get-VMIntegrationComponent $vm
              $vmRFX      = Get-VMRemoteFXController $VM
              Write-Progress -Activity "Configuring VM $($VM.ElementName) " -Status "Gathering Data" -Completed
              $Refreshneeded = $false
          }                       
          if ($host.name -notmatch "\sISE\s") {
              $heading = "Configuring VM : $($VM.ElementName) on server $($VM.__Server)"
              $heading=(("-" * ($host.ui.RawUI.WindowSize.width-1)) + "`n" + ("|"+$heading.Padleft(($heading.length / 2) + ($host.ui.RawUI.WindowSize.width /2))).padright($host.ui.RawUI.WindowSize.width -2) +"|") + "`n" + (("-" * ($host.ui.RawUI.WindowSize.width-1))) + "`n"
              Clear-host
              write-host -ForegroundColor $hifore -BackgroundColor $hiBack $heading
         }
         else                               { 
              Write-host  "     -------------------------------------------------------------------------------"
              write-host  "               Configuring VM : $($VM.ElementName) on server $($VM.__Server)"
              write-host  "     -------------------------------------------------------------------------------"
         }
          write-host     ("[ 1] Change VM State          :                  [ {0,-61} ]"             -f [vmState]$vm.enabledState)
          write-host     ("[ 2] Rename                   :                  [ {0,-61} ]"             -f $vmsd.elementName)                    
          ([bootmedia[]]$vmsd.BootOrder) | % -begin {$b=""} -process {$b += $_.tostring() +", "} `
    -end {write-host     ("[ 3] Boot order               :                  [ {0,-61} ]"             -f ($b -replace ", $",""))}
          write-host     ("[ 4] Notes                    :                  [ {0,-61} ]"             -f $vmsd.NOTES)
          write-host     ("[ 5] Recovery and             :                  [ On service fail:{0,-16}, On Host shutdown:{1,-10} ]"`
                                                                                                    -f [RecoveryAction]$vsgsd.AutomaticRecoveryAction ,
                                                                                                        [ShutdownAction]$vsgsd.AutomaticShutdownAction) 
          write-host     ("     Startup options                             [ On Host boot   :{0,-16}, Delay {1,4} seconds          ]" `
                                                                                                    -f [StartUpAction]$vsgsd.AutomaticStartupAction, 
                                                                                                       [System.Management.ManagementDateTimeconverter]::ToTimeSpan($VSGSD.AutomaticStartupActionDelay).Seconds )
          write-host     ("[ 6] Snapshots                :")                                         
          $VmSnap | foreach-object {
              write-host ("                              $_" )
          }            
          write-host     ("[ 7] Export VM                "  )                                                         
          write-host     ("[ 8] Delete VM  "  )                                                          
          write-host     ("[ 9] Integration Components   :                  [ {0}/{1} Enabled                                       ]" -f ($vmics | where {$_.enabledState -eq [VMState]::running} | Measure-Object ).count ,
                                                                                                      ($vmics | Measure-Object ).count)
          Write-Host     ("[10] CPU                      :   {0} Processor(s) [ Reserve:{1,7}/100000 - Limit:{2,7}/100000 - Weight:{3,-4}   ]" `
                                                                                                   -f $VMcpu.VirtualQuantity, $VMcpu.Reservation, $VMcpu.Limit, $VMcpu.Weight) 
          write-host     ("[11] Memory                   :        {0, 6} MB [ Buffer :{1,7}%       - Limit:    {2,7} MB - Weight:{3,-6} ]"           -f $VMMemory.virtualQuantity,$vmMemory.TargetMemoryBuffer, $VmMemory.limit , $vmMemory.weight )
          if ($vmscsi.count -lt 4)   {
              write-host ("[12] SCSI Controllers         :                  [ {0} Present                                                     ]"     -f ([int]$vmscsi.count) )  
              write-host ("[13] IDE and SCSI Disks       : ") 
          }
          else {
              write-host ("[13] IDE and SCSI Disks       :                 [ Max 4 SCSI Controllers present                                    ]" )     
          }        
          if ($vmdisk) { $vmDisk | foreach-object {
              write-host ("     {0,-25                  }: {1,15         }: [ {2,-61} ]"             -f ($_.controllerName +" LUN:"+ $_.DriveLUN) , $_.DriveName, $_.diskimage)}
          }
          write-host     ("[14] Floppy Disk              :           Image: [ {0,-61} ]"             -f $(if ($vmFloppy.Connection) {$VMFloppy.connection[0]} else {""}))
          $Global:count=15 ;                   
          $vmComPort | foreach-object {if ($_) {
              write-host ("[{2,2}] {0,-25               }:      Connection: [ {1,-61} ]"             -f $_.ElementName, $_.connection[0],($Global:count ++))
          }}
          if ($vmRFX) {      
          Write-Host     ("[18] Remote FX                :     {0} Monitor(s) [ {1,-61} ]"           -f $vmRFX.MaximumMonitors, ([RemoteFxResoultion]$vmRFX.MaximumScreenResolution) )}
          elseif ((Get-WmiObject -ComputerName $vm.__server -class win32_operatingsystem).version -gt "6.1.7600"){
          Write-Host     ("[18] Add Remote FX controller :")}
          if ((($vmNic | where {$_.type -eq "synthetic"} | measure-object).count -lt 8) -or (($vmnic | where {$_.type -eq "emulated"} | measure-object).count -lt 4) ){
              write-host ("[19] Add Network interface    : ")
          }
          $Global:count=20
          $vmnic     | foreach-object {if ($_) {
              write-host ("[{3,2}] {0,-25               }: MAC:{1         } [ {2} ] "            -f $_.ElementName,$_.address,(Get-VMnicSwitch $_).elementname ,($Global:count ++))
          }}
          if (get-Module FailoverClusters -ErrorAction SilentlyContinue) {
          write-host   ("`n[30] Cluster status           :                  [ {0,-61} ]"           -f  $VMCG.state)
          }
          write-host   ("`n[40] Refresh data")
          write-host   ("`n[99] Exit this menu`n")
          $selection = [int](read-host    "Enter a selection")
        
          if ($?) {switch ($selection) {
              1 {  switch ($vm.enabledState ) {
                       {$_ -eq [vmstate]::Suspended} {   
                           Switch (select-item -TextChoices @("&Delete Saved state", "&Start VM", "&Cancel") -Caption "$($vm.elementname) is Suspended" -Message "Do you want to:" -default 2) {
                               0 {stop-vm  -Confirm -VM $vm ; $null = read-host "Press [enter] to continue" ; $vm.get() }
                               1 {Start-Vm          -VM $vm ; $null = read-host "Press [enter] to continue" ; $vm.get() }
                           }        
                       }    
                       {$_ -eq [vmstate]::Stopped }  {
                           if ((select-item -TextChoices @("&Start VM", "&Cancel") -Caption "$($vm.elementname) is Stopped" -Message "Do you want to:" -default 1) -eq 0) {
                                Start-VM $vm 
                                $null = read-host "Press [enter] to continue"  
                                $vm.get()
                           }
                       }
                       {$_ -eq [vmstate]::Running }  {
                            switch (select-item -TextChoices @("&Save VM","&Turn off VM", "Shut &Down the OS", "&Cancel")  -Caption "$($vm.elementname) is running" -Message "Do you want to:" -default 3) {
                                0 {Save-VM                    -VM $vm ; $null = read-host "Press [enter] to continue"  ;$vm.get()  } 
                                1 {Stop-VM           -Confirm -VM $vm ; $null = read-host "Press [enter] to continue"  ;$vm.get()  }
                                2 {Invoke-VMShutdown -Confirm -vm $vm ; $null = read-host "Press [enter] to continue"  ;$vm.get()  }
                            }     
                       }
                   } 
                } 
              2 {  $name=read-host "Enter the new name for the VM [leave blank to remain as $($vm.elementName)]"  
                   if ($name -ne "") { 
                        Set-vm -confirm -VM $vm -name $Name 
                        $vm.get()
                        $vmsd.get()
                   }        
                }
              3 { $vm.get(); if ($vm.EnabledState -eq [vmstate]::Stopped)  {
                       Write-host "Select the devices which in the order you want to boot from them. `n Any you don't select will be added in the order Floppy,CD,IDE,NET"
                       $newbootOrder = ($vmsd.BootOrder | select-object @{name="Device"; Expression={[bootMedia]$_}} | select-list -multiple -property Device  | %{$_.device} )
                       if ($newbootOrder -is [array]) {"Floppy","CD","IDE","NET" | ForEach-Object -process {if ($newbootOrder -notcontains $_) {$newbootOrder = $newBootOrder + $_}} `
                                                                                                      -end {set-vm -confirm -VM $vm -bootOrder ([bootmedia[]]$newbootOrder)}}
                       else                           {write-host "You need to enter at least 2 devices." }                                               
                       $null = read-host "Press [enter] to continue" ; $vmsd.get()
                   }
                   else {$null = read-host "You can change the boot order only when the VM is stopped.`nPress [enter] to continue"}
                }
              4 {  $Notes=read-host "Enter the new notes for the VM [leave blank to keep notes unchanged}"  
                   if ($Notes -ne "") { Set-vm -confirm -VM $vm -notes $Notes  ; $vmsd.get() }        
                }
              5 {   Write-host "Please select the action to be taken if the virtual machine worker process terminates abnormally"
                    $autoRecovery = Select-EnumType -EType RecoveryAction -default $vsgsd.AutomaticRecoveryAction
                    Write-host "Please select the action to be taken if the host OS is shutdown with the VM running"
                    $autoShutdown = Select-EnumType -EType ShutdownAction -default $vsgsd.AutomaticShutdownAction
                    Write-host "Please select the action to be when the host OS is Starts with the VM running"
                    $autoStartup  = Select-EnumType -EType StartupAction -default $vsgsd.AutomaticStartupAction  
                    if ($autostartup -ne [startupAction]::none) {$autoDelay= Read-host "Please enter the time in seconds to delay the automatic start up"   } 
                    if (-not $autoDelay) {$autoDelay = [System.Management.ManagementDateTimeconverter]::ToTimeSpan($VSGSD.AutomaticStartupActionDelay).Seconds }
                    if (     ($autoRecovery -ne $vsgsd.AutomaticRecoveryAction) -or ($autoShutdown -ne $vsgsd.AutomaticShutdownAction     ) `
                         -or ($autoStartup  -ne $vsgsd.AutomaticStartupAction ) -or ($autoDelay    -ne $vsgsd.AutomaticStartupActionDelay )) {
                        Set-vm -Confirm -vm $vm -AutoRecovery $autoRecovery -AutoShutDown $autoShutdown -autoStartup $autoStartup -AutoDelay $autoDelay
                        $null = read-host "Press [enter] to continue" 
                        $vsgsd.get() 
                    }    
                 }
               6 { if ($vmSnap -ne "-") {$action = select-item -TextChoices @("Create a &New snapshot" ,"&Apply a SnapShot","&Delete a SnapShot" , "&Rename a SnapShot" , 
                                                  "&Update a snapshot" , "&Cancel") -Caption "What do you want to do:" -default 5 
                   }
                   else                 {$action = 0 ; Write-host "No existing Snapshots, creating new Snapshot" }
                   switch ($action) {
                       0   {$note = Read-Host "Enter a note to describe the snapshot [optional]" 
                            New-VMSnapshot -VM $vm -note $note -wait -Confirm
                           }
                       {1..4 -contains $_}
                           {$snap = Select-VMSnapshot $vm} 
                       1   {Restore-VMsnapshot -SnapShot $snap -wait -Confirm ;  $refreshNeeded = $true  } 
                       2   {$Tree = [boolean](select-item -TextChoices @("&No" ,"&Yes") -Caption "Deleting Snapshot(s)" -message "Do you want to delete children of the select snapshot, if any ?" )
                            Remove-VMSnapshot  -snapshot $Snap -Tree:$tree -wait -Confirm
                           }
                       3   {$name = Read-Host "Please enter the new name for the snapshot"
                            if ($name) {rename-vmsnapshot  -snapshot $snap -newName $name}
                           }
                       4   {Update-VMSnapshot -VM $vm -snapName $snap.elementName -Confirm}
                       {0..4 -contains $_}    
                           {$null = read-host "Press [enter] to continue" ; $VmSnap = Get-VMSnapshottree $vm}
                   }                           
                 }
               7 { if (($vm.EnabledState -eq [vmstate]::Stopped) -or ($vm.EnabledState -eq [vmstate]::suspended)) {
                        $path = Read-host "Please enter path to store the exported files"
                        if ($path) { 
                            $CopyState = [boolean](select-item -TextChoices @("&Configuration data only","&Machine State and Configuration data") -Caption "What do you want to export:" -default 1 )
                            Export-VM -VM $vm -path $path -copyState:$copyState  -confirm
                            $null = read-host "Press [enter] to continue" 
                        }
                        else {$null = read-host "You can add export only when the VM is saved or stopped.`nPress [enter] to continue"}  
                   }
                 }  
               8 { if ((remove-vm -Confirm -VM $vm) -eq [ReturnCode]::OK) {return $null} } 
               9 { Write-host "Switch integration components between 'Running' (enabled) status and 'Stopped' (disabled status)"
                   $vmics | select-list -multiple -Property elementName, @{name="State";expression={[vmstate]$_.enabledstate}}  | 
                       Foreach-Object -begin   {$c=@()} `
                                      -process {$c += $_.elementName} `
                                      -end     {if ($c) {$null=Set-VMIntegrationComponent -vm $vm -Confirm -componentName $C 
                                                         $vmics = Get-VMIntegrationComponent -vm $vm
                                      }}
                 }
              10 { $vm.get() 
                   if ($vm.EnabledState -eq [vmstate]::Stopped)  {
                       $cpucount = Read-host "Enter the new number of Virtual CPUs [Leave blank to remain as $($VMcpu.VirtualQuantity)]" 
                   }
                   else {Write-host "You can change the number of processors only when the VM is stopped."}
                   if (-not $cpucount) {$cpuCount = $VMcpu.VirtualQuantity}
                   if ($vm.EnabledState -ne [vmstate]::Suspended)  {
                       $limit  = Read-host "Enter the new CPU limit (0 - 100000) [Leave blank to remain as $($VMcpu.Limit)]"
                       if (-not $limit) {$limit = $VMcpu.limit} 
                       $Reservation  = Read-host "Enter the new CPU Reservation (0 - 100000) [Leave blank to remain as $($VMcpu.Reservation)]"
                       if (-not $Reservation) {$Reservation = $VMcpu.Reservation} 
                       $Weight  = Read-host "Enter the new CPU Weight (default=100) [Leave blank to remain as $($VMcpu.weight)]"
                       if (-not $Weight) {$Weight = $VMcpu.Weight ; write-debug "Weight"} 
                           if ( ($Weight -ne $VMcpu.Weight) -or ($Reservation -ne $VMcpu.Reservation) -or ($limit -ne $VMcpu.limit) -or ($cpuCount -ne $VMcpu.VirtualQuantity)) {
                                if ($vm.EnabledState -eq [vmstate]::Stopped)  {Set-VMCPUCount -Confirm -VM $vm -CPUCount $CpuCount -Limit $limit -Reservation $reservation -Weight $weight }
                                else                                          {Set-VMCPUCount -Confirm -VM $vm                     -Limit $limit -Reservation $reservation -Weight $weight }
                           $null = read-host "Press [enter] to continue"
                           $vmCpu.get()
                       }
                   }
                   else {$null=Read-host "CPU weightings can not be changed on a saved VM``nPress [Enter] to continue"}
                 }
              11 { $vm.get()
                   $DynamicMemoryEnabled = $vmmemory.DynamicMemoryEnabled
                   $MemoryLimit = 0 
                   if ((Get-WmiObject -ComputerName $vm.__server -class win32_operatingsystem).version -gt "6.1.7600"){
                      if ($vm.EnabledState -eq [vmstate]::Stopped) {
                          if ($vmmemory.DynamicMemoryEnabled) {
                              $DynamicMemoryEnabled = [boolean](select-item -TextChoices @("&Disabled","&Enabled") -Caption "Dynamic Memory is Enabled "-Message "Should it be:" -default 1 )
                          }
                          Else {
                              $DynamicMemoryEnabled = [boolean](select-item -TextChoices @("&Disabled","&Enabled") -Caption "Dynamic Memory is Disabled "-Message "Should it be:" -default 0 )    
                          } 
                          $Memory=[int](Read-host "Please enter the new amount of memory in MB - or nothing to leave it as $($VMMemory.virtualQuantity)")
                          if ($Memory -eq 0 )     {$memory      = $VMMemory.virtualQuantity}
                          if ($DynamicMemoryEnabled) {
                                $MemoryLimit=[int](Read-host "Please enter the new  memory Limit in MB - or nothing to leave it as $($VMMemory.Limit)")
                          }
                          if ($MemoryLimit -eq 0) {$MemoryLimit = $VMMemory.Limit }
                      }
                      else {write-host "You can change the memory size only when the VM is stopped."
                            if (-not $DynamicMemoryEnabled) {$null = read-host "Press [enter] to continue"}
                      }
                      if ($DynamicMemoryEnabled) {
                                $MemoryBuffer=[int](Read-host "Please memory buffer Percentage between 5 and 2000 - or nothing to leave as $($VMMemory.TargetMemoryBuffer)")
                                if ($memoryBuffer -eq 0) {$MemoryBuffer = $VMMemory.TargetMemoryBuffer}
                                $memoryWeight=[int](Read-host "Please memory weighting between 1 and 10000 - or nothing to leave as $($VMMemory.Weight)")
                                if ($memoryWeight -eq 0) {$memoryWeight = $VMMemory.Weight}
                                if ($vm.EnabledState -eq [vmstate]::Stopped) {Set-VMMemory -Confirm -VM $vm -Dynamic -Weight $memoryWeight -BufferPercentage $memoryBuffer -Memory $memory -limit $MemoryLimit  |
                                                                                out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get()}
                                else                                         {Set-VMMemory -Confirm -VM $vm -Dynamic  -Weight $memoryWeight -BufferPercentage $memoryBuffer |
                                                                                out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get()}       
                      } 
                      elseif ((($memory -ne  $VMMemory.virtualQuantity) -or ($vmmemory.DynamicMemoryEnabled -ne $DynamicMemoryEnabled)  ) -and ($vm.EnabledState -eq [vmstate]::Stopped) )
                                                                             {Set-VMMemory -Confirm -VM $vm -Memory $memory | out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get() }
                  }
                  else {     
                       if ($vm.EnabledState -eq [vmstate]::Stopped) {
                            $Memory=[int](Read-host "Please enter the new amount of memory in MB - or nothing to leave it as $($VMMemory.virtualQuantity)")
                                
                            if ($memory) {Set-VMMemory -Confirm -VM $vm -Memory $memory | out-null ; $null = read-host "Press [enter] to continue"  ;$vmmemory.get() }
                        }
                        else {$null = read-host "You can change the memory size only when the VM is stopped.`nPress [enter] to continue"}
                   }     
                 } 
              12 { $vm.get()
                   if ($vm.EnabledState -eq [vmstate]::Stopped) {
                      if      (-not $vmScsi.count)  {$selection = 0}
                      elseif  ($vmScsi.count -eq 4) {$Selection = 1}
                      else   { $selection = Select-item -TextChoices "&Add a SCSI Controller","&Remove a SCSI controller","&Cancel" -Caption "SCSI Controllers" -Message "Would you like to:" }   
                      if ($Selection -eq 0) {
                           $nameSuffix = Read-host "By default all SCSI Controllers use the same display name.`nEnter a suffix to identify this SCSI controller [optional]"
                           add-vmscsicontroller -vm $vm -name ($lstr_VMBusSCSILabel + $namesuffix) -confirm | out-Null
                           $null = read-host "Press [enter] to continue"
                      }
                      if ($selection -eq 1) {$rasd =($vmscsi | select-list -Property @{Name="Controller"; expression={$_.ElementName}},
                                                                                     @{Name="Drive(s) Attached";expression={(Get-VMDriveByController $_ | measure-Object).count}}) 
                                             if ($rasd) {Remove-VMRasd -confirm -VM $vm -rasd $rasd                                         
                                                         $null = read-host "Press [enter] to continue" 
                                             }
                      }
                   }                             
                   else  {$null = read-host "You can add hardware only when the VM is stopped.`nPress [enter] to continue"}  
                   [Object[]]$vmScsi = Get-VMDiskController $vm -SCSI 
                 }
              13 { Show-VMdiskMenu -vm $vm -vmDisk $vmDisk -vmscsi $vmScsi 
                   [Object[]]$vmDisk  = Get-VMDisk $vm
                 }
              14 { if ($vmFloppy.Connection) { Remove-VMFloppyDisk -Confirm $vm}
                    Else                     { $path = Read-host "Please enter path to the VFD file."
                                                if ($path) {Add-VMFloppyDisk -VM $vm -Path $path}
                    }
                    $null = read-host "Press [enter] to continue" ; 
                    $VMFloppy   = Get-VMFloppyDisk $vm          
                 }
{($_ -eq 15)`
-or ($_ -eq 16)} { $port = ($_ - 14) 
                   $path = Read-host "Please enter the path for the named pipe to use as connection for COM$Port or blank to disconnect."
                   $null = Set-VMSerialPort -Confirm -vm $vm -PortNumber $port -Connection $path 
                   $null = read-host "Press [enter] to continue" ; $vmComPort= Get-VMSerialPort -vm $vm
                 }
              18 {  if ($vm.EnabledState -eq [vmstate]::Stopped)  {
                        if ($vmRFX) {$RFXResolution = $vmrfx.MaximumScreenResolution 
                                     $RFXMonitors   = $vmrfx.MaximumMonitors
                                     $action = select-item -TextChoices @("&Remove Remote FX controller","&Configure Remote FX controller") -Caption "What do you want to do:" -default 1}
                        else        {$RFXResolution = 0
                                     $RFXMonitors   = 1
                                     $action = 1 }
                        if ($action -eq 0) {Remove-VMRemoteFXController -Confirm -VM $vm ; $null = read-host "Press [enter] to continue"
                                          $vmRFX = $null }
                        else             {Write-host "Select the new resolution (Default $([RemoteFxResoultion]$RFXResolution) )"
                                          $RFXResolution = Select-EnumType RemoteFxResoultion -default $RFXResolution
                                          $RFXM = [int](Read-host "Please enter the new Number of monitors - or nothing to leave it as $RFXMonitors")
                                          if ($RFXM -eq 0) {$RFXM = $RFXMonitors }
                                          
                                          $vmRFX = Set-VMRemoteFXController -Confirm -VM $vm -Monitors $RFXM -Resolution $RFXResolution 
                                          $null = read-host "Press [enter] to continue"}
                    }
                    
                    else  {$null = read-host "You can configure RemoteFX only when the VM is stopped.`nPress [enter] to continue"}         
                 }   
              19 { if ($vm.EnabledState -eq [vmstate]::Stopped) {
                       if ((($vmNic | where {$_.type -eq "synthetic"} | measure-object).count -lt 8) -and (($vmnic | where {$_.type -eq "emulated"} | measure-object).count -lt 4) )
                            {$legacy = [boolean]( select-item -TextChoices @("&Synthetic / VMbus NIC","&Emulated / Legacy NIC") -caption "Which type of Network Interface Card ?" -default 0 )}
                       else {$legacy =  (($vmnic | where {$_.type -eq "emulated"} | measure-object).count -lt 4)}
                       Write-host "Please select a new switch for the NIC" 
                       $switch = Select-VMSwitch -Server $Vm.__server 
                       $nic = Add-VMNIC -VM $vm -legacy:$legacy -Virtualswitch $Switch -Confirm
                       $vmnic = Get-VMNic $vm
                   }
                   else  {$null = read-host "You can add hardware only when the VM is stopped.`nPress [enter] to continue"}         
                 }
{($_ -ge 20)`
-and $_ -lt 30}  { $nic = $vmNic[($_ -20)]
                   if ($vm.EnabledState -eq [vmstate]::Stopped) { $action = select-item -TextChoices @("&Connect to a different network", "Change &MAC", "&Delete NIC") -Caption "What do you want to do:" -default 0 }
                   else                                         { $action = 0 ; Write-host "You can delete or change the MAC address of a NIC only when the VM is stopped"}
                   switch ($action) {
                        0 { Write-host "Please select a new switch for the NIC" 
                            $switch = Select-VMSwitch -Server $nic.__server 
                            Set-VMNICSwitch -nic $nic -Virtualswitch $switch -Confirm | out-null
                          }  
                        1 { Set-VMNICAddress -Nic $nic -mac (Read-host "Please enter the new MAC address") -Confirm  }
                        2 { Remove-VMNIC -Nic $nic -confirm}   
                    }
                    $vmnic = Get-VMNic $vm
                 }
             30  { if (-not $VMCG) {if (select-item -TextChoices @("&No" ,"&Yes") -Caption "Configuring Clustering" -message "Do you want to configure this virtual machine for High Availablity ?" ) {
                                        Add-ClusterVirtualMachineRole -Name $vm.ElementName -VirtualMachine $vm.ElementName -Cluster $vm.__SERVER | out-null
                                        $VMCG = Get-vmClusterGroup $vm
                   }}
                   Else {  $RunningNodes = Get-Clusternode -cluster $vm.__SERVER | Where-Object {$_.state -eq "Up" -and $_.name -ne $VMCG.OwnerNode}
                           if ($RunningNodes -and $VMCG.state -eq "Online") {if (select-item -TextChoices @("&No" ,"&Yes") -Caption "Configuring Clustering" -message "Do you want to Live migrate virtual machine to another node ?" ) {
                                                                             $destination = (Select-list $runningNodes -property Name)
                                                                             move-vm -VM $vm -Destination $destination | out-null ; Start-Sleep -Seconds 5 ; return}}
                           if ($RunningNodes -and $VMCG.state -eq "Offline") {if (select-item -TextChoices @("&No" ,"&Yes") -Caption "Configuring Clustering" -message "Do you want move this virtual machine to another node ?" ) {
                                                                             $destination = (Select-list $runningNodes -property Name)
                                                                             Move-ClusterGroup -Cluster $vm.__SERVER -name $vmcg -node $destination | out-null ; Start-Sleep -Seconds 5 ; return} }                                                 
                           if (-not $runningNodes) {Read-host "There are no nodes available to take this VM.`nPress [Enter] to Continue"} 
                           }
                                                          
                 } 
             40  {$vm.get()
                  $refreshneeded = $true
                  if ($VMCG) {Sync-vmClusterConfig -vm $vm -force | out-null}
                 }
          }} 
    } while ($selection -le 50) }           
}
