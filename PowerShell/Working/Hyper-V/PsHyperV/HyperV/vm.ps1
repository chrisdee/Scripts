

Function Export-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM , 
        
        [parameter(Mandatory = $true)]
        [string]$Path, 
        
        [ValidateNotNullOrEmpty()]
        $Server=".",         #May need to look for VM(s) on Multiple servers
        [switch]$CopyState,  
        [switch]$Wait, 
        [Switch]$Preserve, 
        $PSC, 
        [switch]$Force
    )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM = (Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | Foreach-Object  {export-vm  -VM $_ @PSBoundParameters}}        
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {  
            if ($force -or $psc.shouldProcess($vm.ElementName ,$lstr_ExportVm)) {  
                $VSMgtSvc=Get-WmiObject -ComputerName $VM.__server  -Namespace $HyperVNamespace  -Class "MsVM_virtualSystemManagementService"
                if ( ($VSMgtSvc.ExportVirtualSystem($VM.__path,($CopyState.Ispresent),$path)    | Test-wmiResult -wait:($wait -or $preserve) -JobWaitText ($lstr_ExportOfVm -f $vm.elementName)`
                            -SuccessText ($lstr_ExportOfVmSuccess -f $vm.elementName , $path) -failText ($lstr_ExportOfVmFailure -f $vm.elementName , $path) ) -eq [returnCode]::ok) {
                        if ($Preserve) {
                                   Write-Progress -activity ($lstr_ExportOfVm -f $vm.elementName) -Status $lstr_ExportZip
                                   Add-ZIPContent "$path\$($vm.elementname)\importFiles.zip" "$path\$($vm.elementname)\config.xml","$path\$($vm.elementname)\virtual machines"
                                   if (Get-ChildItem "$path\$($vm.elementname)\snapshots") {Add-ZIPContent "$path\$($vm.elementname)\importFiles.zip" "$path\$($vm.elementname)\snapshots"} 
                                   Write-Progress -activity ($lstr_ExportOfVm -f $vm.elementName) -Status $lstr_ExportZip -Completed
                       }
                } 
            }
         }
    }
}




Function Get-VM 
{# .ExternalHelp  MAML-VM.XML
    param(
        [parameter(ValueFromPipeLine = $true)] [ValidateNotNullOrEmpty()][Alias("VMName")]
        $Name = "%", 
        
        [ValidateNotNullOrEmpty()]
        $Server = ".",  #May need to look for VM(s) on Multiple servers
        [Switch]$Suspended, 
        [switch]$Running, 
        [switch]$Stopped
    ) 
    Process { 
        if ($Name.count -gt 1  ) {[Void]$PSBoundParameters.Remove("Name") ;  $Name | ForEach-object {Get-VM -Name $_ @PSBoundParameters}}
        if ($name -is [String]) {
            # In case people are used to the * as a wildcard...
            $Name = $Name.Replace("*","%")
            # Note: in V1 the test was for caption like "Virtual%" which did not work in languages other than English.
            # Thanks to Ronald Beekelaar -  we now test for a processID , the host has a null process ID, stopped VMs have an ID of 0. 
            $WQL = "SELECT * FROM MSVM_ComputerSystem WHERE ElementName LIKE '$Name' AND ProcessID >= 0"
            if ($Running -or $Stopped -or $Suspended) { 
                $state = "" 
                if ($Running)   {$State += " or enabledState = " + [int][VMState]::Running   }
                if ($Stopped)   {$State += " or enabledState = " + [int][VMState]::Stopped   }
                if ($Suspended) {$State += " or enabledState = " + [int][VMState]::Suspended }
                $state = $state.substring(4)  
                $WQL += " AND ($state)" 
            } 
            Get-WmiObject -computername $Server -NameSpace $HyperVNamespace -Query $WQL | Add-Member -MemberType ALIASPROPERTY -Name "VMElementName" -Value "ElementName" -PassThru 
        }
        elseif ($name.__class)  {
            Switch ($name.__class) {
               "Msvm_ComputerSystem"                {$Name}
               "Msvm_VirtualSystemSettingData"      {get-wmiobject  -computername $Name.__SERVER -namespace $HyperVNamespace  -Query "associators of {$($name.__path)} where resultclass=Msvm_ComputerSystem"}   
               Default                              {get-wmiobject  -computername $Name.__SERVER -namespace $HyperVNamespace  -Query "associators of {$($Name.__path)} where resultclass=Msvm_VirtualSystemSettingData" | 
                                                          ForEach-Object {$_.getRelated("Msvm_ComputerSystem")} | Select-object -unique  }
            }
        }
    }
}


Function Get-VMBuildScript
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true)]
        $VM = "%"  ,    
        
        [ValidateNotNullOrEmpty()]
        $Server="."  #May need to look for VM(s) on Multiple servers
    )
    Process { 
        if ($VM -is [String]) {$VM = Get-VM -Name $VM -server $Server }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Get-VMBuildScript -VM $_ @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem')  {
              ("`n`n#Build Script for {0} created {1}`n" -f $VM.elementName, (Get-Date) )
              ("{0} = New-VM                  -Name '{1}' " -f '$VM' , $VM.elementName)
              $VMcpu = Get-VMCPUCount $VM
              ("Set-VMCPUCount                -VM   {0}  -CPUCount {1} -Limit {2} -Reservation {3} -Weight {4} " -f '$VM', $VMcpu.VirtualQuantity ,$VMcpu.Limit , $VMcpu.Reservation , $VMcpu.weight)
              $VMmem = Get-VMMemory -VM $VM
              if ($VMmem.DynamicMemoryEnabled) {("Set-VMMemory  -dynamic        -VM   {0}  -Memory   {1} -Limit {2} -Weight {3} -bufferPercentage {4}" -f '$VM', $VMmem.VirtualQuantity, $VMmem.Limit , $VMmem.Weight, $VMmem.TargetMemoryBuffer)} 
              else                             {("Set-VMMemory                  -VM   {0}  -Memory   {1}"                                              -f '$VM', $VMmem.VirtualQuantity) }
              $VMsd  = Get-VMSettingData -VM $VM  
              $VSGSD = get-wmiobject  -computername $VM.__SERVER -namespace $HyperVNamespace  -Query "associators of {$($VM.__path)} where resultclass=MsVM_VirtualSystemGlobalSettingData"
              ("Set-VM                        -VM   {0}  -BootOrder {1} -notes '{2}' -AutoRecovery {3} -AutoShutDown {4} -autoStartup {5} -AutoDelay {6} " -f '$VM' ,
                     ($VMSD.BootOrder  | foreach-object -begin {$bootDevices=""} -process {[string]$bootdevices += ([bootmedia]$_).tostring() +","} -end {$bootDevices -replace ",$","" }) ,
                     $VMsd.notes ,  [recoveryAction]$VSGSD.AutomaticRecoveryAction , [ShutdownAction]$vsgsd.AutomaticShutdownAction , [StartupAction]$vsgsd.AutomaticStartupAction,
                     [System.Management.ManagementDateTimeconverter]::ToTimeSpan($VSGSD.AutomaticStartupActionDelay).Seconds)


              Get-VMNIC -VM $VM | forEach-object {
                  if ($_.elementName -match "Legacy") {('$NIC = Add-VMNIC              -VM   {0}  -legacy'   -f '$VM')}
                  else                                {('$NIC = Add-VMNIC              -VM   {0}  -GUID {1}' -f '$VM', $_.VirtualSystemIdentifiers[0]) }    
                  if ($_.address -ne "000000000000")  {('Set-VMNICAddress              -NIC  $NIC -MAC {0}' -f $_.address ) }
                  $switch = (Get-VMNICSwitch ($_)).elementname
                  if ($switch)                        {('Set-VMNICSwitch               -NIC  $NIC -VirtualSwitch "{0}"' -f $switch) }
              }
              Get-VMSerialPort -VM $VM | foreach-Object {if ($_.connection[0]) {"Set-VMSerialport             -VM   {0}  -PortNumber {1} -connection {2}"  -f '$VM' , $_.elementName.replace("com ",""), $_.connection[0]}}
              Get-VMFloppyDisk -VM $VM | foreach-object {("Add-VMFloppyDisk              -VM   {0}  -Path {1}" -f '$VM', $_.Connection[0])}
              Get-VMDiskController -VM $VM -SCSI | foreach-object {
                  ('$DC = Add-VMSCSIController -VM   {0}  -name "{1}"' -f '$VM', $_.elementName)
                  Get-VMDriveByController -Controller $_ | foreach-object {
                      IF   ($_.ResourceSubType -match "Synthetic") {
                          ('$Drv = Add-VMDrive              -ControllerRASD $DC -LUN {0} ' -f $_.address )
                          Get-VMDiskByDrive -Drive $_ | foreach-object {if ($_.connection) {
                              $p=$_.Connection[0] ; while ($p.toupper().EndsWith(".AVHD")) { $p=(Get-VHDInfo -vhdpath $p -Server $_.__server ).parentPath }
                              ('Add-VMDisk                     -DriveRASD $Drv -Path {0} ' -f  $P )
                          }}    
                      }
                      elseif ($_.ResourceSubType -match "Physical") {'Add-vmpassThrough -ControllerRASD $DC -LUN {0} -physicalDisk [wmi]''{1}''' -f $_.address , $_.HostResource[0]}
                  }     
              }
              Foreach ($ID in @(0,1)) {Get-VMDiskController -VM $VM -ide -ControllerID $ID | foreach-object {
                  Get-VMDriveByController -Controller $_ | foreach-object {
                  IF  ($_.ResourceSubType -match "Synthetic") {
                          ('$Drv = Add-VMDrive            -VM   {0}  -ControllerID {1} -LUN {2} -OpticalDrive:${3}' -f '$VM' , $ID , $_.address, ($_.elementName -notmatch "Hard"))
                          Get-VMDiskByDrive -Drive $_ | foreach-object {if ($_.connection) {
                              $p=$_.Connection[0] ; while ($p.toupper().EndsWith(".AVHD")) { $p=(Get-VHDInfo -vhdpath $p -Server $_.__server ).parentPath }
                              ('Add-VMDisk                    -Dri  $Drv -Path {0} -OpticalDrive:${1}' -f  $P , ($_.elementName -notmatch "Hard"))
                          }}
                  } 
                  elseif ($_.ResourceSubType -match "Physical") {'Add-vmpassThrough           -VM   {0}  -ControllerID {1} -LUN {2} -physicalDisk [wmi]''{3}''' -f '$VM' , $ID , $_.address , $_.HostResource[0]}
                          
                 }
              }}
              Get-VMIntegrationComponent $VM | Where-Object {$_.enabledstate -eq [VMstate]::Stopped} | ForEach-Object { "Set-VMIntegrationComponent -VM   {0} -componentName '{1}' -state [VMstate]::stopped" -f  '$VM',$_.elementName }
              Get-vmClusterGroup $vm | ForEach-Object {  "Add-ClusterVirtualMachineRole -Name {0} -VirtualMachine{1}" -f $_.name,$_.vmelementname }
       }
   }
} 


Function Get-VMClusterGroup 
{# .ExternalHelp  MAML-VM.XML
    param(
           [parameter(ValueFromPipeLine = $true)]
           $VM="%",           

           [ValidateNotNullOrEmpty()]
           $Server="."   #May need to look for VM(s) on Multiple servers
    )
    Process {    
        if (-not (get-command -Name Move-ClusterVirtualMachineRole -ErrorAction "SilentlyContinue")) { return} #Unlike the other cluster commands, no warning so it can be used as a test for HA VMs anywhere without a stream of messages.  
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -server $server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Get-vmClusterGroup -VM $_  @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            get-cluster -name $vm.__server | Get-clustergroup | where-object { Get-ClusterResource -input $_ | where-object {$_.resourcetype -like "Virtual Machine"} | Get-ClusterParameter -Name vmID | 
                where-object {$_.value -eq $vm.name}} | Add-Member -passthru -name "VMElementName" -MemberType noteproperty   -value $($vm.elementName) 
        }
    }
}
#get-vm | where { (((get-date).subtract($vm.ConverttoDateTime($vm.TimeOfLastConfigurationChange) ) ).totalminutes  -gt 60) -and (get-vmClusterGroup $_) } | Sync-vmClusterConfig
Function Get-VMHost
{# .ExternalHelp  MAML-VM.XML
    param(
        [parameter(ValueFromPipeline = $true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Domain=([ADSI]('GC://'+([ADSI]'LDAP://RootDse').RootDomainNamingContext))
    )   
    $searcher = New-Object directoryServices.DirectorySearcher($domain)
    $searcher.Filter = "(&(cn=Microsoft hyper-v)(objectCategory=serviceConnectionPoint))"
    # Find all matching service connection points in the container. Return 1 object for each, the name. 
    $searcher.FindAll() | ForEach-object {$_.Path.Split(",")[1] -Replace "CN=",""  }
} 


Function Get-VMSummary
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
           [parameter(ValueFromPipeline = $true)]
           $VM="%" ,
           
           [ValidateNotNullOrEmpty()]
           $Server="."   #May need to look for VM(s) on Multiple servers
         )         
    Process {
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Get-VMSummary -VM $_  @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') { 
            $VSMgtSvc=Get-WmiObject -computerName $Vm.__Server -NameSpace $HyperVNamespace  -Class "MsVM_virtualSystemManagementService" 
            $result=$VSMgtSvc.GetSummaryInformation( @( (Get-VMSettingData $vm ).__Path ) ,  @(0,1,2,3,4,100,101,102,103,104,105,106,107,108))
            if ($Result.ReturnValue -eq 0) {$result.SummaryInformation | foreach-object {
                 New-Object PSObject -Property @{      
                   "Host"             =  $VM.__server                   ;  "VMElementName"    =  $_.elementname
                   "Name"             =  $_.name                        ;  "CreationTime"     =  $_.CreationTime
                   "EnabledState"     =  ([vmstate]($_.EnabledState))   ;  "Notes"            =  $_.Notes
                   "CPUCount"         =  $_.NumberOfProcessors          ;  "CPULoad"          =  $_.ProcessorLoad
                   "CPULoadHistory"   =  $_.ProcessorLoadHistory        ;  "MemoryUsage"      =  $_.MemoryUsage
                   "GuestOS"          =  $_.GuestOperatingSystem        ;  "Snapshots"        =  $_.Snapshots.count
                   "Jobs"             =  $_.AsynchronousTasks           ;  "Uptime"           =  $_.UpTime
                   "UptimeFormatted"  =  $(if ($_.uptime -gt 0) {([datetime]0).addmilliseconds($_.UpTime).tostring("hh:mm:ss")} else {0} )
                   "Heartbeat"        =  $(if ($_.heartBeat) { [HeartBeatICStatus] $_.Heartbeat} else {$null} )
                   "FQDN"             =  ((get-vmkvp -vm $vm).FullyQualifiedDomainName)
        	       "IpAddress"        =  ((Ping-VM $vm).NetworkAddress)}
            }}
            else  {write-Warning ($lStr_GetSummaryInfo  -f [ReturnCode]$result.returnValue )}
        }
    }
}

