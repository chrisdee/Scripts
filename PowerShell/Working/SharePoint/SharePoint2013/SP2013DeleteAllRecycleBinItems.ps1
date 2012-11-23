## SharePoint Server: PowerShell Function to Clear All Recycle Bin Items ##

# Overview: Clear all Recycle Bin Items for a site collection (Both Recycle Bin Stages)
# Environments: MOSS 2007, and SharePoint Server 2010 / 2013 Farms   
# Function:  Clear-All-RecycleBin
# Parameters: SiteCollectionURL : URL for Site Collection
# Usage Example: Clear-All-RecycleBin "http://myWebApplication/sites/mySiteCollection/"

function Clear-All-RecycleBin([string]$SiteCollectionURL)
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null
	$site = new-object Microsoft.SharePoint.SPSite($SiteCollectionURL)
	Write-Host "SiteCollectionURL", $SiteCollectionURL

	$SitecollectionRecycleBin = $site.RecycleBin
	Write-Host "SitecollectionRecycleBin Number", $SitecollectionRecycleBin.Count

	for ($x = $SitecollectionRecycleBin.Count ; $x -gt 0 ; $x--) 
	{
		$Item = $SitecollectionRecycleBin.Item($x-1)
		$SitecollectionRecycleBin.Delete($Item.ID)
	}
	Write-Host "SitecollectionRecycleBin Number", $SitecollectionRecycleBin.Count
}

