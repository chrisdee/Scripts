## SharePoint Server 2013: PowerShell Script to Move the Search Index Location ##

<#

Overview: PowerShell Script Function to Move the Search Index Location for the Search Service Application

Environments: SharePoint Server 2013 Farms

Usage: Provide the following parameters and run this script on each Machine you want to move the location on: '-SearchServiceName'; '-Server'; '-IndexLocation'

Usage Example: Move-SPEnterpriseSearchIndex -SearchServiceName "Search Service Application" -Server "SP2013-WFE" -IndexLocation "C:\Index"

Note: You might need to reboot your machines where the Search Service Application is configured on after making the changes

Resources: https://gallery.technet.microsoft.com/office/Move-SharePoint-2013-242869e2; http://consulting.risualblogs.com/blog/2013/09/03/sharepoint-2013move-the-search-index-location

#>

function Move-SPEnterpriseSearchIndex($SearchServiceName,$Server,$IndexLocation){ 
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ea 0; 
    #Gets the Search Service Application 
    $SSA = Get-SPServiceApplication -Name $SearchServiceName; 
    if (!$?){throw "Cant find a Search Service Application: `"$SearchServiceName`"";} 
    #Gets the Search Service Instance on the Specified Server 
    $Instance = Get-SPEnterpriseSearchServiceInstance -Identity $Server; 
    if (!$?){throw "Cant find a Search Service Instance on Server: `"$Server`"";} 
    #Gets the current Search Topology 
    $Current = Get-SPEnterpriseSearchTopology -SearchApplication $SSA -Active; 
    if (!$?){throw "There is no Active Topology, you can try removing the `"-Active`" from the line above in the script";} 
    #Creates a Copy of the current Search Topology 
    $Clone = New-SPEnterpriseSearchTopology -Clone -SearchApplication $SSA -SearchTopology $Current; 
    #Adds a new Index Component with the new Index Location 
    New-SPEnterpriseSearchIndexComponent -SearchTopology $Clone -IndexPartition 0 -SearchServiceInstance $Instance -RootDirectory $IndexLocation | Out-Null; 
    if (!$?){throw "Make sure that Index Location `"$IndexLocation`" exists on Server: `"$Server`"";} 
    #Sets our new Search Topology as Active 
    Set-SPEnterpriseSearchTopology -Identity $Clone; 
    #Removes the old Search Topology 
    Remove-SPEnterpriseSearchTopology -Identity $Current -Confirm:$false; 
    #Now we need to remove the extra Index Component 
    #Gets the Search Topology 
    $Current = Get-SPEnterpriseSearchTopology -SearchApplication $SSA -Active; 
    #Creates a copy of the current Search Topology 
    $Clone=New-SPEnterpriseSearchTopology -Clone -SearchApplication $SSA -SearchTopology $Current; 
    #Removes the old Index Component from the Search Topology 
    Get-SPEnterpriseSearchComponent -SearchTopology $Clone | ? {($_.GetType().Name -eq "IndexComponent") -and ($_.ServerName -eq $($Instance.Server.Address)) -and ($_.RootDirectory -ne $IndexLocation)} | Remove-SPEnterpriseSearchComponent -SearchTopology $Clone -Confirm:$false; 
    #Sets our new Search Topology as Active 
    Set-SPEnterpriseSearchTopology -Identity $Clone; 
    #Removes the old Search Topology 
    Remove-SPEnterpriseSearchTopology -Identity $Current -Confirm:$False; 
    Write-Host "The Index has been moved to $IndexLocation on $Server" 
    Write-Host "This will not remove the data from the old index location. You will have to do that manually :)" 
} 
 
Move-SPEnterpriseSearchIndex -SearchServiceName "Search Service Application" -Server "SP2013-WFE" -IndexLocation "C:\Index"