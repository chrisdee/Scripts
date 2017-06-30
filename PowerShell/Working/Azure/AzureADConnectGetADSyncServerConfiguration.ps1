## PowerShell: Script to Get the Azure Active Directory Synchronization Client Configuration XML Files (Azure AD Connect / AAD Connect) ##

## This script outputs XML configuration files to the location specified in the '$ConfigurationPath' variable into the following directories: Connectors; GlobalSettings; SynchronizationRules

$ConfigurationPath = "C:\BoxBuild\AzureADConnectSyncDocumenter\Data\MachineName" #Change this path to match your environment

Import-Module ADSync

Get-ADSyncServerConfiguration -Path "$ConfigurationPath"

Get-ChildItem $ConfigurationPath