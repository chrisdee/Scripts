$HyperVNamespace                      = "root\virtualization"
$ImageManagementServiceName           = "Msvm_ImageManagementService"
$VirtualSystemManagementServiceName   = "Msvm_VirtualSystemManagementService"

$lstr_LegacyNicLabel                  = "Legacy Network Adapter"
$lstr_VMBusNicLabel                   = "VM-Bus Network Adapter"
$lstr_VMBusSCSILabel                  = "SCSI Controller"
$lstr_noCluster                       = "Cluster commands not loaded. Import-Modue FailoverClusters and try again"


$Lstr_CreateVFD                       = "Create VFD {0}"
$lstr_CreateVFDFailed                 = "Failure while creating VFD.  Error: {0}" 
$lstr_DirectoryNotFound               = "The specified directory does not exist"
$lStr_DiskDismountBadPath             = "{0} Doesn't appear to be a valid path"
$lStr_DiskDismountFailed              = "The Dismount operation for {0} returned a failure response of: "
$lStr_DiskDismounting                 = "Dismount VHD "
$lStr_DiskDismountSuccess             = "Successfully Dismounted {0}"
$lstr_DiskMountedNoID                 = "The disk mount operation completed, but no ID was found for the disk."
$lstr_diskMountedOffline              = "Disk mounted, but left offline, with the following ID:"
$Lstr_diskMountFailed                 = "The mount operation for {0} returned a failure response of: "
$Lstr_diskRemoveFailed                = "Failed to remove disk from VM {0} result {1}" 
$lstr_DriveNotFound                   = "Could not add disk - could not find or create drive for it"
$lstr_DriveRemoveFailed               = "Failed to remove disk from VM {0} result {1}"
$lStr_ErrorValidatingVHD              = "Error while validating VHD - Error Code: {0}"
$Lstr_GetDiskInfoFailed               = "Could not get disk information for {0}, return code:{1} "
$Lstr_removedDisk                     = "Removed disk from VM {0}"
$lstr_removedDrive                    = "Removed drive from VM {0}."
$Lstr_RemovedSCSI                     = "Removed VBBUS SCSI Controller from VM {0}"
$lstr_RemoveHW                        = "Remove {0}" 
$lstr_RemoveHWFailure                 = "Failed to remove {0} from {1}, return code {2}."
$lstr_RemoveHWSuccess                 = "Removed {0} from {1}."
$lStr_ServerName                      = "Server: {0}"
$lstr_TestVhdSilentError              = "The test did not complete but no error was returned. This is probably because an invalid file was specified"
$lstr_validating                      = "Validating {0}"
$Lstr_VFDCreationContinues            = "The job to create the VFD {0} has not finished. You can use Test-WmiJob to check progress, the ID is:`n {1}"
$Lstr_VfDCreationSuccess              = "The job to create the VFD {0} completed successfully"
$lstr_VHDBadParent                    = "The parent path provided for the differencing disk is not valid."
$Lstr_VHDcompactFailure               = "The attempt to compact VHD {0} returned "
$Lstr_VHDcompacting                   = "compact VHD " 
$Lstr_VHDcompactSuccess               = "VHD {0} was compacted succesfully."
$Lstr_VHDconnectFailure               = "The attempt to reconnect VHD {0} to its parent returned "
$Lstr_VHDconnecting                   = "Reconnect VHD to parent " 
$Lstr_VHDconnectSuccess               = "VHD {0} was reconnected succesfully."
$Lstr_VHDConversion                   = "Convert VHD into {0}" 
$Lstr_VHDConvertFailure               = "The attempt to Convert VHD {0} returned "
$Lstr_VHDConverting                   = "Convert VHD {0} into {1}" 
$Lstr_VHDConvertSuccess               = "VHD {0} was Converted succesfully into {1}."
$lstr_VHDCreate                       =  "Create VHD " 
$Lstr_VHDCreationFailure              = "The attempt to Create VHD {0} failed with response "
$Lstr_VHDCreationSuccess              = "VHD {0} created succesfully."
$Lstr_VHDExpanding                     =  "Expand VHD " 
$lstr_VHDExpandNotContract              = "{0} is currently {1}, in size. It is not possible to reduce the size to {2} as requested"
$Lstr_VHDexpansionFailure              = "The attempt to expand VHD {0} returned "
$Lstr_VHDexpansionSuccess              = "VHD {0} was expanded succesfully."
$lstr_VHDMerge                        = "Merge {0} into {1}"
$Lstr_VHDMergeContinues               = "The job to merge the VHD {0} into {1} has not finished. You can use Test-WmiJob to check progress, the ID is:`n {2}"
$Lstr_VHDMergeFailure                 = "The attempt to merge VHD {0} into {1} failed with a response of"
$Lstr_VHDMergeSuccess                 = "VHD {0} merged succesfully into {1}"
$lstr_VHDMounting                     = "Mount VHD "
$lstr_vhdMountSuccess                 = "The mount operation for {0} succeed,"
$lStr_VirtualMachineName              = "VM: {0}"
$lstr_VMBusSCSILabel                  = "VMBus SCSI Controller"
$lstr_VMBusSCSIRemove                 = "Remove VMBus SCSI Controller"
$lStr_WMIJobFailed2                   = "The WMI Job failed with status {0} `n {1} "


