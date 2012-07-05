

Function Add-VMNIC
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VM, 
        
        [Alias("switch","VirtualSwitchName")]
        $VirtualSwitch,           
        
        [ValidatePattern('^[0-9|a-f]{12}$')]
        [String]$MAC,
        [string]$GUID=("{"+[System.GUID]::NewGUID().ToString()+"}") ,
        
        [ValidateNotNullOrEmpty()] 
        $Server = ".",   #May need to look for VM(s) on Multiple servers

        [switch]$Legacy , 
        $PSC, 
        [switch]$Force
        )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM = (Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {add-VmNic -VM $_ @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            if ($Legacy)         {$NicRASD = NEW-VMRasd -server $vm.__Server -resType ([resourcetype]::EthernetAdapter) -resSubType 'Microsoft Emulated Ethernet Port' 
                                  $NicRASD.ElementName = $lstr_LegacyNicLabel
            }  
            else                 {$NicRASD = NEW-VMRasd -server $vm.__Server -resType ([resourcetype]::EthernetAdapter) -resSubType  'Microsoft Synthetic Ethernet Port' 
                                  $NicRASD.VirtualSystemIdentifiers=@($GUID)
                                  $NicRASD.ElementName = $lstr_VMBusNicLabel
            }     
            if ($mac )           {$nicRasD.address          = $mac
			                      $nicRasD.StaticMacAddress = $true
            }
            if ($virtualSwitch ) {$nicRasD.connection = [string](new-VmSwitchPort -virtualSwitch $virtualSwitch -Server $VM.__server)}
            add-VmRasd -rasd $NicRasd -vm $vm -PSC $psc -force:$force
       }
   }
}


Function Get-VMByMACAddress
{# .ExternalHelp  MAML-VMNetwork.XML
    Param( [parameter(Mandatory = $true, ValueFromPipeline = $true)]
           $MAC,
      
           [ValidateNotNullOrEmpty()] 
           $Server = "."  #May need to look for VM(s) on Multiple servers
    )
    process {
        if ($mac.count -gt 1 )  {$mac | ForEach-Object {Get-VMByMACaddress -mac $_ -server $server } }
        if ($Mac -is [string]) {$mac = $mac.replace("*","%")
          (@() +
           (get-wmiobject -ComputerName $Server -Namespace $HyperVNamespace -Query "Select * from MsVM_SyntheticEthernetPortSettingData  where address like '$mac'") + 
           (get-wmiobject -ComputerName $Server -Namespace $HyperVNamespace -Query "Select * from MsVM_EmulatedEthernetPortSettingData   where address like '$mac'")) | 
            ForEach-object {$_.getRelated("Msvm_VirtualSystemSettingData")} | ForEach-Object{ $_.getRelated("msvm_ComputerSystem") } | Select-Object -unique
        }

   }
}


Function Get-VMLiveMigrationNetwork
{# .ExternalHelp  MAML-VMNetwork.XML
    param(
        [parameter(ValueFromPipeLine = $true)][Alias("Cluster")][ValidateNotNullOrEmpty()] 
        $Server = "."
     )
    Process {
        if (-not (get-command -Name Move-ClusterVirtualMachineRole -ErrorAction "SilentlyContinue")) { Write-warning $lstr_noCluster  ; return }
        $Netorder= (Get-ClusterResourceType -Cluster $server -Name "virtual machine" | Get-ClusterParameter -Name migrationNetworkOrder).value.split(";")
        If ($netOrder) { foreach ($id in $netorder) {get-clusterNetwork -Cluster $server | where-object {$_.id -eq $id} }}
        Else {get-clusterNetwork | 
            where-object {(Get-ClusterResourceType -Cluster $server -Name "virtual machine" | 
                Get-ClusterParameter -Name migrationExcludeNetworks).value.split(";") -notcontains $_.id}}
    }
}


