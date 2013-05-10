## SharePoint Server: PowerShell Script To Check Details On A Farms Search Service Application Topology ##

<# 
.SYNOPSIS 
       The purpose of this SharePoint 2013 script is to present the status of the Search  
       Service Application, with main focus on the state of the search topology.  
.DESCRIPTION 
       The script consolidates data from multiple cmdlets and sources:
       - Key topology status data from Get-SPEnterpriseSearchStatus
             Get-SPEnterpriseSearchStatus -SearchApplication $ssa
             Get-SPEnterpriseSearchStatus -SearchApplication $ssa -Primary -<Admin Component>
             Get-SPEnterpriseSearchStatus -SearchApplication $ssa -JobStatus
             Get-SPEnterpriseSearchStatus -SearchApplication $ssa -HealthReport -Component <Search Component>
                 Printing selected info relevant for degraded states
       - Crawl status (crawling/idle/paused)
             $ssa.Ispaused()
             $contentSource.CrawlState
       - Number of indexed documents including index size alert (currently 10 mill. items per partition)
             Using Get-SPEnterpriseSearchStatus -SearchApplication $ssa -HealthReport -Component <Search Component>
       - HA status for topology, indicating which roles that may not have high availability
             Aggregated status info from Get-SPEnterpriseSearchStatus
       - Host controller repository status (for search dictionaries)
             Get-SPEnterpriseSearchHostController

       Limitations:
       - The script only supports one SSA in the farm. 
         If multiple SSAs found, the script prints status for the first SSA found.
.NOTES 
  File Name : Get-SPSearchTopologyState.ps1 
  Tags      : SharePoint 2013, Enterprise Search, SP2013ES, Search Service Application

.RESOURCE
 http://blogs.msdn.com/b/knutbran/archive/2012/11/30/how-to-view-the-status-of-the-sharepoint-2013-search-service.aspx

#> 

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

# ==================================================================================================================
# Get status for search topology
# ==================================================================================================================

# --------------------------------------------------------------------------
#  Writes error message to the user in red color and exits the script.
# --------------------------------------------------------------------------
Function WriteErrorAndExit($errorText)
{
    Write-Host -BackgroundColor Red -ForegroundColor Black $errorText
    Write-Host -BackgroundColor Red -ForegroundColor Black "Aborting script"
    exit
}

# ------------------------------------------------------------------------------------------------------------------
# GetSSA: Get SSA reference 
# ------------------------------------------------------------------------------------------------------------------
Function GetSSA
{
    $ssas = @(Get-SPEnterpriseSearchServiceApplication)
    if ($ssas.Count -ne 1)
    {
        WriteErrorAndExit("This script only supports a single SSA configuration")
    }

    $global:ssa = $ssas[0]
    if ($global:ssa.Status -ne "Online")
    {
        $ssaStat = $global:ssa.Status
        WriteErrorAndExit("Expected SSA to have status 'Online', found status: $ssaStat")
    }

    Write-Output "SSA: $($global:ssa.Name)"
    Write-Output ""
}

# ------------------------------------------------------------------------------------------------------------------
# GetCrawlStatus: Get crawl status
# ------------------------------------------------------------------------------------------------------------------
Function GetCrawlStatus
{
    if ($global:ssa.Ispaused())
    {
        switch ($global:ssa.Ispaused()) 
        { 
            1       { $pauseReason = "ongoing search topology operation" } 
            2       { $pauseReason = "backup/restore" } 
            4       { $pauseReason = "backup/restore" } 
            32      { $pauseReason = "crawl DB re-factoring" } 
            64      { $pauseReason = "link DB re-factoring" } 
            128     { $pauseReason = "external reason (user initiated)" } 
            256     { $pauseReason = "index reset" } 
            512     { $pauseReason = "index re-partitioning (query is also paused)" } 
            default { $pauseReason = "multiple reasons ($($global:ssa.Ispaused()))" } 
        }
        Write-Output "$($global:ssa.Name): Paused for $pauseReason"
    }
    else
    {
        $crawling = $false
        $contentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $global:ssa
        if ($contentSources) 
        {
            foreach ($source in $contentSources)
            {
                if ($source.CrawlState -ne "Idle")
                {
                    Write-Output "Crawling $($source.Name) : $($source.CrawlState)"
                    $crawling = $true
                }
            }
            if (! $crawling)
            {
                Write-Output "Crawler is idle"
            }
        }
        else
        {
            Write-Output "Crawler: No content sources found"
        }
    }
}