Function Get-VMThumbnail
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [ValidateNotNullOrEmpty()]
        [int]$Width = 800, 
        
        [ValidateNotNullOrEmpty()]
        [int]$Height = 600,
        
        [string]$Path,

        [switch]$Passthru,
        
        [ValidateNotNullOrEmpty()]
        $Server = "."   #May need to look for VM(s) on Multiple servers
    )
    Process {
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Get-VMThumbnail -VM $_ @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            $VMSettings = Get-VMSettingData -vm $VM 
            if ($VMSettings -is [System.Management.ManagementObject])  {
                add-type -AssemblyName "System.Drawing" 
                $VSMgtSvc = Get-WmiObject -ComputerName $VM.__Server -Namespace $HyperVNamespace -Class $VirtualSystemManagementServiceName
                $result = $VSMgtSvc.GetVirtualSystemThumbnailImage( $VMSettings , $Width, $Height)    
                # MSDN implies that GetVirtualSystemThumbnailImaage is always synchronous so only test for OK, not for "background job started" 
                if ($result.returnValue -eq [ReturnCode]::OK)    {
                    if ($Result.ImageData -ne $null)     {    # Create a bitmap of the requested size in 16BPP format
                        $VMThumbnail = new-object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format16bppRgb565)
                        # Lock the System.Drawing.Bitmap into system memory (the rectangle is a structure specifying the portion to lock.)
                        $rectangle = new-object System.Drawing.Rectangle(0, 0, $Width, $Height)
                        $VMThumbnailBitmapData = $VMThumbnail.LockBits($rectangle, 
                                                                       [System.Drawing.Imaging.ImageLockMode]::WriteOnly, 
                                                                       [System.Drawing.Imaging.PixelFormat]::Format16bppRgb565
                                                                      )
                        # Since GetVirtualSystemThumbnailImage returns a byte[], we need to copy the bytes into the Bitmap object 
	    	            [System.Runtime.InteropServices.Marshal]::Copy($Result.ImageData,  0, $VMThumbnailBitmapData.Scan0, ($Width * $Height * 2))
                        # Now unlock it 
                        $VMThumbnail.UnlockBits($VMThumbnailBitmapData)
                   
                        # did user ask to save the thumbnail a file ?
                        if ($passthru)  { $VMThumbnail }
                        else {
                             $PNGPath = $path	
                             #if No path at all is provided, make the path the current directory
                             if ($PNGPath -eq "") {$PNGPath = $pwd}
                             #if the path is a directory add VMName.PNG to the end of it.
                             if (test-path $PNGPath -pathtype container) {$PNGPath = join-Path $PNGPath ($VMSettings.elementName + ".PNG") }
                             #if the path starts with ".\" add the current directory to the begining of it 
                             if ($PNGPath.StartsWith(".\")) {PNGPath= join-path $PWD PNGPath.Substring(2)  }
                             #If all we have is a file name add the current directory to the start of it 
                             $Folder = split-path $PNGPath
                             if ($folder -eq "" ) {$PNGPath  = join-Path $pwd $PNGPath }
                             # Allow for the folder being a relative path, and make it an absolute path 
                             else  {$PNGpath=$PNGpath.Replace($Folder , (resolve-path $folder)) }
                             #Allow for .PNG being omitted from the file name. 
                             if (-not $PNGpath.toUpper().endswith("PNG")) {$PNGPath = $PNGPath + ".PNG"}
                             # ...and save
                             $VMThumbnail.Save($PNGPath)
                        }
                   }
                }
	        else  { write-warning $lstr_VMJPEGNoImage }  
            }
        }
    }
}

