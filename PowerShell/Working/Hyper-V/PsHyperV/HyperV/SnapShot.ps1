

Function Get-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    Param(
      [parameter(Position=0 ,  ValueFromPipeline = $true)]
      $VM = "%", 
      [String]$Name="%",
      
      [ValidateNotNullOrEmpty()]  
      $Server="." ,
      [Switch]$Current,  
      [Switch]$Newest, 
      [Switch]$Root
    )
    process{
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { Get-VMSnapshot -VM $_  @PSBoundParameters}} 
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            if ($current)  {Get-wmiobject -computerName $vm.__server -Namespace $HyperVNamespace -q "associators of {$($vm.path)} where assocClass=MSvm_PreviousSettingData"}
            else {$Snaps=Get-WmiObject -computerName $vm.__server -NameSpace $HyperVNameSpace -Query "Select * From MsVM_VirtualSystemSettingData Where systemName='$($VM.name)' and instanceID <> 'Microsoft:$($VM.name)' and elementName like '$name' " 
                if   ($newest) {$Snaps | sort-object -property creationTime | select-object -last 1 } 
                elseif ($root) {$snaps | where-object {$_.parent -eq $null} }
                else           {$snaps}
            }
        }
    }
}



Function Get-VMSnapshotTree
{# .ExternalHelp  MAML-VMSnapshot.XML
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
      $VM, 
 
      [ValidateNotNullOrEmpty()] 
      $Server="."   #May need to look for VM(s) on Multiple servers
    )

    if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
    if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
        $snapshots=(Get-VMSnapshot -VM $VM ) 
       if ($snapshots -is [array]) {out-tree -items $snapshots -startAt ($snapshots | where-object {$_.parent -eq $null}) -path "__Path" -Parent "Parent" -label "elementname"}
       else {$snapshots | foreach-object {"-" + $_.elementName} }
    }
}


Function New-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param( 
           [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
           $VM , 
           [string]$Note, 

           [ValidateNotNullOrEmpty()] 
           $Server=".", 
           
           [switch]$Wait,
           $PSC,
           [Switch]$Force)
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { New-VMsnapshot -VM $_  @PSBoundParameters}} 
        if (($vm.__CLASS -eq 'Msvm_ComputerSystem') -and ($force -or $psc.shouldProcess($VM.elementName , $lstr_NewSnapShot))) {
            $VSMgtSvc=Get-WmiObject -ComputerName $VM.__server -NameSpace  $HypervNameSpace -Class "MsVM_virtualSystemManagementService"
            $WMIResult = $VSMgtSvc.CreateVirtualSystemSnapshot($vm) 
            if ((Test-wmiResult -result $WMIResult -wait:$wait -JobWaitText ($lstr_NewSnapShot + $VM.elementName)`
                                -SuccessText ($lstr_NewSnapShotSuccess -f $VM.elementName) `
                                -failText    ($lstr_NewSnapShotFailure -f $VM.elementName)) -eq [ReturnCode]::OK) {
                $Snap = ([wmi]$WMIResult.Job).getRelated("Msvm_VirtualSystemSettingData")
                if ($note) {$Snap | foreach-object {set-vm -VM $_ -note $note -psc $psc -Force:$true  ; $_.get() ; $_ }}
                else       {$Snap | foreach-object {$_} } 
            }
        }
    }   
} 


Function Remove-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
        [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)][allowNull()]
        $Snapshot , 
        [Switch]$Tree , 
        [Switch]$wait,
        $PSC,
        [switch]$Force
        )
    Process {    
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ( $SnapShot.count -gt 1 ) {[Void]$PSBoundParameters.Remove("SnapShot") ;  $SnapShot | ForEach-object {Remove-VMSnapshot -snapshot $_  @PSBoundParameters}} 
        if (($snapshot.__class -eq 'Msvm_VirtualSystemSettingData') -and ($force -or $psc.shouldProcess($snapshot.elementName , $lstr_RemoveSnapShot))) {
            $VSMgtSvc=Get-WmiObject -ComputerName $snapshot.__server -NameSpace  $HyperVNamespace -Class "MsVM_virtualSystemManagementService"
            if ($tree) {$result=$VSMgtSvc.RemoveVirtualSystemSnapshotTree($snapshot) }
            else       {$result=$VSMgtSvc.RemoveVirtualSystemSnapshot($snapshot)     }
            $result    | Test-wmiResult -wait:$wait -JobWaitText ($lstr_RemoveSnapShot + $snapshot.elementName)`
                                        -SuccessText ($lstr_RemoveSnapShotSuccess -f $snapshot.elementName) `
                                        -failText    ($lstr_RemoveSnapShotFailure -f $snapshot.elementName)  
       }
   }
}                