# ------------------------------------------------------------------------------------------------------------------
# GetTopologyInfo: Get basic topology info and component health status
# ------------------------------------------------------------------------------------------------------------------
Function GetTopologyInfo
{
    $at = Get-SPEnterpriseSearchTopology -SearchApplication $global:ssa -Active
    $global:topologyCompList = Get-SPEnterpriseSearchComponent -SearchTopology $at

    # Check if topology is prepared for HA
    $adminFound = $false
    foreach ($searchComp in ($global:topologyCompList))
    {
        if ($searchComp.Name -match "Admin")
        { 
            if ($adminFound) 
            { 
                $global:haTopology = $true 
            } 
            else
            {
                $adminFound = $true
            }
        }
    }    

    #
    # Get topology component state:
    #
    $global:componentStateList=Get-SPEnterpriseSearchStatus -SearchApplication $global:ssa

    # Find the primary admin component:
    foreach ($component in ($global:componentStateList))
    {
        if ( ($component.Name -match "Admin") -and ($component.State -ne "Unknown") )
        {
            if (Get-SPEnterpriseSearchStatus -SearchApplication $global:ssa -Primary -Component $($component.Name))
            {
                $global:primaryAdmin = $component.Name
            }
        }
    }    
    if (! $global:primaryAdmin)
    {
        Write-Output ""
        Write-Output "-----------------------------------------------------------------------------"
        Write-Output "Error: Not able to obtain health state information."
        Write-Output "Recommended action: Ensure that at least one admin component is operational."
        Write-Output "This state may also indicate that an admin component failover is in progress."
        Write-Output "-----------------------------------------------------------------------------"
        Write-Output ""
        throw "Search component health state check failed"
    }
}

