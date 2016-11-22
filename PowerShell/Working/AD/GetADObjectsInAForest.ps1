## Active Directory: PowerShell Script to Search for Forest Wide Objects ##

<#

Overview: PowerShell Script to search for objects forest wide. The search is based on a LDAP filter

Usage: Edit the parameters under the object search filter under '$objSearcher.Filter' and run the query

Requires: Active Directory PowerShell Module

Resource: https://www.shellandco.net/search-an-object-forest-wide

#>

Import-Module "ActiveDirectory"

#Get Domain List
$objForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$DomainList = @($objForest.Domains | Select-Object Name)
$Domains = $DomainList | foreach {$_.Name}

#Act on each domain
foreach($Domain in ($Domains)) {
	Write-Host "Checking $Domain" -fore red
	$ADsPath = [ADSI]"LDAP://$Domain"
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher($ADsPath)
	#The filter
	$objSearcher.Filter = "(&(objectCategory=user)(mail=*toto*))" ##Change this 'Filter' to match what your search scope on AD Object Category and Attribute
	$objSearcher.SearchScope = "Subtree"
	
	$colResults = $objSearcher.FindAll()
	
	foreach ($objResult in $colResults) {
		$objArray = $objResult.GetDirectoryEntry()
		write-host $objArray.DistinguishedName ";" $objArray.mail ";" $objArray.ProxyAddresses "`r"
	}
}