## =====================================================================
## Title       : Get-IADFSMORoleHolder
## Description : Retrieve the forest and domain FSMO roles holders.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input              
##                     
## Output      : System.Management.Automation.PSCustomObject
## Usage       :  Get-IADFSMORoleHolder
##            
## Notes       :
## Tag         : fsmo, forest, domain, activedirectory
## Change log  :
## =====================================================================


   

function Get-IADFSMORoleHolder 
{

    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

    $pso = "" | select Naming,Schema,Pdc,Rid,Infrastructure

    $pso.Naming = $forest.NamingRoleOwner
    $pso.Schema = $forest.SchemaRoleOwner
    $pso.Pdc = $domain.PdcRoleOwner
    $pso.Rid = $domain.RidRoleOwner
    $pso.Infrastructure = $domain.InfrastructureRoleOwner
    $pso
}