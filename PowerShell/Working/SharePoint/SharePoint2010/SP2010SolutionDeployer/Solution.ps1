#############################################################################################################################
#	Author:					Aaron Saikovski - Aaron.Saikovski@microsoft.com  												#
#	Version:				1.1																					 			#
#	Description:			SharePoint 2010 Solution deployer 																#
#############################################################################################################################

<#
    .Synopsis
        SharePoint 2010 Solution packager deployer. - For use with NON Sandboxed solutions
    .Description
        Allows for the easy deployment and retraction of SharePoint 2010 solution packages (.WSPs).
    .Parameter SolutionName
        The solution (.WSP) package name to deploy.
    .Parameter Add
        Installs and deploys the solution package.
	.Parameter Remove
        Uninstalls and retracts the solution package.
	.Parameter Upgrade
		Upgrades and deploys the solution package.		  
	.Parameter AllWebApplications
		Tells the installer whether to deploy to all web applications.		
    .Example
        Solution.ps1 -SolutionName "Solution.wsp" -Add $true
	.Example
        Solution.ps1 -SolutionName "Solution.wsp" -Remove $true
	.Example
        Solution.ps1 -SolutionName "Solution.wsp" -Upgrade $true
	.Example	
        Solution.ps1 -SolutionName "Solution.wsp" -Add $false
	.Example
        Solution.ps1 -SolutionName "Solution.wsp -Remove $false
	.Example
        Solution.ps1 -SolutionName "Solution.wsp" -Upgrade $false
#>

#parameters
PARAM
(
	[string]$SolutionName = $(throw "You must provide a solution(.WSP) name"), 
	[switch]$Add, 
	[switch]$Remove, 
	[switch]$Upgrade,
	[bool]$AllWebApplications 
)

#Set the execution policy
Set-ExecutionPolicy Unrestricted

########################################### Function ##############################################
#    Function name:               CheckPSSnapIn                                           		  #
#    Synopsis:                    Add the required SP2010 snapins				                  #
#    Input parameters:            None			                                                  #
#    Returns:                     None                                                            #
###################################################################################################
function CheckPSSnapIn()
{
	#Write-Host "Adding PSSnapin - Microsoft.SharePoint.PowerShell" -ForegroundColor Magenta

	#Check if the snapin has been added
	$snapin = Get-PSSnapin | Where-Object { $_.Name -like "Microsoft.SharePoint.PowerShell"}
	
	#add the snapin
	if ([bool]$snapin) {} else {Add-PSSnapIn Microsoft.SharePoint.PowerShell | Out-Null}
}

########################################### Function ##############################################
#    Function name:               ExecuteSPAdminServiceJobs                                       #
#    Synopsis:                    Call Start-SPAdminJob to execute timer jobs                     #
#    Input parameters:            None                                                            #
#    Returns:                     None                                                            #
###################################################################################################
function ExecuteSPAdminServiceJobs()
{
	#Start-SPAdminJob -verbose -ErrorAction SilentlyContinue
	Start-SPAdminJob -ErrorAction SilentlyContinue
}

########################################### Function ##############################################
#    Function name:               WaitForJobToFinish                                              #
#    Synopsis:                    Waits for a timer job to finish				                  #
#    Input parameters:            SolutionName                                                    #
#    Returns:                     None                                                            #
###################################################################################################
function WaitForJobToFinish([string]$SolutionFileName)
{ 
    $JobName = "*solution-deployment*$SolutionFileName*"
    $job = Get-SPTimerJob | ?{ $_.Name -like $JobName }
    if ($job -ne $null) 
	{    
        $JobFullName = $job.Name
        Write-Host -NoNewLine "Waiting to finish Timer job - $JobFullName" 
        
        while ((Get-SPTimerJob $JobFullName) -ne $null) 
        {
            Write-Host -NoNewLine .
            Start-Sleep -Seconds 2
        }
        Write-Host  "Finished waiting for job.."
    }
}

########################################### Function ##############################################
#    Function name:               GetWorkingFolder    			                                  #
#    Synopsis:                    Gets the current working folder where the script was run        #
#    Input parameters:            None                                                            #
#    Returns:                     None                                                            #
###################################################################################################
function GetWorkingFolder()
{
	#Get the current folder	from where the script was run
	$currentDir	= (Get-Location -PSProvider FileSystem).ProviderPath
	[Environment]::CurrentDirectory=$currentDir	
	return $currentDir
}


########################################### Function ##############################################
#    Function name:               InstallSolution                                                 #
#    Synopsis:                    Installs the solution to the solution store	                  #
#    Input parameters:            solutionFileName                                                #
#    Returns:                     None                                                            #
###################################################################################################
function InstallSolution([string]$solutionFileName)
{
	#Get the current folder			
	$PathToFile = GetWorkingFolder 
	$PathToFile += "\" + $solutionFileName
		
	Write-Host "Add solution $PathToFile" -ForegroundColor Yellow

	#Add the solution to the farm
	Add-SPSolution -LiteralPath $PathToFile | Out-Null
	
	#execute timer jobs
	ExecuteSPAdminServiceJobs
	
	Write-Host 'Waiting for Add-SPSolution job to finish' -ForegroundColor Yellow
	WaitForJobToFinish	

	Write-Host "Install solution $solutionFileName" -ForegroundColor Yellow	
	
	#check if we are deploying to all web applications
	if($AllWebApplications)
	{
		#Install the solution to all web applications
		Install-SPSolution -Identity $solutionFileName -GACDeployment -CASPolicies -Force -AllWebApplications | Out-Null
	}
	else
	{
		#Install the solution 
		Install-SPSolution -Identity $solutionFileName -GACDeployment -CASPolicies -Force | Out-Null
	}
	
	#execute timer jobs	
	ExecuteSPAdminServiceJobs
	
	Write-Host 'Waiting for Install-SPSolution job to finish' -ForegroundColor Yellow
	WaitForJobToFinish	
		
	Write-Host "Finished Installing solution $solutionFileName" -ForegroundColor Yellow
}