Function Get-VMNIC
{# .ExternalHelp  MAML-VMNetwork.XML    
    param(
        [parameter(ValueFromPipeline = $true)]
        $VM="%", 
     
        [ValidateNotNullOrEmpty()] 
        $Server = ".", #May need to look for VM(s) on Multiple servers

        [switch]$Legacy ,
        [switch]$VMBus)
    Process {     
        if ((-not ($legacy)) -and (-not ($VmBus)) ) {$vmbus = $legacy=$True}
        if ($VM -is [String])  {$VM=(Get-VM -Name $VM -Server $Server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object {Get-VmNic -VM $_  @PSBoundParameters}}
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            $vssd = Get-VMSettingData $vm 
            if ($legacy) {$vssd.getRelated("MsVM_EmulatedEthernetPortSettingData") |  
                          Add-Member -passthru -name "VMElementName" -MemberType noteproperty   -value $($vm.elementName) |
                          Add-Member -PassThru -name "SwitchName"    -MemberType Scriptproperty -value { (Get-VMnicSwitch -Nic $this).ElementName }
            }
            if ($vmbus)  {$vssd.getRelated("MsVM_SyntheticEthernetPortSettingData") | 
                          Add-Member -passthru -name "VMElementName" -MemberType noteproperty   -value $($vm.elementName) |
                          Add-Member -PassThru -name "SwitchName"    -MemberType Scriptproperty -value { (Get-VMnicSwitch -Nic $this).ElementName }
            }
        }
    }
}