$Lstr_jobContinues                    = "The job to {0} is still running in the background. `n You can check its progress with Test-wmiJob or Test-wmiJob -statusOnly using the following job id:`n{1}"  
$lstr_JobFailure                      = "{0} Failed, with the response " 
$lstr_JobSuccess                      = "{0} succeeded" 


$lstr_boundInternalEthernetFailure    = "Failed to Bind Internal Ethernet adapter to Switch port, result code {0}" 
$lstr_boundInternalEthernetSuccess    = "Bound Internal Ethernet adapter to Switch Port"
$lStr_CreateSwitchPortFailure         = "Failed to create VirtualSwitchPort on switch {0}, return code {1}"
$lstr_CreateSwitchPortSuccess         = "Created VirtualSwitchPort on switch {0}"
$lstr_CreateVirtualNICFailed          = "Failed to Create internal ethernet adapter" 
$lstr_CreateVirtualNICSuccess         = "Created internal ethernet adapter" 
$Lstr_DeleteVirtualSwtich             = "Delete Virtual Switch" 
$lStr_ExternalNictoSwtich             = "Use Host network card for an external virtual network"
$lstr_ExternalSwitchSetup             = "Configuring External Switch {0}"
$lstr_ExternalSwitchSetupFailure      = "Failed to create the external Switch {0} on Server {1}"  
$lstr_ExternalSwitchSetupSuccess      = "Successfully created the external Switch {0} on Server {1}"
$lstr_LegacyNicLabel                  = "Legacy Network Adapter"
$lstr_noCluster                       = "Cluster commands not loaded. Import-Modue FailoverClusters and try again"
$lstr_NoNICProvided                   = "No valid network card was provided"
$lstr_notConnected                    = "Not Connected"
$lstr_RemoveHostNic                   = "Remove Virtual Nic from host"
$Lstr_RemoveSwitchPortStatus          = "Removal of Virtual Switch Port returned {0}" 
$lstr_SelectLMNetworks                = "Please enter the ID(s) of the Network(s) to use for live migration, in order of preference"
$lStr_SetVLAN                         = "Set VLAN ID  {0}"
$lStr_SwitchCreating                   = "Create a new Virtual Switch named {0}"
$lStr_SwitchCreatingFailure            = "Failed to create Virtual Switch {0} on server{1} the response was " 
$lStr_SwitchCreatingSuccess            = "Created Virtual Switch {0} on server{1}"
$Lstr_SwitchPortRemoval               = "Removal of the switch port returned {0}."
$lstr_UpdateLiveMig                   ="Update Live migration networks"
$lstr_VMBusNicLabel                   = "VM-Bus Network Adapter"


$lstr_NewSnapShot                     = "Create Snapshot "
$lstr_NewSnapShotFailure              = "The attempt to snapshot VM {0} failed with the result "
$lstr_NewSnapShotSuccess              = "Successfully Created a new snapshot of VM {0}"
$lstr_RemoveSnapShot                  = "Remove Snapshot "
$lstr_RemoveSnapShotFailure           = "The attempt to remove the snapshot {0} failed with the result "
$lstr_RemoveSnapShotSuccess           = "Successfully removed snapshot {0}"
$Lstr_RenameSnapShot                  = "Rename Snapshot"
$Lstr_RestoreSnapShot                 = "Restore SnapShot "
$lstr_RestoreSnapShotFailure          = "Failed to restore snap shot to VM {0}, the result was "
$lstr_RestoreSnapShotSuccess          = "Successfully restored snap shot to VM {0}"
$lstr_VMWillBeStopped                 = "VM {0} is currently {1} and needs to be stopped" 


