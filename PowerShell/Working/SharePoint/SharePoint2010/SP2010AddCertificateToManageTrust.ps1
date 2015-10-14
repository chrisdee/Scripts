## SharePoint Server: PowerShell Script to Add a Certificate File (.cer) to the Farm Trust ##

## Overview: Adds a certificate (.cer) to the Farms trust relationship manager (/_admin/ManageTrust.aspx)

## Environments: SharePoint Server 2010 / 2013 Farms

## Usage: Edit the Variables to match your environment and run the script

### Start Variables ###

$CertPath = "C:\BoxBuild\Certs\WorkflowFarm.cer"
$TrustName = "Workflow Manager Farm"

### End Variables ###

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$trustCert = Get-PfxCertificate $CertPath

New-SPTrustedRootAuthority -Name $TrustName -Certificate $trustCert