Function Get-VMNICport
{# .ExternalHelp  MAML-VMNetwork.XML
    Param ( [parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $NIC
    ) 
    Process { if ($nic.connection) {[wmi]$nic.connection[0]} }
}


Function Get-VMNICSwitch
{# .ExternalHelp  MAML-VMNetwork.XML
    Param ( 
            [parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $NIC
          )
    Process {
        if ($NIC.count -gt 1  ) {$NIC | ForEach-object {Get-VMnicSwitch  -NIC $_ }} 
        if ($NIC.__CLASS -like "*EthernetPortSettingData") {
            if ($nic.Connection) {([WMI]$nic.Connection[0]).getRelated("Msvm_VirtualSwitch") }# Get-WmiObject -computerName $nic.__server -NameSpace $HyperVNamespace -Query "ASSOCIATORS OF {$($nic.Connection)} where resultclass = Msvm_VirtualSwitch" }
            else {$lstr_notConnected }
        }
    }
 
}


Function Get-VMNICVLAN
{# .ExternalHelp  MAML-VMNetwork.XML
    param  (  [parameter(Mandatory = $true, ValueFromPipeline = $true)]
              $NIC
    )
    
    process {  if ($NIC.count -gt 1 ) {[Void]$PSBoundParameters.Remove("NIC") ;  $NIC | ForEach-object {Get-VMNICVLAN -NIC $_ @PSBoundParameters}}
               if ($nic.connection) {(Get-WmiObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$($nic.connection[0])} where assocClass=msvm_bindsto" | 
                           foreach-object {Get-WmiObject -ComputerName $Nic.__Server  -Namespace $HyperVNamespace -q "associators of {$_} where assocClass=MSVM_NetWorkElementSettingData"}).accessVlan}
    }
}


Function Get-VMSwitch
{# .ExternalHelp  MAML-VMNetwork.XML    
    param(
        [parameter(ValueFromPipeline = $true)][Alias("Name")]
        [String]$VirtualSwitchName="%",
       
        [ValidateNotNullOrEmpty()] 
        $Server = "."    #Can query multiple servers for switches
        )
    process {
        $VirtualSwitchName=$VirtualSwitchName.replace("*","%")
        Get-WmiObject -computerName $server -NameSpace  $HyperVNamespace   -query "Select * From MsVM_VirtualSwitch Where elementname like '$VirtualSwitchname' "
    }
}

Function New-VMExternalSwitch
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$True , ConfirmImpact='High')]
    param ( 
        [ValidateNotNullOrEmpty()][Alias("Name")]
        [string]$VirtualSwitchName,           
            
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]$ExternalEthernet,
        [int]$Ports=1024, 
            
        [ValidateNotNullOrEmpty()] 
        [String]$Server=".",  #Only allow a Switch to be created on a single server
        [switch]$Force
    )
    Process {
        if ($ExternalEthernet -is [String]) {
              $ExternalEthernet=(Get-WmiObject -computername $server -NameSpace  $HyperVNamespace `
                                              -query "Select * from Msvm_ExternalEthernetPort where Name like '$ExternalEthernet%' " `
                                |  sort-object -property name | select-object -first 1)
        }
        if ($ExternalEthernet.__CLASS -eq 'Msvm_ExternalEthernetPort') {
            If  (-not $virtualSwitchName ) {$virtualSwitchName=$ExternalEthernet.name + " Virtual NIC"}
  	    if ($force -or $pscmdlet.shouldProcess($ExternalEthernet.name, $lStr_ExternalNictoSwtich)) {
                $Switch       = New-VMPrivateSwitch $virtualSwitchName $ports $server -force:$force
                if ($Switch) { 
                   $intSP    = New-VMSwitchPort -virtualSwitch $switch -name ($virtualSwitchName + "_InternalPort") 
                   $ExtSP    = New-VMSwitchPort -virtualSwitch $switch -name ($virtualSwitchName + "_ExternalPort")
                   if ($intSP -and $extSP) { 
                       $SwitchMgtSvc = Get-WmiObject -ComputerName $Server -NameSpace $HyperVNamespace -Query "Select * From MsVM_VirtualSwitchManagementService"
                       $Result       = $SwitchMgtSvc.SetupSwitch($ExtSp, $intSp, $ExternalEtherNet.__path, $virtualSwitchName, $virtualSwitchName)
                  
                       if ( ($result | Test-wmiResult -wait -JobWaitText ($lstr_ExternalSwitchSetup  -f $virtualSwitchName) `
                                                      -SuccessText ( $lstr_ExternalSwitchSetupSuccess -f $virtualSwitchName,$server) `
                                                      -failText ($lstr_ExternalSwitchSetupFailure -f $virtualSwitchName,$server )) -eq [returnCode]::ok) {$switch}
                    }
                }
            }               # if port or switch creation causes an error that will be seen in those functions 
        }    
        else                {Write-warning  $lstr_NoNICProvided }
   }
}  


Function New-VMInternalSwitch
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param ( [parameter(Mandatory = $true,  ValueFromPipeLine = $true)][Alias("Name")]
            [ValidateNotNullOrEmpty()][string]$VirtualSwitchName,
            [int]$Ports=1024, 
            
            [ValidateNotNullOrEmpty()] 
            [string]$Server=".",   #Only allow a Switch to be created on a single server
            [Switch]$force
    )
    Process {         
        $Switch       =  New-VMPrivateSwitch -virtualSwitchName $virtualSwitchName -ports $ports -server $server -psc $pscmdlet -force:$force
        if ($Switch) {
            $intSP        =  New-VMSwitchPort -virtualSwitch $switch # -name ($virtualSwitchName + "_InternalPort") 
            $SwitchMgtSvc =  Get-WmiObject  -ComputerName $Server  -NameSpace $HyperVNamespace -Query "Select * From MsVM_VirtualSwitchManagementService" 
            $result=$SwitchMgtSvc.CreateInternalEthernetPortDynamicMac($virtualSwitchName,$virtualSwitchName)
            if ($Result.ReturnValue -eq 0) { 
                write-Verbose $lstr_CreateVirtualNICSuccess  
                $endPoint = ([wmi]$result.CreatedInternalEthernetPort).getrelated("Msvm_SwitchLANEndpoint") #(Get-WmiObject  -NameSpace $HyperVNamespace -Query "ASSOCIATORS OF {$($result.CreatedInternalEthernetPort)} where resultClass = Msvm_SwitchLANEndpoint")
                $intSP    = New-VMSwitchPort -virtualSwitch $switch -name ($virtualSwitchName + "_InternalPort") 
                if ($intSP -and $endPoint) {
                    $result=$SwitchMgtSvc.ConnectSwitchPort($intSP, $endPoint )
	                if ($Result.returnValue -eq 0) {write-Verbose $lstr_boundInternalEthernetSuccess  
                                                $Switch
                    }
                }
                else  {write-warning ($lstr_boundInternalEthernetFailure -f $Result.returnValue) }
             }
             else     {Write-warning ($lstr_CreateVirtualNICFailed       -f $Result.returnValue) }
         }
     }
}