Function Import-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
    
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName =$true,ValueFromPipeline =$true)][Alias("Fullname","Path","DiskPath")][ValidateNotNullOrEmpty()]
        [string[]]$Paths,
        
        [ValidateNotNullOrEmpty()]
        [String]$Server=".",   #Only import on one server 
        
        [switch]$ReimportVM, 
        [switch]$ReuseIDs,  
        [switch]$Wait, 
        [Switch]$Preserve,
        
        $PSC, 
        [switch]$Force
    )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        forEach ($Path in $Paths) {
            if ($server -eq ".") {$path = (Resolve-Path $path).path}
            if ($pscmdlet.shouldProcess(($lStr_ImportFrom -f $server))) {
                if ($Preserve) {Add-ZIPContent "$path\importFiles.zip" "$Path\config.xml","$path\virtual machines"
                                if (test-path "$path\$($vm.elementname)\snapshots") {Add-ZIPContent "$path\importFiles.zip" "$path\snapshots"}
                }  
                elseif ($reImportVM -and (test-path "$path\importFiles.zip")) {
                    Copy-ZipContent -Zipfile "$path\importFiles.zip" -path $path
                    remove-VM -VM $ReimportVM -Server $server -confirm
                }
                $VSMgtSvc=Get-WmiObject -ComputerName $server -Namespace $HyperVNamespace -Class "MsVM_virtualSystemManagementService"
                $Result=$VSMgtSvc.importVirtualSystem($path,(-not $ReuseIDs.Ispresent) )   
                If ($wait) {$job = test-wmijob $Result.Job  -wait -Description ($lstr_importFrom -f $path)
                           if ($job.jobState -eq 7) { Write-Verbose $lstr_ImportSuccess  }
                           else                     { Write-error   $Job.errorDescription }
                }           
                else       {Write-Verbose ([ReturnCode]$result.returnValue) 
                            $result.job 
                }
            }
        }
    } 
    
}




