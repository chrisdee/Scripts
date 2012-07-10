#############################################################################################################################
#	Author:					Aaron Saikovski - Aaron.Saikovski@microsoft.com  												#
#	Version:				1.0																				 				#
#	Description:			Feature installer and activator for SharePoint 2010												#
#############################################################################################################################

<#
    .Synopsis
        Feature Deployer and activator for SharePoint 2010.
    .Description
        Allows for the easy deployment and activation of SharePoint 2010 features.
    .Parameter FeatureId
        The feature to deploy and activate.
    .Parameter SiteUrl
        The site url to deploy and activate the feature to.
	.Parameter Add
        Adds and Activates the given feature.
	.Parameter Remove
		Deactivates and removces the given feature.	
    .Example
		Feature.ps1 -FeatureId "Feature Name" -SiteUrl http://www.somesite.com/ -Add 
	.Example
        Feature.ps1 -FeatureId "Feature Name" -SiteUrl	http://www.somesite.com/ -Remove	
	.Example
        Feature.ps1 -FeatureId "Feature Name" -SiteUrl	http://www.somesite.com/ -Get
#>

#parameters
PARAM
(
	[string]$FeatureId = $(throw "You must provide a Feature name"), 
	[string]$SiteUrl = $(throw "You must provide a valid site/web url"),
	[switch]$Add, 
	[switch]$Remove,
	[switch]$Get
	
)

#Set the execution policy
Set-ExecutionPolicy Unrestricted

########################################### Function ##############################################
#    Function name:               CheckPowerShellSnapIn                                           #
#    Synopsis:                    Add the required SP2010 snapins				                  #
#    Input parameters:            None			                                                  #
#    Returns:                     None                                                            #
###################################################################################################
function CheckPSSnapIn()
{
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
#    Function name:               EnableFeature                                                   #
#    Synopsis:                    Installs and Activates a feature for a given url                #
#    Input parameters:            FeatureName & SiteUrl                                           #
#    Returns:                     None                                                            #
###################################################################################################
function AddFeature([string]$FeatureId,[string]$SiteUrl)
{	
	Write-Host "Installing Feature $FeatureId for site $SiteUrl" -ForegroundColor Yellow	

	#install feature
	Install-SPFeature -Path $FeatureId -Force | Out-Null

	#execute timer jobs
	ExecuteSPAdminServiceJobs	
	
	#Enable feature
	Enable-SPFeature -Identity $FeatureId -Url $SiteUrl -Force | Out-Null
	
}

########################################### Function ##############################################
#    Function name:               RemoveFeature                                                   #
#    Synopsis:                    Disables and Removes a feature for a given url                  #
#    Input parameters:            FeatureName & SiteUrl                                           #
#    Returns:                     None                                                            #
###################################################################################################
function RemoveFeature([string]$FeatureId,[string]$SiteUrl)
{
	Write-Host "Removing Feature $FeatureId for URL $SiteUrl" -ForegroundColor Cyan

	#Disable Feature
	Disable-SPFeature -Identity $FeatureId -Url $SiteUrl -Force -Confirm:$false | Out-Null
	
	#execute timer jobs
	ExecuteSPAdminServiceJobs	
	
	#Uninstall Feature
	Uninstall-SPFeature -Identity $FeatureId -Force -Confirm:$false | Out-Null
}

########################################### Function ##############################################
#    Function name:               GetFeature                                                      #
#    Synopsis:                    Gets the Feature					                              #
#    Input parameters:            FeatureName                                                     #
#    Returns:                     SPSolution Object                                               #
###################################################################################################
function GetFeature([string]$FeatureId)
{	
	$SPFeature = Get-SPFeature -Identity $FeatureId -ErrorAction SilentlyContinue 
	return $SPFeature
}

########################################### Function ##############################################
#    Function name:               IsFeatureDeployed                                               #
#    Synopsis:                    Gets the deployed property for a Feature object                 #
#    Input parameters:            SolutionName                                                    #
#    Returns:                     True/False                                                      #
###################################################################################################
function IsFeatureDeployed([string]$FeatureId)
{
	$SPFeature = GetFeature $FeatureId
	
	if (-not ([String]::IsNullOrEmpty($SPFeature.DisplayName)))
	{
		return $true
	}
	else
	{
		return $false
	}
	
}

###################################################################################################
#Main Operation section

#Clear the console
CLS

#Add the SP2010 Powershell snap-ins
CheckPSSnapIn

#Check for the operation
if($Add)
{
	if(IsFeatureDeployed($FeatureId))
	{
		Write-Error "Unable to install a feature which is already deployed, please use uninstall first."  
	}
	else
	{		
		#Add the feature
		AddFeature $FeatureId $SiteUrl
		
		if(IsFeatureDeployed($FeatureId))
		{
			Write-Host "Feature successfully installed and activated." -ForegroundColor Green
		}
		else
		{
			Write-Error "Error deploying the Feature."
			GetFeature($FeatureId)
		}
	}
}

if($Remove)
{
	if(GetFeature($FeatureId) -ne $null)
	{
		RemoveFeature $FeatureId $SiteUrl
		
		Write-Host "Feature successfully deactivated and removed." -ForegroundColor Green
	}
	else
	{
		Write-Error "Unable to uninstall solution which is not installed."
	}
}

if($Get)
{
	#Get the feature details
	$SPFeature = GetFeature($FeatureId)
	
	#Display feature details
	if (-not ([String]::IsNullOrEmpty($SPFeature.DisplayName)))
	{		
		Get-SPFeature -Identity $FeatureId
	}
	else
	{
		Write-Error "$FeatureId - Feature not found."
	}	
	
}

###################################################################################################
