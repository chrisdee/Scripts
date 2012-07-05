## MOSS 2007: PowerShell Script To Migrate All Site Collections and Sites From One Content Database to Another ##
## Resource: http://mysharepointofview.com/2010/12/a-word-about-moving-site-collections
## Notes: Script at Resource has some issues along with this one like Set Site Lock not working
## Usage: Ensure that you have created your Destination / Target DB through CA 'Manage Content Databases' or STSADM
##		  Edit the 'Variables' to suit your environment, and run the script 
##		  You will get a 'You cannot call a method' exception and 'setsitelock' errors
##		  Check the site move results under CA 'Manage Content Databases'
## Important: This approach won't really be useful for large site collection moves

$env:PATH = $env:PATH +
";C:Program FilesCommon FilesMicrosoft SharedWeb Server Extensions12BIN"

############# Start Variables ################
$webAppUrl = "http://YourWebAppURL.com"
$sourceContentDB = "YourSourceContent_DB"
$destinationContentDB = "YourDestination_DB"
$xmlfile = "C:\inetpub\tempsites.xml"
############# End Variables ################

# enumerate through all site collections and save them to the XML-file
Write-Host '"Retreives all site collections located at"
$webAppUrl "and save it to " $xmlfile'
stsadm -o enumsites -url $webAppUrl -showlocks > $xmlfile | out-null

# Import the XML file content $sites = [xml](Get-Content $xmlfile)
# Remove only the site collections located in the source database
Write-Host "Cleaning up the" $xmlfile "file and remove sites that should not be migrated"
$sites.Sites.Site | Where-Object {$_.ContentDatabase -ne $sourceContentdb} |
ForEach-Object { $_.ParentNode.RemoveChild($_) | out-null }

# Enumerate through all the sites in the xml file and make necessary preparations

foreach($site in $sites.sites.site) {
# Lock the sites to prevent errors when migration and data loss
Write-Host "Locking the site" $site.url "to prevent data loss"
stsadm -o setsitelock -url $site.URL -lock Noaccess
}

# Moving sites
stsadm -o mergecontentdbs -url $webAppUrl -sourcedatabasename $sourceContentDB -destinationdatabasename $destinationContentDB -operation 3 -filename $xmlfile

# Get the farm object to find get all the WFEs in the farm
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$farm = [Microsoft.SharePoint.Administration.SPFarm]::Local
Write-Host "To complete the move you need to make an IISreset on all WFEs in the farm"
Write-Host "You will now get the option to make an IISreset on all your WFEs"
Write-Host ""

# Enumerate through all servers in the farm

foreach ($svr in $farm.Servers) {
  foreach ($svc in $svr.ServiceInstances) {
    # If the server has the Windows SharePoint Services Web Application service it
    # is most likely it's a WFE.
    if($svc.TypeName -eq "Windows SharePoint Services Web Application"){
      # Ask if we should make an IISReset on the server
      $IISReset = Read-Host '"Do you want to make an IIS-reset on"
      '$svr.DisplayName'  "(yes/no)?"'
      if($IISReset.ToLower() -eq "yes") {
        iisreset $svr.DisplayName
      }
    }
  }
}
# Enumerate through all the sites in the xml file and finalize the move
foreach($site in $sites.sites.site) {
  # Set the original lockstate for the site collection
   Write-Host "Setting the original lock state for site" $site.url "to prevent data loss"
  stsadm -o setsitelock -url $site.URL -lock $site.Lock
}