Function Invoke-VMShutdown
{# .ExternalHelp  MAML-VM.XML
   [CmdletBinding(SupportsShouldProcess=$True , ConfirmImpact='High' )]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [ValidateNotNullOrEmpty()]
        [string]$Reason = "Scripted",
        
        [ValidateNotNullOrEmpty()]
        $Server = ".",   #May need to look for VM(s) on Multiple servers

        [int]$ShutdownTimeOut , 
          
        $PSC, 
        [switch]$Force
    )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) { $VM = Get-VM -Name $VM -Server $Server }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Invoke-VMShutdown -VM $_  @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem')     {
            $Endtime=(get-date).addSeconds($ShutdownTimeOut)
            $ShutdownComponent = Get-WmiObject -ComputerName $VM.__Server -Namespace $HyperVNamespace `
                                               -Query "SELECT * FROM MSVM_ShutdownComponent WHERE SystemName='$($VM.Name)'"
	        if ($ShutdownComponent -ne $null) {
	            if ($force -or $psc.shouldProcess($vm.elementName,$lStr_VMShutdown)) {  
	         	    $result = $ShutdownComponent.InitiateShutdown($true, $Reason)
		            if   ($result.ReturnValue -eq [ReturnCode]::OK) { 
                        write-verbose ($lstr_VMShutdownItitiated -f $VM.ElementName) 
                        Do { $vm.get()
                             $pending = ($vm.enabledState -ne [vmstate]::stopped -and ((get-date) -lt $endTime) )
                             if ($Pending) {write-progress -activity $Lstr_VMHeartBeatWaiting -Status $vm.elementname -Current ([vmState]$vm.enabledState)}
                             start-sleep 5
                           } while ($Pending )
                        write-progress -activity $Lstr_VMShutDownWaiting -Status $vm.elementname -Completed
                    }
        		    else {Write-error -message ($lstr_VMShutdownFailed -f $VM.ElementName) -Category InvalidResult -ErrorId $result.returnValue    }
                }
            }
	        else {Write-warning ($lstr_VMShutdownNoIC -f $vm.name)}
        }
    }
}


Function Move-VM 
{# .ExternalHelp  MAML-VM.XML
   [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [parameter(ValueFromPipeLine = $true)]
        $VM="%",
        
        [string]$Destination ,
        
        [ValidateNotNullOrEmpty()]
        $Server = ".",
        
        $PSC,
        [switch]$Force
    )
    process {
        if (-not (get-command -Name Move-ClusterVirtualMachineRole -ErrorAction "SilentlyContinue")) {Write-warning "Cluster commands not loaded. Import-Modue FailoverClusters and try again" ; return}
        if ($psc -eq $null)   {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -server $server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Move-VM -VM $_  @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            $VMClusterGroup = Get-vmClusterGroup -vm $vm
            if  ($vmclusterGroup.State -ne "online") {Write-warning "$($vm.elementName) is either not a Highly available VM, or is not on-line" ; return}
            if (-not $destination) {$Destination = (Get-Clusternode -cluster $VM.__server | Where-Object {$_.state -eq "up" -and $_.name -ne $vmclusterGroup.ownernode.name} | Select-Object -first 1).name }
            if ($force -or $psc.shouldProcess(($lStr_VirtualMachineName -f $vm.elementName ), ($lstr_MigrateTarget   -f $destination))) {
	            Move-ClusterVirtualMachineRole -Node $destination -inputobject $vmclusterGroup |  
			            Add-Member -name "Origin"        -MemberType "Noteproperty" -Value $vm.__server    -passthru | 
                        Add-Member -name "VmElementName" -MemberType "Noteproperty" -Value $vm.elementName -passthru  

            } 
        }
    }
}
#$vmMoveResults = (get-vm -Running | move-vm -force) 


Function New-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory = $true, ValueFromPipeLine = $true)][ValidateNotNullOrEmpty()]
        [string[]]$Name,   
    
        [string]$Path,
        
        [ValidateNotNullOrEmpty()] 
        [string]$Server = "." #Only allow VMs to be created on a single server
    )
    Process {
        $VSMgtSvc = Get-WmiObject -ComputerName $Server -Namespace $HyperVNamespace -Class "MSVM_VirtualSystemManagementService"
        $name | forEach-Object {
            $GlobalSettingsData             = ([WMIClass]"\\$Server\Root\Virtualization:MSVM_VirtualSystemGlobalSettingData").CreateInstance()
            $GlobalSettingsData.ElementName = $_
            if ($Path -is [string])       { $GlobalSettingsData.ExternalDataRoot = $Path }
            if ($pscmdlet.shouldProcess($_,($lstr_VMCreating -f $Server))) {  
	            $result = $VSMgtSvc.DefineVirtualSystem($GlobalSettingsData.GetText([System.Management.TextFormat]::WmiDtd20), $null, $null)
                
                if ( ($Result | Test-wmiResult -wait:$wait -JobWaitText (($lstr_VMCreating -f $Server) + $_)`
                                                           -SuccessText ($lstr_VMCreationSuccess  -f $_,$server) `
                                                           -failText ($lstr_VMCreationFailed   -f $_,$server) ) -eq [returnCode]::ok) {
                     [WMI]$result.DefinedSystem | Add-Member -MemberType ALIASPROPERTY -Name "VMElementName" -Value "ElementName" -PassThru
                }
            }
        }
    }
}

Function New-VMConnectSession
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding()]
    Param([parameter(Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()]
           $VM,        
          
           [parameter()][ValidateNotNullOrEmpty()] 
           $Server = "."   #May need to look for VM(s) on Multiple servers
          )
    process {
        # Check Windows edition, and look for the EXE before we run it...
        if (Test-Path env:PROCESSOR_ARCHITEW6432 ) {$vmConnectPath = (join-path $Env:ProgramW6432 "Hyper-V\VMconnect.exe")}
        else                                       {$vmConnectPath = (join-path $Env:ProgramFiles "Hyper-V\VMconnect.exe")}
        if ( ((Get-Itemproperty -path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion").editionID -notmatch "core|hyper") -and  	    
             (Test-Path $vmConnectPath))   { 
            if ($VM -is [String]) { $VM = Get-VM -Name $VM -Server $Server }
            if ($VM.count -gt 1 )  { $VM | Foreach-object {New-VMConnectSession -VM $_ -Server $Server}  }
            
            if ($vm.__CLASS -eq 'Msvm_ComputerSystem') { (Start-Process -PassThru -FilePath $vmConnectPath -ArgumentList "$($Vm.__Server) -G $($VM.Name)").Id }
        }
        Else { Write-Error -message $lStr_VMConnectInvalidSystem -Category invalidoperation }
    }
}


Function Ping-VM
{# .ExternalHelp  MAML-VM.XML
    Param(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)] 
    $VM , 
    
    [ValidateNotNullOrEmpty()]
    $Server=".",   #May need to look for VM(s) on Multiple servers
    
    [Switch]$UseIP4Address,
    [Switch]$UseIP6Address
    ) 
    
    Process {
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 )  {$VM | foreach-Object {Ping-VM $_ -Server $Server} }
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') { 
            if ($VM.EnabledState -ne $vmstate["running"]) {
                $vm | Select-object -property @{Name="VMName"; expression={$_.ElementName}}, 
                                              @{Name="FullyQualifiedDomainName"; expression={$null}} , 
                                              @{name="NetworkAddress"; expression={$null}} ,
                                              @{Name="Status"; expression={"VM {0}" -f [vmstate]$_.EnabledState } }
            }            
            else {
                $vmkvp =(Get-VMKVP $VM)
                $query = $null 
                if     ($UseIP6Address -and $vmkvp.NetworkAddressIPv6)      {$query=($vmkvp.NetworkAddressIPv6 -split "%")[0]  + "'"}
                Elseif ($UseIP4Address -and $vmkvp.NetworkAddressIPv4)      {$query= $vmkvp.NetworkAddressIPv4       +           "' and recordRoute=1"}
                elseif (                    $vmKvp.fullyQualifiedDomainName){$query= $vmKvp.fullyQualifiedDomainName +           "' and recordRoute=1 and ResolveAddressNames = True"}
                if ($query -eq $null) {
                    $vm | Select-object -property @{Name="VMName"; expression={$vm.ElementName}},
                                                  @{Name="FullyQualifiedDomainName"; expression={$null}} , 
                                                  @{name="NetworkAddress"; expression={$null}} ,
                                                  @{Name="Status"; expression={$lstr_NoFQDN }} 
                }           
                else {
                 write-debug "will attempt to WMI PING  where Address='$query"
                       Get-WmiObject -Namespace "root/cimV2" -query ("Select * from  Win32_PingStatus where Address='" + $query)  |
                       Select-object -property @{Name="VMElementName"; expression={$vm.ElementName}},
                                               @{Name="FullyQualifiedDomainName"; expression={$vmKvp.fullyQualifiedDomainName}} , 
                                               @{name="NetworkAddress"; expression={$_.ProtocolAddress}} , ResponseTime , TimeToLive , StatusCode , 
                                               @{Name="Status"; expression={if  ($_.PrimaryAddressResolutionStatus -eq 0) { $LHash_PingStatusCode[[int]$_.statusCode]} 
                                                                            else {  $lstr_FQDNNotResolved }}}
               }
            }
        }
    }    
}


Function Remove-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [ValidateNotNullOrEmpty()]
        $Server = ".",  #May need to look for VM(s) on Multiple servers
        [switch]$wait,
        $PSC, 
        [switch]$Force
        )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [string]) { $VM = Get-VM -Name $VM -Server $Server }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-Object  {Remove-VM -VM $_  @PSBoundParameters}}        
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem'){
            $VSMgtSvc = Get-WmiObject -ComputerName $vm.__Server -Namespace $HyperVNamespace -Class "MSVM_VirtualSystemManagementService"
            if ($force -or  $psc.shouldProcess($vm.ElementName,$LStr_RemoveVMAction) ) {  
                if (get-module failoverClusters -ErrorAction silentlycontinue) {Get-vmClusterGroup $vm | Remove-ClusterGroup -RemoveResources -force}
                $VSMgtSvc.DestroyVirtualSystem( $VM.__Path ) | Test-wmiResult -wait:$wait -JobWaitText ($LStr_RemoveVMDescription -f $VM.ElementName)`
                            -SuccessText ($LStr_RemoveVMSuccess -f $vm.elementName) -failText ($LStr_RemoveVMFailure -f $VM.ElementName)  
           }
        }
    }   
}