# ------------------------------------------------------------------------------------------------------------------
# PopulateHostHaList: For each component, determine properties and update $global:hostArray / $global:haArray
# ------------------------------------------------------------------------------------------------------------------
Function PopulateHostHaList($searchComp)
{
        if ($searchComp.ServerName)
        {
            $hostName = $searchComp.ServerName
        }
        else
        {
            $hostName = "Unknown server"
        }
        $partition = $searchComp.IndexPartitionOrdinal
        $newHostFound = $true
        $newHaFound = $true
        $entity = $null

        foreach ($searchHost in ($global:hostArray))
        {
            if ($searchHost.hostName -eq $hostName)
            {
                $newHostFound = $false
            }
        }
        if ($newHostFound)
        {
            # Add the host to $global:hostArray
            $hostTemp = $global:hostTemplate | Select-Object *
            $hostTemp.hostName = $hostName
            $global:hostArray += $hostTemp
            $global:searchHosts += 1
        }

        # Fill in component specific data in $global:hostArray
        foreach ($searchHost in ($global:hostArray))
        {
            if ($searchHost.hostName -eq $hostName)
            {
                $partition = -1
                if ($searchComp.Name -match "Query") 
                { 
                    $entity = "QueryProcessingComponent" 
                    $searchHost.qpc = "QueryProcessing "
                    $searchHost.components += 1
                }
                elseif ($searchComp.Name -match "Content") 
                { 
                    $entity = "ContentProcessingComponent" 
                    $searchHost.cpc = "ContentProcessing "
                    $searchHost.components += 1
                }
                elseif ($searchComp.Name -match "Analytics") 
                { 
                    $entity = "AnalyticsProcessingComponent" 
                    $searchHost.apc = "AnalyticsProcessing "
                    $searchHost.components += 1
                }
                elseif ($searchComp.Name -match "Admin") 
                { 
                    $entity = "AdminComponent" 
                    if ($searchComp.Name -eq $global:primaryAdmin)
                    {
                        $searchHost.pAdmin = "Admin(Primary) "
                    }
                    else
                    {
                        $searchHost.sAdmin = "Admin "
                    }
                    $searchHost.components += 1
                }
                elseif ($searchComp.Name -match "Crawl") 
                { 
                    $entity = "CrawlComponent" 
                    $searchHost.crawler = "Crawler "
                    $searchHost.components += 1
                }
                elseif ($searchComp.Name -match "Index") 
                { 
                    $entity = "IndexComponent"
                    $partition = $searchComp.IndexPartitionOrdinal
                    $searchHost.index = "IndexPartition($partition) "
                    $searchHost.components += 1
                }
            }
        }
    
        # Fill in component specific data in $global:haArray
        foreach ($haEntity in ($global:haArray))
        {
            if ($haEntity.entity -eq $entity)
            {
                if ($entity -eq "IndexComponent")
                {
                    if ($haEntity.partition -eq $partition)
                    {
                        $newHaFound = $false
                    }
                }
                else 
                { 
                    $newHaFound = $false
                }
            }
        }
        if ($newHaFound)
        {
            # Add the HA entities to $global:haArray
            $haTemp = $global:haTemplate | Select-Object *
            $haTemp.entity = $entity
            $haTemp.components = 1
            if ($partition -ne -1) 
            { 
                $haTemp.partition = $partition 
            }
            $global:haArray += $haTemp
        }
        else
        {
            foreach ($haEntity in ($global:haArray))
            {
                if ($haEntity.entity -eq $entity) 
                {
                    if (($entity -eq "IndexComponent") )
                    {
                        if ($haEntity.partition -eq $partition)
                        {
                            $haEntity.components += 1
                        }
                    }
                    else
                    {
                        $haEntity.components += 1
                        if (($haEntity.entity -eq "AdminComponent") -and ($searchComp.Name -eq $global:primaryAdmin))
                        {
                            $haEntity.primary = $global:primaryAdmin
                        }
                    }
                }
            }
        }
}

# ------------------------------------------------------------------------------------------------------------------
# AnalyticsStatus: Output status of analytics jobs
# ------------------------------------------------------------------------------------------------------------------
Function AnalyticsStatus
{
    Write-Output "Analytics Processing Job Status:"
    $analyticsStatus = Get-SPEnterpriseSearchStatus -SearchApplication $global:ssa -JobStatus

    foreach ($analyticsEntry in $analyticsStatus)
    {
        if ($analyticsEntry.Name -ne "Not available")     
        {
            foreach ($de in ($analyticsEntry.Details))
            {
                if ($de.Key -eq "Status")
                {
                    $status = $de.Value
                }
            }
            Write-Output "    $($analyticsEntry.Name) : $status"
        }
        # Output additional diagnostics from the dictionary
        foreach ($de in ($analyticsEntry.Details))
        {
            # Skip entries that is listed as Not Available
            if ( ($de.Value -ne "Not available") -and ($de.Key -ne "Activity") -and ($de.Key -ne "Status") )
            {
                Write-Output "        $($de.Key): $($de.Value)"
                if ($de.Key -match "Last successful start time")
                {
                    $dLast = Get-Date $de.Value
                    $dNow = Get-Date
                    $daysSinceLastSuccess = $dNow.DayOfYear - $dLast.DayOfYear
                    if ($daysSinceLastSuccess -gt 3)
                    {
                        Write-Output "        Warning: More than three days since last successful run"
                        $global:serviceDegraded = $true                        
                    }
                }
            }
        }
    }
    Write-Output ""
}

