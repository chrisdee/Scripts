## SharePoint Server: PowerShell Script to Export / Import / Delete Managed Properties from a Search Service Application (SSA) ##

#------------------------------------------------------------------------------------------------------------------------------
# Name:             SP2013ExportImportSearchServiceManagedProperties.ps1   
# Description:      This script has three switch to:
#					- export a list of managed properties (optionally filtered - '*' Wild card filters are supported like 'A*') 
#					- import a list of managed properties with crawled property mapping
#                   - delete a list of managed properties
#                    
# Usage:            Run the script passing paramters ServiceApp, Import|Export|Delete and Filter  
#  
# Resource: http://gallery.technet.microsoft.com/Powershell-script-to-09ffa974
#
#Usage Examples:

#.\SP2013ExportImportSearchServiceManagedProperties.ps1 -serviceapp "Search Service Application" -export -filter "AboutMe"

#.\SP2013ExportImportSearchServiceManagedProperties.ps1 -serviceapp "Search Service Application" -import

#.\SP2013ExportImportSearchServiceManagedProperties.ps1 -serviceapp "Search Service Application" -delete -filter "AboutMe"

#"AboutMe" is a sample filter ('*' Wild card filters are also supported)
#------------------------------------------------------------------------------------------------------------------------------ 

Param([Parameter(Mandatory=$true)] 
      [String]$serviceapp,
      [Parameter(Mandatory=$false,ParameterSetName='Export')]
      [Parameter(Mandatory=$true,ParameterSetName ="Delete")]
      [String]$filter,
      [Parameter(ParameterSetName='Import')]
      [switch]$import,
      [Parameter(ParameterSetName='Export')]
      [switch]$export,
      [Parameter(ParameterSetName='Delete')]
      [switch]$delete
)

if ((gsnp MIcrosoft.SharePoint.Powershell -ea SilentlyContinue) -eq $null){
    asnp MIcrosoft.SharePoint.Powershell -ea Stop
}

$logfile = ".\export-managed-properties.csv"
$importlog = ".\import-managed-properties.log"
$importlogerr = ".\import-managed-properties-errors.log"

function ManagedPropertyTypes($type){
    switch ($type){  
        "text" {$type = 1}  
        "integer" {$type = 2}  
        "decimal" {$type = 3} 
        "DateTime" {$type = 4} 
        "YesNo" {$type = 5} 
        "Binary" {$type = 6} 
        "Double" {$type = 7} 
        default {$type = 1} 
    }

    return $type
}

if ((Get-SPEnterpriseSearchServiceApplication $serviceapp -ea SilentlyContinue) -eq $null){
    Write-Host "Enterprise Search Service Application $serviceapp has not been found" -ForegroundColor Red
    exit
} else {
    $ssa = Get-SPEnterpriseSearchServiceApplication $serviceapp

    Write-Host "Enterprise Search Service Application $serviceapp has been found" -ForegroundColor Green
}

if ($export){
    if ((Get-ChildItem -Name $logfile -ea SilentlyContinue) -ne $null){
        Clear-Content $logfile
        ac $logfile "Name,Description,ManagedType,Searchable,FullTextQueriable,Queryable,Retrievable,Refinable,Sortable,HasMultipleValues,SafeForAnonymous,Mapping";
    } else {
        ac $logfile "Name,Description,ManagedType,Searchable,FullTextQueriable,Queryable,Retrievable,Refinable,Sortable,HasMultipleValues,SafeForAnonymous,Mapping";
    }

    if ($filter -ne $null){
        Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $ssa -Limit All | ?{$_.Name -like "$($filter)*"} | %{
        
            $mp = $_;
            $mpmap = @();

            Get-SPEnterpriseSearchMetadataMapping -SearchApplication $ssa -ManagedProperty $mp.Name | %{
                $mpmap += $_.CrawledPropertyName
            }

            ac $logfile "$($mp.Name),$($mp.Description),$(ManagedPropertyTypes $mp.ManagedType),$($mp.Searchable),$($mp.FullTextQueriable),$($mp.Queryable),$($mp.Retrievable),$($mp.Refinable),$($mp.Sortable),$($mp.HasMultipleValues),$($mp.SafeForAnonymous),$($mpmap -join '|')"

        }
    } else {
        Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $ssa -Limit All | %{
        
            $mp = $_;
            $mpmap = @();

            Get-SPEnterpriseSearchMetadataMapping -SearchApplication $ssa -ManagedProperty $mp.Name | %{
                $mpmap += $_.CrawledPropertyName
            }
        
            ac $logfile "$($mp.Name),$($mp.Description),$(ManagedPropertyTypes $mp.ManagedType),$($mp.Searchable),$($mp.FullTextQueriable),$($mp.Queryable),$($mp.Retrievable),$($mp.Refinable),$($mp.Sortable),$($mp.HasMultipleValues),$($mp.SafeForAnonymous),$($mpmap -join '|')"
        }
    }
}