Function New-VMPrivateSwitch 
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param ( [parameter(Mandatory = $true , ValueFromPipeLine = $true)][Alias("Name")]
            [ValidateNotNullOrEmpty()][string]$VirtualSwitchName,
            
            [int]$Ports=1024, 
            
            [ValidateNotNullOrEmpty()][string]$Server=".",  #Only allow a Switch to be created on a single server
            $PSC, 
            [switch]$Force
    )
    Process {
        if ($psc -eq $null) { $psc = $pscmdlet }
        $SwitchMgtSvc =  Get-WmiObject  -ComputerName $Server -NameSpace $HyperVNamespace -Query "Select * From MsVM_VirtualSwitchManagementService" 
        if ($force -or $psc.shouldProcess(($lStr_VirtualMachineName -f $vm.elementName ), ($lStr_SwitchCreating -f $virtualSwitchName ))) {
            $result=$SwitchMgtSvc.CreateSwitch( [system.guid]::NewGuid() , $virtualSwitchName , $Ports  ,$null )
            if ( ($result | Test-wmiResult -wait:$wait -JobWaitText ($lStr_SwitchCreating  -f $virtualSwitchName) `
                                           -SuccessText ( $lStr_SwitchCreatingSuccess -f $virtualSwitchName,$server) `
                                           -failText ($lStr_SwitchCreatingFailure -f $virtualSwitchName,$server )) -eq [returnCode]::ok) {
                [wmi]$Result.CreatedVirtualSwitch
            }
        }   
    }
}



Function New-VMSwitchPort
{# .ExternalHelp  MAML-VMNetwork.XML
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $VirtualSwitch ,
        
        [String]$Name=([System.GUID]::NewGUID().ToString()),   
        
        [ValidateNotNullOrEmpty()] 
        [string]$Server = "."    #Only allow a Switch to be created on a single server
    ) 
    # Intentionally Does not support Should process as it should not be run from the command line. 
    if ($Virtualswitch -is [String]) {$Virtualswitch=Get-vmSwitch -name $virtualSwitch -server $server}
    if ($Virtualswitch.__class -eq 'Msvm_VirtualSwitch')  {
        $SwitchMgtSvc=(Get-WmiObject -computerName $Virtualswitch.__server -NameSpace  $HyperVNamespace   -Query "Select * From MsVM_VirtualSwitchManagementService")
        $result = $SwitchMgtSvc.CreateSwitchPort($Virtualswitch.__Path, $name, $name) 
        if ($result.returnValue -eq 0) {@($result.CreatedSwitchPort) 
                                        write-verbose ($lstr_CreateSwitchPortSuccess -f $virtualSwitch.elementName )
        }
        else                           {write-error   ($lStr_CreateSwitchPortFailure -f $virtualSwitch.elementName, $Result)}
    }
}