Function Rename-VMSnapshot 
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High' )]
    param (
        [parameter(ParameterSetName="Path" ,Mandatory = $true)]
        $VM, 
        [parameter(ParameterSetName="Path" , Mandatory = $true)][ValidateNotNullOrEmpty()][Alias("SnapshotName")]
        [String]$SnapName, 
        [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] 
        [string]$NewName, 
        [parameter(ParameterSetName="Path")][ValidateNotNullOrEmpty()] 
        $Server=".",   #May need to look for VM(s) on Multiple servers
        [parameter(ParameterSetName="Snap" , Mandatory = $true, ValueFromPipeline = $true)]
        $Snapshot,
        $PSC,
        [switch]$Force 
    )    
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { Rename-VMsnapshot -VM $_  @PSBoundParameters}} 
        if (($pscmdlet.ParameterSetName -eq "Path") -and ($vm.__CLASS -eq 'Msvm_ComputerSystem')) { $snapshot=Get-VmSnapshot -vm $vm -name $snapName }
        if ($snapshot.__class -eq 'Msvm_VirtualSystemSettingData') {Set-vm -VM $snapshot -Name $newName -psc $psc -force:$force }
    }     
}


Function Restore-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
      $SnapShot, 
      
      $PSC, 
 
      [Switch]$Force , 
      [Switch]$Restart, 
      [Switch]$wait)
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
         if ($SnapShot.count -gt 1 ) {[Void]$PSBoundParameters.Remove("SnapShot") ;  $SnapShot | ForEach-object {Restore-snapshot -snapshot $_  @PSBoundParameters}} 
         if ($snapshot.__class -eq 'Msvm_VirtualSystemSettingData') {
             $VM = Get-WmiObject -computername $snapshot.__server -NameSpace "root\virtualization" -Query ("Select * From MsVM_ComputerSystem Where Name='$($Snapshot.systemName)' " )
             if ($vm.enabledState -ne [vmstate]::stopped) {write-warning ($lstr_VMWillBeStopped -f $vm.elementname , [vmstate]$vm.enabledState) ; Stop-VM $vm -wait -psc $psc -force:$force}
             if ($force -or $psc.shouldProcess($vm.ElementName , $Lstr_RestoreSnapShot)) {
                 $VSMgtSvc=Get-WmiObject -ComputerName $snapshot.__server -NameSpace  "root\virtualization" -Class "MsVM_virtualSystemManagementService" 
                 if ( ($VSMgtSvc.ApplyVirtualSystemSnapshot($VM,$snapshot)  | Test-wmiResult -wait:$wait -JobWaitText ($lstr_RestoreSnapShot + $vm.elementName)`
                                                                            -SuccessText ($lstr_RestoreSnapShotSuccess -f $VM.elementname) `
                                                                            -failText ($lstr_RestoreSnapShotFailure -f  $vm.elementname) ) -eq [returnCode]::ok) {if ($Restart) {Start-vm $vm}  }
              }
         }
    } 
}



Function Select-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()] 
      $VM, 
 
      [ValidateNotNullOrEmpty()] 
      $Server="."   #May need to look for VM(s) on Multiple servers
    )
    if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
    if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
 	    $snapshots=(Get-VMSnapshot -vm $VM)
	    if ($snapshots -is [array]) {Select-Tree -items $snapshots -startAt ($snapshots | where-object {$_.parent -eq $null}) -path "__Path" -Parent "Parent" -label "elementname"}
         else                       {$snapshots}
    }
            
}


Function Update-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
        [parameter( Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()] 
        $VM , 
        
        [Alias("SnapshotName")]
        $SnapName, 
        
        $Note,
        
        [ValidateNotNullOrEmpty()] 
        $Server=".",
        $PSC,
        [Switch]$Force
        ) 
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { Update-VMSnapshot -VM $_  @PSBoundParameters}} 
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            if ($snapName -eq $null) {$snapName=(Get-VMSnapshot $vm -newest ).elementname } 
            If ($snapName) {rename-VMsnapshot  -vm $vm -SnapName $snapName -newName "Delete-me" -force:$force -psc $psc}
            new-vmSnapshot $vm -wait -note $note -force:$force -psc $psc | rename-VMsnapshot -Newname $snapName -force:$force -psc $psc
            Get-VmSnapShot $vm -name "Delete-me" | remove-vmSnapShot -wait -force:$force -psc $psc -ErrorAction silentlycontinue
        }
    }
}