$Lstr_BootOrderDuplicate              = "An item appeared more than once in the boot order"
$lstr_ExportOfVm                      = "Export of {0} "
$lstr_ExportOfVmFailure               = "Attempt to export {0} to {1} failed. "
$lstr_ExportOfVmSuccess               = "Export of {0} to {1} completed."
$lstr_ExportVm                        = "Export Virtual Machine"
$lstr_ExportZip                       = "Zipping files for preservation"
$lstr_FQDNNotResolved                 = "Address not resolved"
$lStr_GetSummaryInfoError             = "Get Summary info error : {0}"
$lstr_importFrom                      = "Import VM from {0}"
$lstr_ImportSuccess                   = "Import VM completed." 
$lstr_MigrateTarget                   = "Live migrate to cluster node {0}"
$Lstr_ModifiedVMGlobalSettings        = "Modified VM Global Settings object for {0}"
$Lstr_ModifiedVMSettings              = "Modified VM Settings object for {0}"
$lstr_ModifyServer                       = "Modify Server Configuration" 
$lstr_ModifyServerFailure                = "Failed to Modify server {0} return code "
$lstr_ModifyServerSuccess                = "Updated server settings on server {0}"
$Lstr_ModifyVMGlobalSettingaction     = "Modify VM Global Settings object"
$Lstr_ModifyVMGlobalSettingsFailed    = "Could not Modify VM Global Settings Object for {0} "
$Lstr_ModifyVMSettingaction           = "Modify VM Settings object"
$Lstr_ModifyVMSettingsFailed          = "Could not Modify VM Settings Object for {0} "
$lstr_NoFQDN                          = "Could not discover VM's FQDN"
$LStr_RemoveVMAction                  = "Remove-VM"
$LStr_RemoveVMDescription             = "Removing VM {0}"
$LStr_RemoveVMFailure                 = "Unable to remove the VM {0} " 
$LStr_RemoveVMSuccess                 = "Sucessfully removed the VM {0} " 
$lStr_ServerName                         = "Server: {0}" 
$lStr_VMConnectInvalidSystem          = "Can not run VMConnect is on this system. Skipping."
$lstr_VMCreating                      = "Create Virtual Machine on Server {0} "
$lstr_VMCreationFailed                = "Failed to Create Virtual Machine {0} on Server {1}"
$lstr_VMCreationSuccess               = "Sucessfully created Virtual Machine {0} on Server {1}"
$lstr_VMHeartBeatICNotFound           = "No Heartbeat component found" 
$Lstr_VMHeartBeatWaiting              = "Waiting for heartbeat"
$lstr_VMJPEGFailed                    = "The attempt to get the image failed"
$lstr_VMJPEGNoImage                   = "No image was returned. Try requesting a smaller size." 
$lStr_VMSaving                        = "Suspending VM"
$lStr_VMShutdown                      = "Shutdown OS in the VM."
$lstr_VMShutdownFailed                = "Could not begin Shutdown of {0}" 
$lstr_VMShutdownItitiated             = "Shutdown of {0} has been initiated." 
$lstr_VMShutdownNoIC                  = "Unable to get Shutdown Component for VM {0}.`nPlease verify that the Integration components are enabled for this VM." 
$Lstr_VMShutDownWaiting               = "Waiting for shudown to complete"
$lStr_VMStarting                      = "Starting VM"
$lStr_VMStateChangeFail               = "Failed to change state of VM {0} to: {1}"
$lStr_VMStateChangeSuccess            = "Sucessfully changed state of VM {0} to: {1}"
$lStr_VMStateChanging                 = "Change state to {0}"
$lStr_VMStateWaiting                  = "Change state of VM {1} to {0} "
$lstr_VMstopping                      = "Stopping VM"
$lStr_WMIJobFailed1                   = "The WMI Job failed: {0}"
$LStr_WMIjobfailed2                   = "The WMI Job failed with status {0} `n {1} "
$LHash_PingStatusCode = @{0     = "Success"                          ; 11001 = "Buffer Too Small" ; 
                         11002 = "Destination Net Unreachable"      ; 11003 = "Destination Host Unreachable" ;
                         11004 = "Destination Protocol Unreachable" ; 11005 = "Destination Port Unreachable" ;
                         11006 = "No Resources"                     ; 11007 = "Bad Option" ; 
                         11008 = "Hardware Error"                   ; 11009 = "Packet Too Big" ; 
                         11010 = "Request Timed Out"                ; 11011 = "Bad Request"; 
                         11012 = "Bad Route"                        ; 11013 = "TimeToLive Expired Transit"; 
                         11014 = "TimeToLive Expired Reassembly"    ; 11015 = "Parameter Problem";
                         11016 = "Source Quench"                    ; 11017 = "Option Too Big" ;
                         11018 = "Bad Destination"                  ; 11032=  "Negotiating IPSEC"; 
                         11050="General Failure" } #End PingStatusCode