Function Remove-VMNIC
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory = $true ,  ValueFromPipeline = $true)]
        $NIC,
        
        $PSC, 
        [switch]$Force,
        
        $VM, $Server #VM no longer required, but preserved for compatibility with V1 
    )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($NIC.count -gt 1  ) {[Void]$PSBoundParameters.Remove("NIC") ;  $NIC | ForEach-object {Remove-VMNIC  -NIC $_  @PSBoundParameters}}
        if ($nic.__CLASS -like "*EthernetPortSettingData")  {remove-VMRasd -rasd $NIC -PSC $psc -force:$force }
            # note: In V1 the switch port was removed before removing the NIC, but this is done automatically. 	        
    }
}            


Function Remove-VMSwitch
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true , ConfirmImpact='High' )]
    param ( [parameter(valueFromPipeline = $true , Mandatory = $true)][ValidateNotNullOrEmpty()][Alias("name","VirtualSwitchName")]
            $VirtualSwitch,
            [int]$Ports=1024, 
            
            [ValidateNotNullOrEmpty()] 
            [string]$Server=".",   #Only allow one switch at once
            $PSC, 
            [Switch]$Force
    )
    process{
        if ($psc -eq $null)    { $psc = $pscmdlet }   
        if ($virtualSwitch -is [String]) {$virtualSwitch=get-vmswitch -server $server -VirtualSwitchName $virtualSwitch}
        if ($virtualSwitch.__CLASS -eq 'Msvm_VirtualSwitch') {
            $SwitchMgtSvc = Get-WMIObject -computername $server -namespace $HyperVNamespace -Query "select * from MSVM_VirtualSwitchManagementService"   
            $intSP        = Get-WmiObject -computername $server -Namespace $HyperVNamespace -Query "select * from msvm_vlanendpoint where elementName = '$($VirtualSwitch.ElementName)_InternalPort' "
            $ExtSP        = Get-WmiObject -computername $server -Namespace $HyperVNamespace -Query "select * from msvm_vlanendpoint where elementName = '$($VirtualSwitch.ElementName)_ExternalPort' "
            if ($force -or $psc.shouldProcess($virtualSwitch.elementname, $Lstr_DeleteVirtualSwtich)) {  
                if     ($expSP)    { $Result = $SwitchMgtSvc.TeardownSwitch($extSP,$intSP)   }
                elseif ($intSP)    { $result = remove-VMSwitchNIC -server $server -name $VirtualSwitch.ElementName -psc $psc -force:$true}
                $result = $SwitchMgtSvc.DeleteSwitch($virtualSwitch) 
                [returnCode]$result.returnValue
            }  
        }
    }
}

Function Remove-VMSwitchNIC 
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$True , ConfirmImpact='High')]
    param (
        [parameter(Mandatory = $true)]
        [String]$Name ,

        [ValidateNotNullOrEmpty()]  
        [string]$Server=".",  #Only process one server
        $PSC,
        [Switch]$Force
     )
     if ( $psc -eq $null)    { $psc = $pscmdlet }   
     $virtualSwitchMgtSvc= Get-WMIObject -computername $server -namespace $HyperVNamespace -class "MSVM_VirtualSwitchManagementService"   
     $nic                = get-wmiObject -computername $server -namespace $HyperVNamespace  -query "Select * from Msvm_InternalEthernetPort where elementName = '$Name' "
     if (($nic -is [System.Management.ManagementObject]) -and ($force -or $psc.shouldProcess($nic.ElementName, $lstr_RemoveHostNic ))) {     
         $result = $virtualSwitchMgtSvc.DeleteInternalEthernetPort($nic)
         [returnCode]$result.returnValue
    }
}



Function Select-VMExternalEthernet
{# .ExternalHelp  MAML-VMNetwork.XML
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Server = "."   #Only makes sense to select on a single server
    )
    Get-WmiObject -ComputerName $Server -Namespace $HyperVNamespace -query "Select * from Msvm_ExternalEthernetPort where isbound=false"  | 
        Select-list -property Name
}

