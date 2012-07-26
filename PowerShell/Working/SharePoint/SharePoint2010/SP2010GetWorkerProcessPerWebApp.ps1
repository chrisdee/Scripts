## SharePoint Server 2010: PowerShell Script To Get Which W3WP IIS Process Is Running Against Each Web App ##
## Overview: Queries which w3wp.exe Process ID (PID) is running against which web application, along with Memory and CPU usage
## Resource: http://sp2010adminpack.codeplex.com

<#
.SYNOPSIS
    Gets the SharePoint processes running with current performance statistics
.DESCRIPTION
    Matches the running w3wp processes with SharePoint Web Applications and Services. Includes the current Working Set RAM usage and CPU Utilization.
.NOTES
    Author: David Lozzi @DavidLozzi
    DateCreated: 17Feb2012
#> 

#store current location, and return back to it at the end
$currentLocation = Get-Location

#Check to ensure SharePoint is loaded
if((Get-PSSnapin | Where {$_.Name -eq "Microsoft.SharePoint.PowerShell"}) -eq $null){
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}
#clear our screen
cls

#get the IIS application pools running
cd c:\Windows\System32\inetsrv
$appPools = .\appcmd list wp

#get the SPServices running
$serviceApps = Get-SPServiceApplicationPool | select name, id

#result set
$results = @()

foreach($pool in $appPools)
{
	$poolSplit = $pool.Split(" ")
	#get the processor id
	$appPid = $poolSplit[1].Replace("`"","")
	#get the app pool name
	$name = $poolSplit[2].Replace("(applicationPool:","").Replace(")","")
	
	$result = New-Object System.Object
	$result | Add-Member -type NoteProperty -Name ProcID -Value $appPid
	
	$guid = $name -as [Guid]
	if ($guid -eq $null)
	{
		#web app names contain spaces, and would've been trimmed out above. add the rest of the name
		$name = "Web Application: " + $name
		for($i = 3; $i -le $poolSplit.length; $i++)
		{
			if($poolSplit[$i] -ne $null)
			{
				$name += " " + $poolSplit[$i].Replace("`)","")
			}
		}
		$result | Add-Member -type NoteProperty -Name Name -Value $name
	}else{	
		$spAppName = $serviceApps | where {$_.id -eq $guid}
		$result | Add-Member -type NoteProperty -Name Name -Value $spAppName.Name
	}
	
	#get process stats
	$psProcess = Get-Process -id $appPid            
	$psName = $psProcess.name
	# Create the Performance Counter Object to track our sessions CPU usage            
	$Global:psPerfCPU = new-object System.Diagnostics.PerformanceCounter( "Process","% Processor Time", $psName )            
	# Get the first 'NextValue', which will be zero            
	$psPerfCPU.NextValue() | Out-Null            
	           
	[int]$ws = $psProcess.workingset64/1MB
	[int]$proc = $psPerfCPU.NextValue() / $env:NUMBER_OF_PROCESSORS
	
	$ram = $ws.ToString() + "MB"
	$cpuper = $proc.ToString() + "%"
	
	$result | Add-Member -type NoteProperty -Name RAM -Value $ram
	$result | Add-Member -type NoteProperty -Name CPU -Value $cpuper
	
	$results += $result
}

cd $currentLocation

$a = @{Expression={$_.ProcID};Label="Proc ID";width=8}, `
@{Expression={$_.Name};Label="Name";width=55}, `
@{Expression={$_.RAM};Label="RAM";width=7},
@{Expression={$_.CPU};Label="CPU";width=7}
$results | Format-Table $a