$LStr_CPUScalesWarning                = "Reservation and Limit are scaled from 0 to 100,000. A value below 100 is less than 0.1%"
$lstr_CreateHW                        = "Create {0}" 
$lstr_CreateHWFailure                 = "Failed to add {0} to {1}, return code"
$lstr_CreateHWSuccess                 = "Added {0} to {1}."
$lstr_KVP_Waiting                     = "Waiting for KVP Exchange Service to finish"
$lstr_KVPRemove                       = "Remove Key Value Pair {0} "
$lstr_KVPRemoveFailure                = "Failed to remove Key  {0} on Virtual Machine {1}, result code {3}"
$lstr_KVPRemoveSucess                 = "Removed Key {0} from Virtual Machine {1}"
$lstr_KVPSet                          = "Set Key Value Pair to {0}--{1} "
$lstr_KVPSetFailure                   = "Failed to set Key Value Pair {0}--{1} on Virtual Machine {2}, result code {3}"
$lstr_KVPSetSucess                    = "Set Key Value Pair {0}--{1} on Virtual Machine {2}"
$lstr_ModifyHW                        = "Modify {0}" 
$lstr_ModifyHWFailure                 = "Failed to Modify {0} on {1}, result was"
$lstr_ModifyHWSuccess                 = "Modified {0} on {1}."
$lstr_noCluster                       = "Cluster commands not loaded. Import-Modue FailoverClusters and try again"
$lstr_RemoveHW                        = "Remove {0}" 
$lstr_RemoveHWFailure                 = "Failed to remove {0} from {1}: Result was {2}."
$lstr_RemoveHWSuccess                 = "Removed {0} from {1}."
$lstr_syncConfig                      = "Update Cluster Virtual Machine Configuration"
$lStr_VirtualMachineName              = "VM: {0}"
$LHash_suites=@{1="Small Business";2="Enterprise";4="BackOffice";8="Communications";16="Terminal";32="Small Business Restricted";64="Embedded NT";128="Data Center";256="Single User";512="Personal";1024="Blade"}


Add-Type @" 


public enum VMState : int  
{
                    Paused = 32768,
                   Stopped = 3,
                   Running = 2,
                    Saving = 32773,
                  Stopping = 32774,
              Snapshotting = 32771,
                 Suspended = 32769,
                  Starting = 32770 
}
public enum ReturnCode : int  
{
                        OK = 0,
                JobStarted = 4096,
                    Failed = 32768, 
              AccessDenied = 32769,
              NotSupported = 32770,
                   Unknown = 32771,
                   Timeout = 32772,
          InvalidParameter = 32773,
               SystemInUse = 32774,
  InvalidStateForOperation = 32775,
         IncorrectDataType = 32776,
        SystemNotAvailable = 32777,
               OutOfMemory = 32778,
              FileNotFound = 32779
}
public enum BootMedia : int  
{
                       IDE = 2,
                    Floppy = 0,
                       NET = 3,
                        CD = 1 
}
public enum StartupAction : int  
{
                      None = 0,
               RestartOnly = 1,
             AlwaysStartup = 2 
}
public enum ShutdownAction : int  
{
                   TurnOff = 0,
                 SaveState = 1,
                  ShutDown = 2 
}
public enum RecoveryAction : int  
{
          RevertToSnapShot = 2,
                   Restart = 1,
                      None = 0 
}
public enum VHDType : int  
{
                   Dynamic = 3,
              Differencing = 4,
                     Fixed = 2,
             PhysicalDrive = 5 
}
public enum JobState : int  
{
                   Service = 11,
                Terminated = 8,
              ShuttingDown = 6,
                 Exception = 10,
                    Killed = 9,
                       New = 2,
                   Running = 4,
                 Completed = 7,
                 Suspended = 5,
                  Starting = 3 
}
public enum ResourceType : int  
{
                  iSCSIHBA = 8,
             StorageExtent = 21,
                  DVDDrive = 16,
                  IODevice = 13,
              ParallelPort = 18,
                     FCHBA = 7,
             USBController = 19,
             CoolingDevice = 29,
        FirewireController = 25,
                    Memory = 4,
                     IBHCA = 9,
                     Other = 1,
            ComputerSystem = 2,
     BasePartitionableUnit = 27,
               PowerSupply = 28,
             IDEController = 5,
                SerialPort = 17,
                      Tape = 23,
                 Processor = 3,
               FloppyDrive = 14,
         PartitionableUnit = 26,
           ParallelSCSIHBA = 6,
        OtherStorageDevice = 24,
                    IOSlot = 12,
                      Disk = 22,
           EthernetAdapter = 10,
        GraphicsController = 20,
       OtherNetworkAdapter = 11,
                   CDDrive = 15 
}
public enum HeartBeatICStatus : int  
{
               Unavailable = 32896,
                No_Contact = 12,
        Lost_Communication = 13,
                        OK = 2,
                     Error = 6 
}


public enum RemoteFxResoultion : int  
{
                  Display1024x768 = 0,
                 Display1280x1024 = 1,
                 Display1600x1200 = 2,
                 Display1920x1200 = 3 
}


"@ 

