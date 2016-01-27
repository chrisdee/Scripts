## Scheduled Tasks: PowerShell Script to Get Details on All Scheduled Tasks on a Local or Remote Machine ##

<#   
.SYNOPSIS   
Script that returns scheduled tasks on a computer (local or remote)
    
.DESCRIPTION 
This script uses the Schedule.Service COM-object to query the local or a remote computer in order to gather	a formatted list including the Author, UserId and description of the task. This information is parsed from the XML attributed to provide a more human readable format
 
.PARAMETER Computername
The computer that will be queried by this script, local administrative permissions are required to query this information

.NOTES   
Name: Get-ScheduledTask.ps1
Author: Jaap Brasser
DateCreated: 2012-05-23
DateUpdated: 2015-08-17
Site: http://www.jaapbrasser.com
Version: 1.3.2

.LINKS
http://www.jaapbrasser.com
https://gallery.technet.microsoft.com/scriptcenter/Get-Scheduled-tasks-from-3a377294

.EXAMPLE
	.\Get-ScheduledTask.ps1 -ComputerName server01

Description
-----------
This command query mycomputer1 and display a formatted list of all scheduled tasks on that computer

.EXAMPLE
	.\GetScheduledTask.ps1

Description
-----------
This command query localhost and display a formatted list of all scheduled tasks on the local computer

.EXAMPLE
	.\GetScheduledTask.ps1 -ComputerName server01 | Select-Object -Property Name,Trigger

Description
-----------
This command query server01 for scheduled tasks and display only the TaskName and the assigned trigger(s)

.EXAMPLE
	.\GetScheduledTask.ps1 | Where-Object {$_.Name -eq 'TaskName') | Select-Object -ExpandProperty Trigger

Description
-----------
This command queries the local system for a scheduled task named 'TaskName' and display the expanded view of the assisgned trigger(s)

.EXAMPLE
	Get-Content C:\Servers.txt | ForEach-Object { .\GetScheduledTask.ps1 -ComputerName $_ }

Description
-----------
Reads the contents of C:\Servers.txt and pipes the output to GetScheduledTask.ps1 and outputs the results to the console


#>
param(
	[string]$ComputerName = $env:COMPUTERNAME,
    [switch]$RootFolder
)

#region Functions
function Get-AllTaskSubFolders {
    [cmdletbinding()]
    param (
        # Set to use $Schedule as default parameter so it automatically list all files
        # For current schedule object if it exists.
        $FolderRef = $Schedule.getfolder("\")
    )
    if ($FolderRef.Path -eq '\') {
        $FolderRef
    }
    if (-not $RootFolder) {
        $ArrFolders = @()
        if(($Folders = $folderRef.getfolders(1))) {
            $Folders | ForEach-Object {
                $ArrFolders += $_
                if($_.getfolders(1)) {
                    Get-AllTaskSubFolders -FolderRef $_
                }
            }
        }
        $ArrFolders
    }
}

function Get-TaskTrigger {
    [cmdletbinding()]
    param (
        $Task
    )
    $Triggers = ([xml]$Task.xml).task.Triggers
    if ($Triggers) {
        $Triggers | Get-Member -MemberType Property | ForEach-Object {
            $Triggers.($_.Name)
        }
    }
}
#endregion Functions


try {
	$Schedule = New-Object -ComObject 'Schedule.Service'
} catch {
	Write-Warning "Schedule.Service COM Object not found, this script requires this object"
	return
}

$Schedule.connect($ComputerName) 
$AllFolders = Get-AllTaskSubFolders

foreach ($Folder in $AllFolders) {
    if (($Tasks = $Folder.GetTasks(1))) {
        $Tasks | Foreach-Object {
	        New-Object -TypeName PSCustomObject -Property @{
	            'Name' = $_.name
                'Path' = $_.path
                'State' = switch ($_.State) {
                    0 {'Unknown'}
                    1 {'Disabled'}
                    2 {'Queued'}
                    3 {'Ready'}
                    4 {'Running'}
                    Default {'Unknown'}
                }
                'Enabled' = $_.enabled
                'LastRunTime' = $_.lastruntime
                'LastTaskResult' = $_.lasttaskresult
                'NumberOfMissedRuns' = $_.numberofmissedruns
                'NextRunTime' = $_.nextruntime
                'Author' =  ([xml]$_.xml).Task.RegistrationInfo.Author
                'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
                'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description
                'Trigger' = Get-TaskTrigger -Task $_
                'ComputerName' = $Schedule.TargetServer
            }
        }
    }
}