Function Save-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [ValidateNotNullOrEmpty()]
        $Server = ".",      #May need to look for VM(s) on Multiple servers        
        [Switch]$Wait,
        $PSC,
        [Switch]$Force
    ) 
    Process { if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
              Set-VmState -State ([VMState]::Suspended) @PSBoundParameters } 
}


Function Select-VM
{# .ExternalHelp  MAML-VM.XML
    param ([ValidateNotNullOrEmpty()]
           $Server=".",
           [Switch]$Multiple
    )
    Get-VM -Server $Server | 
        Sort-Object -property elementName | 
            Select-list -Property @(@{Label="VM Name"; Expression={$_.ElementName}}, 
                                  @{Label="State"; Expression={[VMState]$_.EnabledState}}) -multiple:$multiple
}


Function Set-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
      $VM, 
      
      [string]$Name, 
      [BootMedia[]]$BootOrder, 
      [String]$Notes, 
      [recoveryAction]$AutoRecovery, 
      [ShutDownAction]$AutoShutDown, 
      [Startupaction]$AutoStartup, 
      [Int]$AutoDelay, 
      [ValidateNotNullOrEmpty()]
      $Server=".",       #May need to look for VM(s) on Multiple servers
      $PSC, 
      [switch]$Force
    )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Set-VM -VM $_  @PSBoundParameters}} 
        if (($vm.__CLASS -eq 'Msvm_ComputerSystem') -or ($vm.__CLASS -eq 'Msvm_VirtualSystemSettingData')) {
            $VSMgtSvc=Get-WmiObject -computerName $VM.__server -NameSpace $HyperVNamespace -Class "MsVM_virtualSystemManagementService"
            if ($Name -or $notes -or $BootOrder) { 
                $VSSD=(Get-VMSettingData $VM)
	            if ($vm -eq $vssd) { $vm = Get-WmiObject -computername $vssd.__SERVER -namespace $HyperVNamespace -Query "select * from MSVM_Computersystem where name ='$($vssd.systemName)'"}
                if ($Name      )   { $VSSD.ElementName = $Name }
                if ($notes     )   { $VSSD.notes       = $Notes }
                if ($BootOrder )   {if   (($bootOrder | Group-Object | where-object {$_.count -gt 1}) -ne $null) {write-warning $Lstr_BootOrderDuplicate}
                                    else {$VSSD.BootOrder=$BootOrder} }
                if ($force -or $psc.shouldProcess($vm.ElementName , $Lstr_ModifyVMSettingaction)) {
                    $result = $VSMgtSvc.ModifyVirtualSystem($VM , $VSSD.GetText([System.Management.TextFormat]::WmiDtd20) )
                    if   ($Result.ReturnValue -eq [returnCode]::ok) { ($Lstr_ModifiedVMSettings -f $vm.elementname) } 
                    else  {write-error ($Lstr_ModifyVMSettingsFailed -f $vm.elementname) }
                }
            }
            If (($AutoRecovery) -or ($AutoShutDown ) -or ($AutoStartup ) -or ($AutoDelay ) ) {
                $VSGSD=get-wmiobject  -computername $vm.__SERVER -namespace $HyperVNamespace  -Query "associators of {$($vm.__path)} where resultclass=Msvm_VirtualSystemGlobalSettingData"
                if ($AutoRecovery ) {$VSGSD.AutomaticRecoveryAction     = $AutoRecovery }
                if ($AutoShutDown ) {$VSGSD.AutomaticShutdownAction     = $AutoShutdown }
                if ($AutoStartup  ) {$VSGSD.AutomaticStartupAction      = $autoStartup  }
                if ($AutoDelay    ) {$VSGSD.AutomaticStartupActionDelay = [System.Management.ManagementDateTimeconverter]::ToDmtfTimeInterval((New-TimeSpan -Seconds $AutoDelay)) }
                if ($force -or $psc.shouldProcess($vm.ElementName , $Lstr_ModifyVMGlobalSettingaction)) {
                     $result = $VSMgtSvc.ModifyVirtualSystem($VM , $VSGSD.GetText([System.Management.TextFormat]::WmiDtd20) )
                     if    ($Result.ReturnValue -eq [returnCode]::ok) { $Lstr_ModifiedVMGlobalSettings -f $vm.elementname } 
                     else  {write-error ($Lstr_ModifyVMGlobalSettingsFailed -f $vm.elementname)}
                }
            }
        }
    }
}


