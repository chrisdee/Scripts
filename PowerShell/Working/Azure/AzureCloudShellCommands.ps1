## Azure: PowerShell Commands For Managing Azure Cloud Shell ##

#Get CloudDrive details including Cloud Shell Directory (MountPoint)
Get-CloudDrive

#Dismount CloudDrive will dismount the Azure file share from the current storage account
Dismount-CloudDrive

#HTML Snippet to Embed an Azure Cloud Shell Session in a HTML Page

<a style="cursor:pointer" onclick='javascript:window.open("https://shell.azure.com", "_blank", "toolbar=no,scrollbars=yes,resizable=yes,menubar=no,location=no,status=no")'><image src="https://shell.azure.com/images/launchcloudshell.png" /></a>