# ------------------------------------------------------------------------------------------------------------------
# SearchComponentStatus: Analyze the component status for one component
# ------------------------------------------------------------------------------------------------------------------
Function SearchComponentStatus($component)
{
    # Find host name
    foreach($searchComp in ($global:topologyCompList))
    {
        if ($searchComp.Name -eq $component.Name)
        {
            if ($searchComp.ServerName)
            {
                $hostName = $searchComp.ServerName
            }
            else
            {
                $hostName = "No server associated with this component. The server may have been removed from the farm."
            }
        }
    }
    if ($component.State -ne "Active")
    {
        # String with all components that is not active:
        if ($component.State -eq "Unknown")
        {
            $global:unknownComponents += "$($component.Name):$($component.State)"
        }
        elseif ($component.State -eq "Degraded")
        {
            $global:degradedComponents += "$($component.Name):$($component.State)"
        }
        else
        {
            $global:failedComponents += "$($component.Name):$($component.State)"
        }
        $global:serviceDegraded = $true
    }
    
    # Skip unnecessary info about cells and partitions if everything is fine
    $outputEntry = $true
    
    # Indent the cell info, logically belongs to the component. 
    if ($component.Name -match "Cell")
    {
        if ($component.State -eq "Active")
        {
            $outputEntry = $false
        }
        else
        {
            Write-Output "    $($component.Name)"
        }
    }
    elseif ($component.Name -match "Partition")
    {
        if ($component.State -eq "Active")
        {
            $outputEntry = $false
        }
        else
        {
            Write-Output "Index $($component.Name)"
        }
    }
    else
    {
        # State for search components
        $primaryString = ""
        if ($component.Name -match "Query") { $entity = "QueryProcessingComponent" }
        elseif ($component.Name -match "Content") { $entity = "ContentProcessingComponent" }
        elseif ($component.Name -match "Analytics") { $entity = "AnalyticsProcessingComponent" }
        elseif ($component.Name -match "Crawl") { $entity = "CrawlComponent" }
        elseif ($component.Name -match "Admin") 
        { 
            $entity = "AdminComponent" 
            if ($global:haTopology)
            {
                if ($component.Name -eq $global:primaryAdmin)
                {
                    $primaryString = " (Primary)"
                }
            }
        }
        elseif ($component.Name -match "Index") 
        { 
            $entity = "IndexComponent"
            foreach ($searchComp in ($global:topologyCompList))
            {
                if ($searchComp.Name -eq $component.Name) 
                {
                    $partition = $searchComp.IndexPartitionOrdinal
                }
            }
            # find info about primary role
            foreach ($de in ($component.Details))
            {
                if ($de.Key -eq "Primary")
                {
                    if ($de.Value -eq "True")
                    {
                        $primaryString = " (Primary)"
                        foreach ($haEntity in ($global:haArray))
                        {
                            if (($haEntity.entity -eq $entity) -and ($haEntity.partition -eq $partition))
                            {
                                $haEntity.primary = $component.Name

                            }
                        }                        
                    }
                }
            }
        }
        foreach ($haEntity in ($global:haArray))
        {
            if ( ($haEntity.entity -eq $entity) -and ($component.State -eq "Active") )
            {
                if ($entity -eq "IndexComponent")
                {
                    if ($haEntity.partition -eq $partition)
                    {
                        $haEntity.componentsOk += 1
                    }
                }
                else 
                { 
                    $haEntity.componentsOk += 1
                }
            }
        }
        # Add the component entities to $global:compArray for output formatting
        $compTemp = $global:compTemplate | Select-Object *
        $compTemp.Component = "$($component.Name)$primaryString"
        $compTemp.Server = $hostName
        $compTemp.State = $component.State
        if ($partition -ne -1) 
        { 
            $compTemp.Partition = $partition 
        }
        $global:compArray += $compTemp

        if ($component.State -eq "Active")
        {
            $outputEntry = $false
        }
        else
        {
            Write-Output "$($component.Name)"
        }
    }
    if ($outputEntry)
    {
        if ($component.State)
        {
            Write-Output "    State: $($component.State)"
        }
        if ($hostName)
        {
            Write-Output "    Server: $hostName"
        }
        if ($component.Message)
        {
            Write-Output "    Details: $($component.Message)"
        }
    
        # Output additional diagnostics from the dictionary
        foreach ($de in ($component.Details))
        {
            if ($de.Key -ne "Host")
            {
                Write-Output "    $($de.Key): $($de.Value)"
            }
        }
        if ($global:haTopology)
        {
            if ($component.Name -eq $global:primaryAdmin)
            {
                Write-Output "    Primary: True"            
            }
            elseif ($component.Name -match "Admin")
            {
                Write-Output "    Primary: False"            
            }
        }
    }
}