Function Set-VMHost
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$true , ConfirmImpact='High' )]
    param(
        [ValidateNotNullOrEmpty()]
        [String]$ExtDataPath , 
        
        [ValidateNotNullOrEmpty()]
        [String]$VHDPath , 
        
        [ValidatePattern('^[0-9|a-f]{12}$')]
        [String]$MINMac, 
        
        [ValidatePattern('^[0-9|a-f]{12}$')]
        [String]$MaxMac ,
        
        [String]$OwnerContact ,
        [String]$OwnerName,
        [parameter(ValueFromPipeline = $true)][ValidateNotNullOrEmpty()]
        $Server = ".",    
        $PSC,      
        [switch]$Force
    )
    Process {
         if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}

        if ($Server.count -gt 1 )  {[Void]$PSBoundParameters.Remove("Server") ;  $Server | ForEach-object {Set-VMHost -Server $_  @PSBoundParameters}} 
        if ($Server -is [String]) {
            $VSMSSD   = Get-WmiObject -ComputerName $Server -NameSpace $HyperVNamespace -Class "MsVM_VirtualSystemManagementServiceSettingData"
            $VSMgtSvc = Get-WmiObject -ComputerName $Server -Namespace $HyperVNamespace -Class "MSVM_VirtualSystemManagementService"
            if ($ExtDataPath)  { $VSMSSD.DefaultExternalDataRoot    = $extDataPath  } 
            If ($vhdPath )     { $VSMSSD.DefaultVirtualHardDiskPath = $VhdPath      } 
            if ($MINMac)       { $VSMSSD.MinimumMacAddress          = $MinMac       } 
            If ($MaxMac)       { $VSMSSD.MaximumMacAddress          = $MaxMac       } 
            if ($OwnerContact) { $VSMSSD.PrimaryOwnerContact        = $ownerContact }
            if ($OwnerName)    { $VSMSSD.PrimaryOwnerName           = $OwnerName    } 
            if ($force -or $psc.shouldProcess(($lStr_ServerName -f $VSMSSD.__server ), $lstr_ModifyServer)) {
                $result = ( ($VSMgtSvc.ModifyServiceSettings($VSMSSD.GetText([System.Management.TextFormat]::WmiDtd20) ) | Test-wmiResult -wait -JobWaitText ($lstr_ModifyServer)`
                                -SuccessText ($lstr_ModifyServerSuccess -f $VSMSSD.__server) -failText ($lstr_ModifyServerFailure -f $VSMSSD.__Server) ) )      
            }
            $VSMSSD.get()  
            $VSMSSD | Select-Object -property  Caption, DefaultExternalDataRoot, DefaultVirtualHardDiskPath,MinimumMacAddress, MaximumMacAddress ,PrimaryOwnerContact, PrimaryOwnerName
        }
    }
}

Function Set-VMState 
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [parameter(Mandatory = $true)]
        [VMState]$State, 
        
        [ValidateNotNullOrEmpty()]
        $Server = "." ,     #May need to look for VM(s) on Multiple servers
        [switch]$Wait,
        $PSC, 
        [switch]$Force
    )
    Process {
        if ( $psc -eq $null)    { $psc = $pscmdlet ;  if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc) }}   
        if ( $VM -is [String])  { $VM = $(Get-VM -Name $VM -Server $Server)}
        if ( $VM.count -gt 1 )   { [Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Set-VmState -VM $_ @PSBoundParameters}}
        if (($vm.__CLASS -eq 'Msvm_ComputerSystem') -and ($force -or $psc.shouldProcess($vm.ElementName, ($lStr_VMStateChanging -f $State)))) {     
                 $VM.RequestStateChange($State) | Test-wmiResult -wait:$wait -JobWaitText ($lStr_VMStateWaiting -f $State, $Vm.elementName ) `
                            -SuccessText ($lStr_VMStateChangeSuccess -f $Vm.elementName,$State)  -failText ($lStr_VMStateChangeFail -f $Vm.elementName,$state) 
        }
         
    }
}


Function Start-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param(
        [parameter(Mandatory = $true,ValueFromPipeline = $true)]
        $VM, 
        
        [ValidateNotNullOrEmpty()]
        $Server = ".",    #May need to look for VM(s) on Multiple servers
        [Switch]$Wait,
        
        [Alias("TimeOut")]
        [int]$HeartBeatTimeOut ,
        $PSC,
        [Switch]$Force
    ) 
    Process { if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
             [Void]$PSBoundParameters.Remove("HeartBeatTimeOut")  
             Set-VmState -State ([VMState]::Running) @PSBoundParameters
             if ($HeartBeatTimeOut)  {Test-VMHeartBeat -VM $VM -timeOut $HeartBeatTimeOut -Server $Server}   
    }
}