if ($import){
    if ((Get-ChildItem $logfile -ea SilentlyContinue) -eq $null){
        Write-Host "The export file has not been found" -ForegroundColor Red
        exit
    } else {

        Import-Csv $logfile -Delimiter "," | %{
            $mp = $_;

            if ((Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $ssa -Identity $mp.Name -ea SilentlyContinue) -eq $null){
                try {
                    $newmp = New-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $ssa -Name $mp.Name -Description $mp.Description -Type $mp.ManagedType -FullTextQueriable:([bool]::Parse($mp.FullTextQueriable)) -Retrievable:([bool]::Parse($mp.Retrievable)) -Queryable:([bool]::Parse($mp.Queryable)) -SafeForAnonymous:([bool]::Parse($mp.SafeForAnonymous)) -EA Stop
                    ac $importlog "$(Get-Date),$($mp.Name),[INF],Managed Property,"

                    #$ump = Get-SPEnterpriseSearchMetadataManagedProperty $mp.Name -SearchApplication $ssa  
                    $newmp.Searchable = ([bool]::Parse($mp.Searchable))
                    $newmp.Refinable = ([bool]::Parse($mp.Refinable))
                    $newmp.Sortable = ([bool]::Parse($mp.Sortable))
                    $newmp.HasMultipleValues = ([bool]::Parse($mp.HasMultipleValues))
                    $newmp.Update() 
                    
                    if (($mp.Mapping).Length -gt 0){
                        
                        $cps = $mp.Mapping

                        foreach ($term in $cps.split("|")){

                            Write-Host "Processing Crawled Property $($term) on Managed Property $($mp.Name)" -ForegroundColor Cyan

                            if ((Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $ssa -Name $term -EA SilentlyContinue) -ne $null){
                            
                                $cp = Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $ssa -Name $term

                                try {
                                    New-SPEnterpriseSearchMetadataMapping -SearchApplication $ssa -ManagedProperty $newmp -CrawledProperty $cp[0] -EA Stop
                                    ac $importlog "$(Get-Date),$($mp.Name),[INF],Metadata Mapping,$term"

                                    if($cp -is [system.array]){
                                        ac $importlog "$(Get-Date),$($mp.Name),[WRN],Metadata Mapping,$term,More than one crawled property selected only the first has been used" 
                                    }
                                } catch {
                                    Write-Host "Something went wrong :) $($Error[0].Exception.Message)" -ForegroundColor Red
                                    ac $importlog "$(Get-Date),$($mp.Name),[ERR],Metadata Mapping,$term"
                                    ac $importlogerr "$(Get-Date),$($mp.Name),[ERR],Metadata Mapping,$($Error[0].Exception.Message)"
                                }
                            } else {
                                Write-Host "Crawled property $($term) does not exists" -ForegroundColor Red
                                ac $importlog "$(Get-Date),$($mp.Name),[ERR],Crawled Property,$term"
                                ac $importlogerr "$(Get-Date),$($mp.Name),[ERR],Crawled Property,$term does not exists"
                            }
                        }
                    }
                } catch {
                    Write-Host "Something went wrong :) $($Error[0].Exception.Message)" -ForegroundColor Red
                    ac $importlog "$(Get-Date),$($mp.Name),[ERR],"
                    ac $importlogerr "$(Get-Date),$($mp.Name),[ERR],Managed Property,$($Error[0].Exception.Message)"
                }
            } else {
                Write-Host "Managed property $($mp.Name) already exists" -ForegroundColor Red
                ac $importlog "$(Get-Date),$($mp.Name),[WRN],Managed Property,Managed property already exists"
            }
        }
    }
}

if ($delete){
    Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $ssa -Limit All | ?{$_.Name -like "$($filter)*"} | %{
        $mp = $_;
        $mp.DeleteAllMappings();
        $mp.Delete();
    }
}