# ------------------------------------------------------------------------------------------------------------------
# DetailedIndexerDiag: Output selected info from detailed component diag
# ------------------------------------------------------------------------------------------------------------------
Function DetailedIndexerDiag
{
    $indexerInfo = @()
    $generationInfo = @()
    $generation = 0

    foreach ($searchComp in ($global:componentStateList))
    {
        $component = $searchComp.Name
        if ( (($component -match "Index") -or ($component -match "Content") -or ($component -match "Admin")) -and ($component -notmatch "Cell") -and ($searchComp.State -notmatch "Unknown") -and ($searchComp.State -notmatch "Registering"))
        {
            $pl=Get-SPEnterpriseSearchStatus -SearchApplication $global:ssa -HealthReport -Component $component
            foreach ($entry in ($pl))
            {
                if ($entry.Name -match "plugin: number of documents") 
                { 
                    foreach ($haEntity in ($global:haArray))
                    {
                        if (($haEntity.entity -eq "IndexComponent") -and ($haEntity.primary -eq $component))
                        {
                            # Count indexed documents from all index partitions:
                            $global:indexedDocs += $entry.Message
                            $haEntity.docs = $entry.Message
                        }
                    }
                }
                if ($entry.Name -match "repartition")
                    { $indexerInfo += "Index re-partitioning state: $($entry.Message)" }
                elseif (($entry.Name -match "splitting") -and ($entry.Name -match "fusion")) 
                    { $indexerInfo += "$component : Splitting index partition (appr. $($entry.Message) % finished)" }
                elseif (($entry.Name -match "master merge running") -and ($entry.Message -match "true")) 
                { 
                    $indexerInfo += "$component : Index Master Merge (de-fragment index files) in progress" 
                    $global:masterMerge = $true
                }
                elseif ($global:degradedComponents -and ($entry.Name -match "plugin: newest generation id"))
                {
                    # If at least one index component is left behind, we want to output the generation number.  
                    $generationInfo += "$component : Index generation: $($entry.Message)" 
                    $gen = [int] $entry.Message
                    if ($generation -and ($generation -ne $gen))
                    {
                        # Verify if there are different generation IDs for the indexers
                        $global:generationDifference = $true
                    }
                    $generation = $gen
                }
                elseif (($entry.Level -eq "Error") -or ($entry.Level -eq "Warning"))
                {
                    $global:serviceDegraded = $true
                    if ($entry.Name -match "fastserver")
                        { $indexerInfo += "$component ($($entry.Level)) : Indexer plugin error ($($entry.Name):$($entry.Message))" }
                    elseif ($entry.Message -match "fragments")
                        { $indexerInfo += "$component ($($entry.Level)) : Missing index partition" }
                    elseif (($entry.Name -match "active") -and ($entry.Message -match "not active"))
                        { $indexerInfo += "$component ($($entry.Level)) : Indexer generation controller is not running. Potential reason: All index partitions are not available" }
                    elseif ( ($entry.Name -match "in_sync") -or ($entry.Name -match "left_behind") )
                    { 
                        # Indicates replicas are out of sync, catching up. Redundant info in this script
                        $global:indexLeftBehind = $true
                    }                
                    elseif ($entry.Name -match "full_queue")
                        { $indexerInfo += "$component : Items queuing up in feeding ($($entry.Message))" }                                
                    elseif ($entry.Message -notmatch "No primary")
                    {
                        $indexerInfo += "$component ($($entry.Level)) : $($entry.Name):$($entry.Message)"
                    }
                }
            }
        }
    } 

    if ($indexerInfo)
    {
        Write-Output ""
        Write-Output "Indexer related additional status information:"
        foreach ($indexerInfoEntry in ($indexerInfo))
        {        
            Write-Output "    $indexerInfoEntry"
        }
        if ($global:indexLeftBehind -and $global:generationDifference)
        {
            # Output generation number for indexers in case any of them have been reported as left behind, and reported generation IDs are different.
            foreach ($generationInfoEntry in ($generationInfo))
            {        
                Write-Output "    $generationInfoEntry"
            }
        }
        Write-Output ""
    }
}

