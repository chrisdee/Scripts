## SharePoint Server: Determine Your Farm ID With PowerShell ##

## Environments: Works on MOSS 2007 and SharePoint Server 2010 Farms

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$spFarm=[Microsoft.SharePoint.Administration.SPfarm]::Local
$spFarm.Id
