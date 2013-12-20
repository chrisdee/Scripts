## ADFS: PowerShell Script That Uses The ADFS PowerShell Snapin To Export And Import Relying Party Trust Claim Rules ##
## Resources: http://kingofidentity.wordpress.com/2011/04/23/backing-up-and-restoring-claims-in-adfs-2-0; http://botsikas.blogspot.ch/2012/11/adfs-export-and-import-claim.html

Add-PSSnapin "Microsoft.ADFS.PowerShell" -ErrorAction SilentlyContinue

##### BEGIN VARIABLES #####
$SourceRelyingPartyTrust = "ServiceNow Dev Instance" #The name of your Source Relying Party Trust
$TargetRelyingPartyTrust = "ServiceNow Prod Instance" #The name of your Target Relying Party Trust
$XMLFilePath = "C:\BoxBuild\Scripts\PowerShell\RelyingPartyTrustClaimRules.xml" #The file path and name of the Claim Rules XML export
##### END VARIABLES #####

##Export Relying Party Trust Claims
Get-ADFSRelyingPartyTrust -Name $SourceRelyingPartyTrust | Export-Clixml $XMLFilePath

##Import Relying Party Trust Claims
Import-Clixml $XMLFilePath | foreach-object {Set-ADFSRelyingPartyTrust -TargetName $TargetRelyingPartyTrust -IssuanceTransformRules $_.IssuanceTransformRules}