# ------------------------------------------------------------------------------------------------------------------
# VerifyHaLimits: Verify HA status for topology and index size limits
# ------------------------------------------------------------------------------------------------------------------
Function VerifyHaLimits
{
    $hacl = @()
    $haNotOk = $false
    $ixcwl = @()
    $ixcel = @()
    $docsExceeded = $false
    $docsHigh = $false
    foreach ($hac in $global:haArray)
    {
        if ([int] $hac.componentsOk -lt 2)
        {
            if ([int] $hac.componentsOk -eq 0)
            {
                # Service is down
                $global:serviceFailed = $true
                $haNotOk = $true   
            }
            elseif ($global:haTopology)
            {
                # Only relevant to output if we have a HA topology in the first place
                $haNotOk = $true   
            }

            if ($hac.partition -ne -1)
            {
                $hacl += "$($hac.componentsOk)($($hac.components)) : Index partition $($hac.partition)"
            }
            else
            {
                $hacl += "$($hac.componentsOk)($($hac.components)) : $($hac.entity)"
            }
        }
        if ([int] $hac.docs -gt 10000000)
        {
            $docsExceeded = $true 
            $ixcel += "$($hac.entity) (partition $($hac.partition)): $($hac.docs)"
        }
        elseif ([int] $hac.docs -gt 9000000)
        {
            $docsHigh = $true   
            $ixcwl += "$($hac.entity) (partition $($hac.partition)): $($hac.docs)"
        }
    }
    if ($haNotOk)
    {
        $hacl = $hacl | sort
        if ($global:serviceFailed)
        {
            Write-Output "Critical: Service down due to components not active:"
        }
        else
        {
            Write-Output "Warning: No High Availability for one or more components:"
        }
        foreach ($hc in $hacl)
        {
            Write-Output "    $hc"
        }
        Write-Output ""
    }
    if ($docsExceeded)
    {
        $global:serviceDegraded = $true
        Write-Output "Warning: One or more index component exceeds document limit:"
        foreach ($hc in $ixcel)
        {
            Write-Output "    $hc"
        }
        Write-Output ""
    }
    if ($docsHigh)
    {
        Write-Output "Warning: One or more index component is close to document limit:"
        foreach ($hc in $ixcwl)
        {
            Write-Output "    $hc"
        }
        Write-Output ""
    }
}

