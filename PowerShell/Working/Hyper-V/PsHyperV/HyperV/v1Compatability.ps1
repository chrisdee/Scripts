####################################
# Aliases for backward compatability
####################################

Set-Alias -Name List-VMState              -Value Get-VMSummary
Set-Alias -Name Get-VMState               -Value Get-VMSummary
Set-Alias -Name Suspend-vm                -Value Save-vm
Set-Alias -Name Shutdown-vm               -Value Invoke-VMShutdown
Set-Alias -Name Choose-List               -Value Select-List
Set-Alias -Name Choose-Tree               -Value Select-Tree
Set-Alias -Name Choose-VM                 -Value Select-VM
Set-Alias -Name Choose-VMPhysicalDisk     -Value Select-VMPhysicalDisk
Set-Alias -Name Choose-VMSwitch           -Value Select-VMSwitch
Set-Alias -Name Choose-VMNIC              -Value Select-VMNIC
Set-Alias -Name Choose-VMExternalEthernet -Value Select-VMExternalEthernet
Set-Alias -Name Choose-VMSnapshot         -Value Select-VMSnapshot
Set-Alias -Name Apply-Snapshot            -Value Restore-VMsnapshot
Set-Alias -Name Set-VMSettings            -Value set-vm
Set-Alias -Name Add-NewVMHardDisk         -Value Add-VMNewHardDisk
Set-Alias -Name compact-VHD               -Value Compress-VHD


####################################
# Hash-Tables for backward compatability
####################################


$VMState        = ([type]"VMState"       ).getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}
$ReturnCode     = ([type]"ReturnCode"    ).getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}
$BootMedia      = ([type]"BootMedia"     ).getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}
$StartupAction  = ([type]"StartupAction" ).getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}
$ShutDownAction = ([type]"ShutDownAction").getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}
$Recoveryaction = ([type]"Recoveryaction").getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}
$DiskType       = ([type]"VHDType"      ).getfields() |foreach-object -begin {$list=@{}} -process { if (-not $_.isspecialName) { $list[[string]$_.getValue($null)]=[int]$_.getValue($null)}} -end  {$list}


Function Convert-VMState
{  <#
     .Synopsis
        This function has been deprecated. The [VMState] enum should be used instead"
     .Example
        PS> Convert-VMState $ID
        Should be written as [VMState]$ID
     .Parameter $ID 
        An ID to convert
   #>
    Param ($ID)
    Write-Warning "This function has been deprecated.  Please replace calls to Convert-VMState`nto use the [VMState] enum."
    return ([vmState]$ID) 
}
#replace calls to convert-VMstate with [vmstate]