Function Select-VMLiveMigrationNetwork
{# .ExternalHelp  MAML-VMNetwork.XML
[CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
     Param (
        [ValidateNotNullOrEmpty()] 
        $Server=".",
        $PSC, 
        [switch]$Force
     )
     if (-not (get-command -Name Move-ClusterVirtualMachineRole -ErrorAction "SilentlyContinue")) {Write-warning $lstr_noCluster ; return} 
     if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
     $clusternetworks = Get-ClusterNetwork -Cluster $server           
     write-host -ForegroundColor Red $lstr_SelectLMNetworks
     $selectedNetworks = Select-List -InputObject $clusternetworks -Property name,address -multi
     if ($force -or $psc.shouldProcess(($lStr_ServerName -f $server),$lstr_UpdateLiveMig)) {
         $selectedNetworks | ForEach-Object -Begin {$IncludedList =  ""          } `
                                          -process {$includedList += $_.id + ";" } `
                                              -end {get-ClusterResourceType -Cluster $Server -Name "virtual machine" | 
                                                    set-ClusterParameter -Name migrationNetworkOrder -Value ($includedList -replace "\;$","") }
         $clusternetworks | Where-Object {$selectedNetworks -notcontains $_} | 
                                ForEach-Object -Begin {$ExcludedList =  ""         } `
                                             -process {$ExcludedList += $_.id + ";"} `
                                                 -end {get-ClusterResourceType -Cluster $Server -Name "virtual machine" | 
                                                       set-ClusterParameter -Name "migrationExcludeNetworks" -Value ($ExcludedList -replace "\;$","")}
     }                                           
}                                  


Function Select-VMNIC
{# .ExternalHelp  MAML-VMNetwork.XML    
    param(
        [parameter(ValueFromPipeline = $true)]
        $VM="%", 
     
        [ValidateNotNullOrEmpty()] 
        $Server = ".",  #May need to look for VM(s) on Multiple servers
        
        [Switch]$multiple
    )
    Process { Get-VMnic -VM $vm -Server $Server -legacy -vmbus | Select-list -multiple:$multiple -property "ResourceSubType", "address", @{label="Network"; expression={(get-vmnicSwitch $_).elementname}}   }
}


Function Select-VMSwitch
{# .ExternalHelp  MAML-VMNetwork.XML
    Param (
           [ValidateNotNullOrEmpty()] 
           [string]$Server = "."  #Only Makes sense to select from one server
          )
    Get-Vmswitch -server $server | Select-list -property @{Label="Switch Name"; Expression={$_.ElementName}}
}

Function Set-VMNICAddress
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [parameter(Mandatory = $true , ValueFromPipeLine = $true)]
        $NIC, 

        [parameter(Mandatory = $true)][ValidatePattern('^[0-9|a-f]{12}$')]
        [String]$MAC,

        $PSC, 
        [switch]$Force,
        # VM is preserved for backwards compatibility but is ignored
        $VM , $Server 
    ) 
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($NIC.count -gt 1  ) {[Void]$PSBoundParameters.Remove("NIC") ;  $NIC | ForEach-object {Set-VMNICAddress  -NIC $_ @PSBoundParameters}}
        if ($nic.__CLASS -like "*EthernetPortSettingData")  {           
            $vssd                 = get-wmiobject -computername $nic.__Server -namespace $HyperVNamespace -query "associators of {$nic}  where resultclass=Msvm_VirtualSystemSettingData"
            $vm                   = get-wmiobject -computername $nic.__Server -namespace $HyperVNamespace -query "associators of {$vssd} where resultClass=msvm_ComputerSystem" 
            $nic.address          = $mac 
	        $nic.staticMacAddress = $true
            Set-VMRASD -vm $vm -rasd $NIC -psc $psc -force:$force
       }
   }
   
}