# ------------------------------------------------------------------------------------------------------------------
# VerifyHostControllerRepository: Verify that Host Controller HA (for dictionary repository) is OK
# ------------------------------------------------------------------------------------------------------------------
Function VerifyHostControllerRepository
{
    $highestRepVer = 0
    $hostControllers = 0
    $primaryRepVer = -1
    $hcStat = @()
    $hcs = Get-SPEnterpriseSearchHostController
    foreach ($hc in $hcs)
    {
        $hostControllers += 1
        $repVer = $hc.RepositoryVersion
        $serverName = $hc.Server.Name
        if ($repVer -gt $highestRepVer)
        {
            $highestRepVer = $repVer
        }
        if ($hc.PrimaryHostController)
        {
            $primaryHC = $serverName
            $primaryRepVer = $repVer
        }
        if ($repVer -ne -1)
        {
            $hcStat += "        $serverName : $repVer"
        }
    }
    if ($hostControllers -gt 1)
    {
        Write-Output "Primary search host controller (for dictionary repository): $primaryHC"
        if ($primaryRepVer -eq -1)
        {
            $global:serviceDegraded = $true
            Write-Output "Warning: Primary host controller is not available."
            Write-Output "    Recommended action: Restart server or set new primary host controller using Set-SPEnterpriseSearchPrimaryHostController."
            Write-Output "    Repository version for existing host controllers:"
            foreach ($hcs in $hcStat)
            {
                Write-Output $hcs
            }
        }
        elseif ($primaryRepVer -lt $highestRepVer)
        {
            $global:serviceDegraded = $true
            Write-Output "Warning: Primary host controller does not have the latest repository version."
            Write-Output "    Primary host controller repository version: $primaryRepVer"
            Write-Output "    Latest repository version: $highestRepVer"
            Write-Output "    Recommended action: Set new primary host controller using Set-SPEnterpriseSearchPrimaryHostController."
            Write-Output "    Repository version for existing host controllers:"
            foreach ($hcs in $hcStat)
            {
                Write-Output $hcs
            }
        }
        Write-Output ""
    }
}

# ------------------------------------------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Search Topology health check"
Write-Output "============================"
Write-Output ""
Get-Date
# ------------------------------------------------------------------------------------------------------------------
# Global variables:
# ------------------------------------------------------------------------------------------------------------------

$global:serviceDegraded = $false
$global:serviceFailed = $false
$global:unknownComponents = @()
$global:degradedComponents = @()
$global:failedComponents = @()
$global:generationDifference = $false
$global:indexLeftBehind = $false
$global:searchHosts = 0
$global:ssa = $null
$global:componentStateList = $null
$global:topologyCompList = $null
$global:haTopology = $false
$global:primaryAdmin = $null
$global:indexedDocs = 0
$global:masterMerge = $false

# Template object for the host array:
$global:hostTemplate = New-Object psobject
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name hostName -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name components -Value 0
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name cpc -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name qpc -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name pAdmin -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name sAdmin -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name apc -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name crawler -Value $null
$global:hostTemplate | Add-Member -MemberType NoteProperty -Name index -Value $null

# Create the empty host array:
$global:hostArray = @()

# Template object for the HA group array:
$global:haTemplate = New-Object psobject
$global:haTemplate | Add-Member -MemberType NoteProperty -Name entity -Value $null
$global:haTemplate | Add-Member -MemberType NoteProperty -Name partition -Value -1
$global:haTemplate | Add-Member -MemberType NoteProperty -Name primary -Value $null
$global:haTemplate | Add-Member -MemberType NoteProperty -Name docs -Value 0
$global:haTemplate | Add-Member -MemberType NoteProperty -Name components -Value 0
$global:haTemplate | Add-Member -MemberType NoteProperty -Name componentsOk -Value 0

# Create the empty HA group array:
$global:haArray = @()

# Template object for the component/server table:
$global:compTemplate = New-Object psobject
$global:compTemplate | Add-Member -MemberType NoteProperty -Name Component -Value $null
$global:compTemplate | Add-Member -MemberType NoteProperty -Name Server -Value $null
$global:compTemplate | Add-Member -MemberType NoteProperty -Name Partition -Value $null
$global:compTemplate | Add-Member -MemberType NoteProperty -Name State -Value $null

