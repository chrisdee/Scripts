## =====================================================================
## Title       : List-MSSQL-FailedJobs
## Description : List failed SQL Server jobs using SMO
## Author      : Idera
## Date        : 1/28/2009
## Input       : -serverInstance <server\instance>
## 				  -verbose 
## 				  -debug	
## Output      : List failed jobs
## Usage			: PS> .\List-MSSQL-FailedJobs -serverInstance MyServer -verbose -debug
## Notes			: Adapted from Jakob Bindslet script
## Tag			: SQL Server, SMO, SQL Agent Jobs
## Change log  : Revised SMO Assemblies
## =====================================================================
 
param
(
  	[string]$serverInstance="(local)",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	List-MSSQL-FailedJobs $serverInstance
}

function List-MSSQL-FailedJobs($ServerInstance)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}

	#Load SMO assemblies
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );

	$namedInstance = new-object('Microsoft.SqlServer.Management.Smo.server') ($serverInstance)
	
	$jobs = $namedInstance.jobserver.jobs | where-object {$_.isenabled}

	# Process all SQL Agent Jobs looking for failed jobs based on the last run outcome
	foreach ($job in $jobs) 
	{
		[int]$outcome = 0
		[string]$output = ""
	
		# Did the job fail completely?
		if ($job.LastRunOutcome -ne "Succeeded") 
		{
			$outcome++
			$output = $output + " Job failed (" + $job.name + ")" + " Result: " + $job.LastRunOutcome
		}
		
		# Did any of the steps fail?
		foreach ($jobStep in $job.jobsteps) 
		{
			if ($jobStep.LastRunOutcome -ne "Succeeded")
			{
				$outcome++
				$output = $output + " Step failed (" + $jobStep.name + ")" + " Result: " + $jobStep.LastRunOutcome + " -- "
			}
		}
		
		if ($outcome -gt 0)    
		{
			$obj = New-Object Object
			$obj | Add-Member Noteproperty name -value $job.name
			$obj | Add-Member Noteproperty lastrundate -value $job.lastrundate
			$obj | Add-Member Noteproperty lastrunoutcome -value $output
			$obj
		}
	}
}

main