Function Set-VMNICSwitch
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        
        [parameter(Mandatory = $true, ValueFromPipeLine = $true)] 
        $NIC, 
        
        [Alias("name","VirtualSwitchName")]        
        $Virtualswitch ,
        $PSC, 
        [switch]$Force,
        # VM is preserved for backwards compatibility but is ignored
        $VM , $Server 
    ) 
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($NIC.count -gt 1  ) {[Void]$PSBoundParameters.Remove("NIC") ;  $NIC | ForEach-object {Set-VMNICSwitch  -NIC $_ @PSBoundParameters}}
        if ($nic.__CLASS -like "*EthernetPortSettingData")  {           
            if ($nic.connection) {$Oldport  = [wmi]$nic.connection[0]}
            if ($virtualSwitch ) {$Newport  = new-VmSwitchPort -virtualSwitch $virtualSwitch -Server $nic.__server}
            $nic.connection  = [string]$newPort 
            $vssd            = get-wmiobject -computername $nic.__Server -namespace $HyperVNamespace -query "associators of {$nic}  where resultclass=Msvm_VirtualSystemSettingData"
            $vm              = get-wmiobject -computername $nic.__Server -namespace $HyperVNamespace -query "associators of {$vssd} where resultClass=msvm_ComputerSystem" 
            $result = Set-VMRASD -vm $vm -rasd $NIC -psc $psc -force:$force
            if ($oldPort -and ($result -eq [returnCode]::OK) ) {     
                $SwitchMgtSvc=(Get-WmiObject -computerName $nic.__server -NameSpace  $HyperVNamespace   -Query "Select * From MsVM_VirtualSwitchManagementService") 
                $result2 = $SwitchMgtSvc.DeleteSwitchPort($oldport)
                write-Verbose ($Lstr_SwitchPortRemoval -f ([ReturnCode]$result2) )
            }  
            $result 
       }
    }
}



Function Set-VMNICVLAN
{# .ExternalHelp  MAML-VMNetwork.XML
    [CmdletBinding(SupportsShouldProcess=$true)]
    param  ( [parameter(Mandatory = $true, ValueFromPipeline = $true)]
              $NIC,
              $VLANID,
              $PSC,
              [Switch]$Force
    )
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($NIC.count -gt 1  ) {[Void]$PSBoundParameters.Remove("NIC") ;  $NIC | ForEach-object {Set-VMVLAN  -NIC $_ @PSBoundParameters}}
        if ($nic.connection) {
            $vlan = Get-WMIObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$($nic.connection[0])} where assocClass=MSVM_hostedAccessPoint" | 
                          ForEach-Object {Get-WMIObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$_} where ResultClass=Msvm_SwitchPort" }  | 
                                 where-object { ( Get-WMIObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$_} where ResultClass=Msvm_SwitchLanEndPoint" |
                                                 ForEach-Object {Get-WMIObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$_} where ResultClass=Msvm_ExternalEthernetPort"}) 
                                              } | ForEach-Object { Get-WMIObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$_} where assocClass=MSVM_Bindsto" }
           if ($force -or $psc.shouldProcess(($nic.ElementName), ( $lStr_SetVLAN -f $VLANID  ))) {
               if ($vlan.DesiredEndpointMode -ne 5 ) {$vlan.DesiredEndpointMode=5   ; $vlan.put() | out-null }
               $vlanSetting=Get-WmiObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$vlan} where assocClass=MSVM_NetWorkElementSettingData"
               if ($vlanSetting.TrunkedVLANList -notContains $VlanID) {$vlanSetting.TrunkedVLANList += $vlanID ; $vlanSetting.put() | out-null}
               $vlanSetting=Get-WmiObject -ComputerName $Nic.__Server -Namespace $HyperVNamespace -q "associators of {$($nic.connection[0])} where assocClass=msvm_bindsto" | 
                               foreach-object {Get-WmiObject -Namespace -ComputerName $Nic.__Server $HyperVNamespace -q "associators of {$_} where assocClass=MSVM_NetWorkElementSettingData"}
               $vlanSetting.accessVlan = $vlanID ; [wmi]$vlanSetting.put().path
           }     
       }
    }
}