########################################### Function ##############################################
#    Function name:               UpgradeSolution                                                 #
#    Synopsis:                    Upgrades a given solution in the solution store	              #
#    Input parameters:            solutionFileName                                                #
#    Returns:                     None                                                            #
###################################################################################################
function UpgradeSolution([string]$solutionFileName)
{
	#Get the current folder			
	$PathToFile = GetWorkingFolder 
	$PathToFile += "\" + $solutionFileName
		
	Write-Host "Upgrading solution $solutionFileName" -ForegroundColor Magenta
	
	Write-Debug "Update-SPSolution -LiteralPath $PathToFile -Identity $solutionFileName -GACDeployment -CASPolicies -Force"
	
	#Upgrade the solution
	Update-SPSolution -LiteralPath $PathToFile -Identity $solutionFileName -GACDeployment -CASPolicies -Force | Out-Null
	
	#execute timer jobs	
	ExecuteSPAdminServiceJobs
	
	Write-Host 'Waiting for Update-SPSolution job to finish' -ForegroundColor Magenta
	WaitForJobToFinish	
	
	Write-Host "Finished Upgrading solution $solutionFileName" -ForegroundColor Magenta
}

########################################### Function ##############################################
#    Function name:               UninstallSolution                                               #
#    Synopsis:                    Uninstalls a solution from the solution store				      #
#    Input parameters:            solutionFileName                                                #
#    Returns:                     None                                                            #
###################################################################################################
function UninstallSolution([string]$solutionFileName)
{
	Write-Host "Uninstalling solution $solutionFileName" -ForegroundColor Cyan
	
	Write-Debug " & Uninstall-SPSolution -Identity $solutionFileName"
	
	#check if we are uninstalling from all web applications
	if($AllWebApplications)
	{
		#Uninstall the solution from all web apps
		Uninstall-SPSolution -Identity $solutionFileName -Confirm:$false -AllWebApplications | Out-Null
	}
	else
	{
		#Uninstall the solution
		Uninstall-SPSolution -Identity $solutionFileName -Confirm:$false | Out-Null
	}
	
	#execute timer jobs		
	ExecuteSPAdminServiceJobs
		
	Write-Host 'Waiting for Uninstall-SPSolution job to finish' -ForegroundColor Cyan
	WaitForJobToFinish	
			
	#Remove the solution
	Remove-SPSolution -Identity $solutionFileName -Confirm:$false -Force | Out-Null	
	
	#execute timer jobs	
	ExecuteSPAdminServiceJobs
	
	Write-Host 'Waiting for Remove-SPSolution job to finish' -ForegroundColor Cyan
	WaitForJobToFinish
	
	Write-Host "Finished Uninstalling solution $solutionFileName" -ForegroundColor Cyan
}

########################################### Function ##############################################
#    Function name:               GetSolution                                                     #
#    Synopsis:                    Gets the SharePoint Solution object from the solution store     #
#    Input parameters:            SolutionName                                                    #
#    Returns:                     SPSolution Object                                               #
###################################################################################################
function GetSolution([string]$SolutionName)
{	
	$SPSolution = Get-SPSolution -Identity $SolutionName -ErrorAction SilentlyContinue 
	return $SPSolution
}

########################################### Function ##############################################
#    Function name:               IsSolutionDeployed                                              #
#    Synopsis:                    Gets the deployed property for a deployed solution              #
#    Input parameters:            SolutionName                                                    #
#    Returns:                     True/False                                                      #
###################################################################################################
function IsSolutionDeployed([string]$SolutionName)
{
	$SPSolution = GetSolution $SolutionName
	return $SPSolution.Deployed	
}

###################################################################################################
#Main Operation section

#Clear the console
CLS

#Add the SP2010 Powershell snap-ins
CheckPSSnapIn

#check for $AllWebApplications, set to true by default
if ([String]::IsNullOrEmpty($AllWebApplications))
{
	$AllWebApplications = $true
}

#Check for the operation
if($Add)
{
	if(IsSolutionDeployed($SolutionName))
	{
		Write-Error "Unable to install solution which is already deployed, please use upgrade or uninstall first."  
	}
	else
	{
		InstallSolution($SolutionName)
		
		if(IsSolutionDeployed($SolutionName))
		{
			Write-Host "Solution successfully deployed." -ForegroundColor Green
		}
		else
		{
			Write-Error "Error deploying the solution."
			GetSolution($SolutionName)
		}
	}
}

if($Remove)
{
	if(GetSolution($SolutionName) -ne $null)
	{
		UninstallSolution $SolutionName
	}
	else
	{
		Write-Error "Unable to uninstall a solution which is not installed."
	}
}

if($Upgrade)
{
	if(GetSolution($SolutionName) -ne $null)
	{
		UpgradeSolution $SolutionName
		
		if(IsSolutionDeployed($SolutionName))
		{
			Write-Host "Solution successfully upgraded." -ForegroundColor Green
		}
		else
		{
			Write-Error "Error upgrading the solution."
			GetSolution($SolutionName)
		}
	}
	else
	{
		Write-Error "Unable to upgrade a solution which is not installed."
	}
}

###################################################################################################