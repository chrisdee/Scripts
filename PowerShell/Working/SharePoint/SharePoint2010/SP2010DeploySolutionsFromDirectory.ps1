## PowerShell Script to Deploy SharePoint 2010 Solutions from a Source Directory ##
## Name: SP2010DeploySolutionsFromDirectory.ps1
## Resource: http://blog.isaacblum.com/2011/08/19/powershell-install-multiple-wsps

######################################
######## Set Variables ###############
######################################
$InstallDIR = "C:\install"
 
######################################
#### CODE, No Changes Necessary ######
######################################
Write-Host "Working, Please wait...."
Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
 
$Dir = get-childitem $InstallDIR -Recurse
$WSPList = $Dir | where {$_.Name -like "*.wsp*"}
Foreach ($wsp in $WSPList )
{
	$WSPFullFileName = $wsp.FullName
	$WSPFileName = $wsp.Name
	clear
	Write-Host -ForegroundColor White -BackgroundColor Blue "Working on $WSPFileName" 
 
	try
	{
		Write-Host -ForegroundColor Green "Checking Status of Solution"
		$output = Get-SPSolution -Identity $WSPFileName -ErrorAction Stop
	}
	Catch
	{
		$DoesSolutionExists = $_
	}
	If (($DoesSolutionExists -like "*Cannot find an SPSolution*") -and ($output.Name -notlike  "*$WSPFileName*"))
	{
		Try
		{
			Write-Host -ForegroundColor Green "Adding solution to farm"
			Add-SPSolution "$WSPFullFileName" -Confirm:$false -ErrorAction Stop | Out-Null
 
			Write-Host -ForegroundColor Green "Checking Status of Solution"
			$output = Get-SPSolution -Identity $WSPFileName -ErrorAction Stop
			$gobal = $null
			if ($output.Deployed -eq $false)
			{
				try
				{
					Write-Host -ForegroundColor Green "Deploy solution to all Web Apps, will skip if this solution is globally deployed"
					Install-SPSolution -Identity "$WSPFileName" -GACDeployment -AllWebApplications -Force -Confirm:$false -ErrorAction Stop | Out-Null
				}
				Catch
				{
					$gobal = $_
				}
				If ($gobal -like "*This solution contains*")
				{
					Write-Host -ForegroundColor Green "Solution requires global deployment, Deploying now"
					Install-SPSolution -Identity "$WSPFileName" -GACDeployment -Force -Confirm:$false -ErrorAction Stop | Out-Null
				}
			}
 
			Sleep 1
			$dpjobs = Get-SPTimerJob | Where { $_.Name -like "*$WSPFileName*" }
			If ($dpjobs -eq $null)
    		{
        		Write-Host -ForegroundColor Green "No solution deployment jobs found"
    		}
			Else
			{
				If ($dpjobs -is [Array])
				{
					Foreach ($job in $dpjobs)
					{
						$jobName = $job.Name
						While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
						{
							Write-Host -ForegroundColor Yellow -NoNewLine "."
							Start-Sleep -Seconds 5
						}
						Write-Host
					}
				}
    			Else
    			{
					$jobName = $dpjobs.Name
					While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
					{
						Write-Host -ForegroundColor Yellow -NoNewLine "."
						Start-Sleep -Seconds 5
					}
					Write-Host
    			}
			}
		}
		Catch
		{
			Write-Error $_
			Write-Host -ForegroundColor Red "Skipping $WSPFileName, Due to an error"
			Read-Host
		}
	}
	Else
	{
		$skip = $null
		$tryagain = $null
		Try
		{
			if ($output.Deployed -eq $true)
			{
			Write-Host -ForegroundColor Green "Retracting Solution"
			Uninstall-SPSolution -AllWebApplications -Identity $WSPFileName -Confirm:$false -ErrorAction Stop
			}
		}
		Catch
		{
			$tryagain = $_
		}
		Try
		{
			if ($tryagain -ne $null)
			{
				Uninstall-SPSolution -Identity $WSPFileName -Confirm:$false -ErrorAction Stop
			}
		}
		Catch
		{
			Write-Host -ForegroundColor Red "Could not Retract Solution"
		}
 
		Sleep 1
		$dpjobs = Get-SPTimerJob | Where { $_.Name -like "*$WSPFileName*" }
		If ($dpjobs -eq $null)
    	{
        	Write-Host -ForegroundColor Green "No solution deployment jobs found"
    	}
		Else
		{
			If ($dpjobs -is [Array])
			{
				Foreach ($job in $dpjobs)
				{
					$jobName = $job.Name
					While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
					{
						Write-Host -ForegroundColor Yellow -NoNewLine "."
						Start-Sleep -Seconds 5
					}
					Write-Host
				}
			}
    		Else
    		{
				$jobName = $dpjobs.Name
				While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
				{
					Write-Host -ForegroundColor Yellow -NoNewLine "."
					Start-Sleep -Seconds 5
				}
				Write-Host
    		}
		}		
 
		Try
		{
			Write-Host -ForegroundColor Green "Removing Solution from farm"
			Remove-SPSolution -Identity $WSPFileName -Confirm:$false -ErrorAction Stop
		}
		Catch
		{
			$skip = $_
			Write-Host -ForegroundColor Red "Could not Remove Solution"
			Read-Host
		}
		if ($skip -eq $null)
		{
			Try
			{
				Write-Host -ForegroundColor Green "Adding solution to farm"
				Add-SPSolution "$WSPFullFileName" -Confirm:$false -ErrorAction Stop | Out-Null
				$gobal = $null
				try
				{
					Write-Host -ForegroundColor Green "Deploy solution to all Web Apps, will skip if this solution is globally deployed"
					Install-SPSolution -Identity "$WSPFileName" -GACDeployment -AllWebApplications -Force -Confirm:$false -ErrorAction Stop | Out-Null
				}
				Catch
				{
					$gobal = $_
				}
				If ($gobal -like "*This solution contains*")
				{
					Write-Host -ForegroundColor Green "Solution requires global deployment, Deploying now"
					Install-SPSolution -Identity "$WSPFileName" -GACDeployment -Force -Confirm:$false -ErrorAction Stop | Out-Null
				}
			}
			Catch
			{
				Write-Error $_
				Write-Host -ForegroundColor Red "Skipping $WSPFileName, Due to an error"
				Read-Host
			}
 
			Sleep 1
			$dpjobs = Get-SPTimerJob | Where { $_.Name -like "*$WSPFileName*" }
			If ($dpjobs -eq $null)
    		{
        		Write-Host -ForegroundColor Green "No solution deployment jobs found"
    		}
			Else
			{
				If ($dpjobs -is [Array])
				{
					Foreach ($job in $dpjobs)
					{
						$jobName = $job.Name
						While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
						{
							Write-Host -ForegroundColor Yellow -NoNewLine "."
							Start-Sleep -Seconds 5
						}
						Write-Host
					}
				}
    			Else
    			{
					$jobName = $dpjobs.Name
					While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
					{
						Write-Host -ForegroundColor Yellow -NoNewLine "."
						Start-Sleep -Seconds 5
					}
					Write-Host
    			}
			}
	}
	Else
	{
		Write-Host -ForegroundColor Red "Cannot Install $WSPFileName, Please try manually"
		Read-Host
	}
}
}