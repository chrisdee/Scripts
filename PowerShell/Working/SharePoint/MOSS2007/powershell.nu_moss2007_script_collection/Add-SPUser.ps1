##################################################################################
#
#
#  Script name: Add-SPUser.ps1
#
#  Author:      	niklas.goude@zipper.se
#  Homepage:    	www.powershell.nu
#  Company:		www.zipper.se
#
##################################################################################

param([string]$url, [string]$Group, [string]$Domain, [String]$sAMAccountName, [string]$mail, [string]$FullName, [switch]$help)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

function GetHelp() {


$HelpText = @"

DESCRIPTION:
NAME: Add-SPUser
Adds A New User To A Group in SHaerPoint

PARAMETERS: 
-url		Url to SharePoint Site
-Group		Name of New Group
-Domain		Role Of New Group
-sAMAccountName	Users sAMAccountName
-mail		Users email Address
-FullName	Users FullNam

SYNTAX:

Add-SPUser -url http://moss -Group "New Group" -Domain "powershell.nu" -sAMAccountName "goude" -mail "niklas.goude@zipper.se" -FullName "Niklas Goude"

Adds the User to the Group "New Group"

Add-SPUser -help

Displays the help topic for the script

"@
$HelpText

}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Add-SPUser ([string]$url, [string]$Group, [string]$Domain, [String]$sAMAccountName, [string]$mail, [string]$FullName) {

	$SPSite = Get-SPSite $url
	$SPSite.RootWeb.SiteGroups[$Group].AddUser(($Domain + "\" + $sAMAccountName),$mail, $FullName,"")

	$SPSite.Dispose()
}

if($help) { GetHelp; Continue }
if($url -AND $Group -AND $Domain -AND $sAMAccountName -AND $mail -AND $FullName) { Add-SPUser -url $url -Group $Group -Domain $Domain -sAMAccountName $sAMAccountName -mail $mail -FullName $FullName }