Function Stop-VM
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$True , ConfirmImpact='High')]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [ValidateNotNullOrEmpty()]
        $Server = "." ,      
        [Switch]$Wait,
        $PSC,
        [Switch]$force
    ) 
    Process { if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
               Set-VmState -State ([VMState]::Stopped) @PSBoundParameters }   
}


Function Test-VMHeartBeat
{# .ExternalHelp  MAML-VM.XML
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [Alias("TimeOut")]
        [int]$HeartBeatTimeOut ,
        
        [ValidateNotNullOrEmpty()]
        $Server = "."   #May need to look for VM(s) on Multiple servers
    )   
    Process {
        $Endtime=(get-date).addSeconds($HeartBeatTimeOut)
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | Foreach-object {Test-VmHeartbeat -VM $_ @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
             $Status= $lstr_VMHeartBeatICNotFound
             Do {
                 $hb = get-wmiobject  -computername $vm.__SERVER -namespace $HyperVNamespace  -Query "associators of {$($vm.__path)} where resultclass=Msvm_HeartbeatComponent" 
                 if ($hb -is [System.Management.ManagementObject]) {$status= [HeartBeatICStatus]$hb.OperationalStatus[0]}
                 $pending = ((get-date) -lt $endTime) -and ($status -ne [HeartBeatICStatus]::OK) 
                 if ($pending) {write-progress -activity $Lstr_VMHeartBeatWaiting   -Status $vm.elementname -Current $status; start-sleep 5}
             } while ($Pending)
             write-progress -completed -activity $Lstr_VMHeartBeatWaiting -Status $vm.elementname        
             $vm | select-object elementName, @{Name="Status"; expression={$status}}  
        }
   }
}
