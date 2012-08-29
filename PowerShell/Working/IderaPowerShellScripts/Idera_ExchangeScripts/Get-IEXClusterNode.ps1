## =====================================================================
## Title       : Get-IEXClusterNode 
## Description : Retrieve a node in clustered mailbox server (CMS)
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXClusterNode [[-ClusteredMailboxServerName] <Object>] [-Passive]
##   
## Output      : System.String
## Usage       : 
##              1. Retrieve an active node in clustered mailbox server CMS1
##              Get-IEXActiveNode $ClusteredMailboxServerName CMS1        
##
##              2. Retrieve a passive node in clustered mailbox server CMS1
##              Get-IEXActiveNode $ClusteredMailboxServerName CMS1 -Passive
##
##              3. Move passive node in clusted mailbox server CMS1
##              Move-ClusteredMailboxServer -Identity CMS1 -TargetMachine (Get-IEXClusterNode CMS1 -passive) -MoveComment "Let's move!"  -whatif
## Notes       :
## Tag         : Exchange 2007, cluster, mailbox, node, get
## Change log  :
## ===================================================================== 


#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
 
function Get-IEXClusterNode {
    param (
    $ClusteredMailboxServerName = $(Throw 'Please, specify clustered mailbox server name.'),
    [switch]$Passive
    )

    $Nodes = Get-ClusteredMailboxServerStatus -Identity $ClusteredMailboxServerName |
    select -expand OperationalMachines

    if ($Passive) {
        $Nodes | where {$_ -notmatch 'Active'}
    }
    else {
        $Node = $Nodes | where {$_ -cmatch 'Active'}
        $Node.substring(0,$Node.indexOf(" "))
    }
}
