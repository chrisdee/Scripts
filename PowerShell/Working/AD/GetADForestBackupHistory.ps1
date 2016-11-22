## Active Directory: PowerShell Script to check Active Directory Backup Dates on All Domains in a Forest ##

<#

Overview: PowerShell Script to check Active Directory Backup Dates on All Domains in a Forest. Returns the Domain; Domain Controller/s; and Partitions that were backed up

Usage: Edit the '$backup_age_threshold' variable to match your requirements and run the query

Requires: Active Directory PowerShell Module

Resource: https://www.shellandco.net/active-directory-backup-check

#>

Import-Module "ActiveDirectory"

$myForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$forestDN = (($myforest.Name).split(".")|%{"DC=$_"}) -join ","

$domain_list = $myForest.Domains.Name
$domainControllers = $myForest.GlobalCatalogs.Name

$array = @()
$backup_age_threshold = "1" #Change this threshold days value to match your requirements

$domain_list | % {
    $domain_fqdn = $_
    $dcname = Get-ADDomainController -Discover -Service ADWS -DomainName $domain_fqdn | select Hostname -first 1 | % { $_.Hostname }
    $Partitions = (Get-ADRootDSE -Server $domain_fqdn).namingContexts
    $Partitions | % {
        $Partition = $_
        $object = Get-ADObject -Identity $Partition -Properties msDS-ReplAttributeMetaData -Server $dcname
        $Object."msDS-ReplAttributeMetaData" | ForEach-Object {
            $MetaData = [XML]$_.Replace("`0","")
            $MetaData.DS_REPL_ATTR_META_DATA | ForEach-Object {
                If ($_.pszAttributeName -eq "dSASignature") {
                    $backup_date = Get-Date $_.ftimeLastOriginatingChange -format "dd.MM.yyyy HH:mm:ss"
                    $backup_age = ((Get-date) - (Get-Date $_.ftimeLastOriginatingChange)).TotalDays
                    $Properties = @{domain=$domain_fqdn;dc=$dcname;partition=$Partition;backup_date=$backup_date;backup_age=$backup_age}
                    $Newobject = New-Object PSObject -Property $Properties
                    $array += $Newobject
                }
            }
        }
    }
}
$array | % {
	if ($_.backup_age -gt $backup_age_threshold) {
		write-host $_.domain "/" ($_.dc) "/" "Partition" $_.partition "/" "Backup is older than the configured threshold of" $backup_age_threshold "days" "/" "Last backup occured on" $_.backup_date -foregroundcolor red
	}
	else {
		write-host $_.domain "/" ($_.dc) "/" "Partition" $_.partition "/" "Backup is OK" "/" "Last backup occured on" $_.backup_date -foregroundcolor green
	}
}