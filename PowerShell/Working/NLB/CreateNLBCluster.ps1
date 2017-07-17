## Windows NLB: PowerShell Script to Install and Configure a 2 Node NLB Cluster ##

<#

Overview: PowerShell Script that installs the appropriate Windows NLB features and creates a 2 Node NLB cluster with the appropriate Cluster Port Rules

Usage: Edit the Variables section below to match your environment and run the script on the Primary machine that you want to create the NLB cluster for

#>

## Start Variables ##
$ClusterName          = "Your-Cluster-Name"
$ClusterInterfaceName = "Cluster-NIC-Name"
$ClusterIP            = "172.27.7.64"
$SecondNodeName       = "Your-VM-Name"
## End Variables ##

## Install First NLB Node ##
## Install NLB feature (and RSaT)
Install-windowsfeature NLB,RSAT-NLB
    
## Load module (should be automatic in W2012/2012R2)
Import-Module NetworkLoadBalancingClusters

## Create NLB Cluster
New-NLBCluster -Interface $ClusterInterfaceName -OperationMode Multicast -ClusterPrimaryIP $ClusterIP -ClusterName $ClusterName

## Configure NLB Cluster Port Rules (add additional Ports and change the -Protocol and -Affinity properties if required)
Add-NLBClusterPortRule -Interface $ClusterInterfaceName -StartPort "80"   -EndPort "80"   -Protocol TCP -Affinity Single
Add-NLBClusterPortRule -Interface $ClusterInterfaceName -StartPort "443"  -EndPort "443"  -Protocol TCP -Affinity Single

## Review Node Config/Status
Get-NLBClusterNode | Format-List *

## Install / Configure Second NLB Node remotely ##
## Install NLB feature (and RSaT)
Invoke-Command -Computername $SecondNodeName -Command {Install-Windowsfeature NLB,RSAT-NLB}

## Join NLB Cluster
Add-NlbClusterNode -InterfaceName $ClusterInterfaceName -NewNodeName $SecondNodeName -NewNodeInterface $ClusterInterfaceName

## Review Nodes Config/Status
Get-NLBClusterNode | Format-List *