# Create the empty component/server table:
$global:compArray = @()

# Get the SSA object and print SSA name:
GetSSA

# Get basic topology info and component health status
GetTopologyInfo

# Traverse list of components, determine properties and update $global:hostArray / $global:haArray
foreach ($searchComp in ($global:topologyCompList))
{
    PopulateHostHaList($searchComp)
}

# Analyze the component status:
foreach ($component in ($global:componentStateList))
{
    SearchComponentStatus($component)
}

# Look for selected info from detailed indexer diagnostics:
DetailedIndexerDiag

# Output list of components with state OK:
if ($global:compArray)
{
    $global:compArray | Sort-Object -Property Component | Format-Table -AutoSize
}
Write-Output ""

# Verify HA status for topology and index size limits:
VerifyHaLimits

# Verify that Host Controller HA (for dictionary repository) is OK:
VerifyHostControllerRepository

# Output components by server (for servers with multiple search components):
if ($global:haTopology -and ($global:searchHosts -gt 2))
{
    $componentsByServer = $false
    foreach ($hostInfo in $global:hostArray)
    {
        if ([int] $hostInfo.components -gt 1)
        {
            $componentsByServer = $true
        }
    }
    if ($componentsByServer)
    {
        Write-Output "Servers with multiple search components:"
        foreach ($hostInfo in $global:hostArray)
        {
            if ([int] $hostInfo.components -gt 1)
            {
                Write-Output "    $($hostInfo.hostName): $($hostInfo.pAdmin)$($hostInfo.sAdmin)$($hostInfo.index)$($hostInfo.qpc)$($hostInfo.cpc)$($hostInfo.apc)$($hostInfo.crawler)"
            }
        }
        Write-Output ""
    }
}

# Analytics Processing Job Status:
AnalyticsStatus

if ($global:masterMerge)
{
    Write-Output "Index Master Merge (de-fragment index files) in progress on one or more index components."
}

if ($global:serviceFailed -eq $false)
{
    Write-Output "Searchable items: $global:indexedDocs"
}

GetCrawlStatus
Write-Output ""
    
if ($global:unknownComponents)
{
    Write-Output "The following components are not reachable:"
    foreach ($uc in ($global:unknownComponents))
    {
        Write-Output "    $uc"
    }
    Write-Output "Recommended action: Restart or replace the associated server(s)"
    Write-Output ""
}

if ($global:degradedComponents)
{
    Write-Output "The following components are degraded:"
    foreach ($dc in ($global:degradedComponents))
    {
        Write-Output "    $dc"
    }
    Write-Output "Recommended action for degraded components:"
    Write-Output "    Component registering or resolving:"
    Write-Output "        This is normally a transient state during component restart or re-configuration. Re-run the script."

    if ($global:indexLeftBehind)
    {
        Write-Output "    Index component left behind:"
        if ($global:generationDifference)
        {
            Write-Output "        This is normal after adding an index component or index component/server recovery."
            Write-Output "        Indicates that the replica is being updated from the primary replica."
        }
        else
        {
            Write-Output "        Index replicas listed as degraded but index generation is OK."
            Write-Output "        Will get out of degraded state as soon as new/changed items are being idexed."
        }
    }
    Write-Output ""
}

if ($global:failedComponents)
{
    Write-Output "The following components are reported in error:"
    foreach ($fc in ($global:failedComponents))
    {
        Write-Output "    $fc"
    }
    Write-Output "Recommended action: Restart the associated server(s)"
    Write-Output ""
}

if ($global:serviceFailed)
{
    Write-Host -BackgroundColor Red -ForegroundColor Black "Search service overall state: Failed (no queries served)"
}
elseif ($global:serviceDegraded)
{
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Search service overall state: Degraded"
}
else
{
    Write-Host -BackgroundColor Green -ForegroundColor Black "Search service overall state: OK"
}
Write-Output ""