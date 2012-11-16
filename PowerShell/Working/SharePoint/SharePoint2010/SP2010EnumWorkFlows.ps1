## SharePoint Server: PowerShell Script to Enumerate All Workflows in a SharePoint Farm ##

<#

Overview: The script will return all Workflows currently associated within your SharePoint farm using PowerShell, and outputs it to a file.
It returns the URL of the site, Title of the list, Title of the workflow, and the number of currently Running Instances of the workflow.

Environments: MOSS 2007, SharePoint Server 2010 / 2013 Farms

Resource: http://www.jeffholliday.com/2012/05/powershell-script-identify-all.html

#>

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null 
$outputFile = Read-Host "Location and Filename (e.g. C:\output.txt)"

$farm = [Microsoft.SharePoint.Administration.SPFarm]::local
$websvcs = $farm.Services | where -FilterScript {$_.GetType() -eq [Microsoft.SharePoint.Administration.SPWebService]} 
$webapps = @() 

$outputHeader = "Url;List;Workflow;Running Instances" > $outputFile

foreach ($websvc in $websvcs) { 

    foreach ($webapp in $websvc.WebApplications) { 
		foreach ($site in $webapp.Sites) {
			foreach ($web in $site.AllWebs) {
				foreach ($List in $web.Lists) {
					foreach ($workflow in $List.WorkflowAssociations) {
						$output = $web.Url + ";" + $List.Title + ";" + $workflow.Name + ";" + $workflow.RunningInstances
						Write-Output $output >> $outputFile
				}}
				} 
			} 
		}
	}
$Web.Dispose();
$site.Dispose();

