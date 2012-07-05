## PowerShell Function to set IIS logging locations on all or individual IIS web sites ##
## Important: This doesn't change Global 'centralBinaryLogFile' and 'centralW3CLogFile' locations in the applicationHost.config

Function Set-IISLogLocation {
<#
.SYNOPSIS
    This command will allow you to set the IIS log location on a server or multiple servers.
.DESCRIPTION
    This command will allow you to set the IIS log location on a server or multiple servers.
.PARAMETER computer
    Name of computer to set log location on
.PARAMETER logdir
    Location to set IIS logs to write to
.PARAMETER website
    Name of website to change the log location.
.NOTES
    Name: Set-IISLogLocation
    Author: Boe Prox
    DateCreated: 20Aug2010

.LINK

http://boeprox.wordpress.com; http://learn-powershell.net/2011/01/22/setting-iis-log-locations-with-powershell

.EXAMPLE
    Set-IISLogLocation -computer <server> -logdir "D:\logs" 

Description
-----------
This command will change the IIS log locations for each website on the server.
.EXAMPLE
    Set-IISLogLocation -computer <server> -logdir "D:\logs" -website "Default Web Site" 

Description
-----------
This command will change the IIS log locations for only the Default Web Site on a server. 

#>
[cmdletbinding(
    SupportsShouldProcess = $True,
    DefaultParameterSetName = 'default',
    ConfirmImpact = 'low'
)]
param(
    [Parameter(
        Mandatory = $False,
        ParameterSetName = '',
        ValueFromPipeline = $True)]
        [string]$computer,
    [Parameter(
        Mandatory = $False,
        ParameterSetName = '',
        ValueFromPipeline = $False)]
        [string]$logdir,
    [Parameter(
        Mandatory = $False,
        ParameterSetName = 'site',
        ValueFromPipeline = $False)]
        [string]$website
)
Process {
    ForEach ($c in $Computer) { 

            If (Test-Connection -comp $c -count 1) { 

                $sites = [adsi]"IIS://$c/W3SVC"
                $children = $sites.children
                ForEach ($child in $children) {
                    Switch ($pscmdlet.ParameterSetName) {
                       "default" {
                                If ($child.KeyType -eq "IIsWebServer") {
                                If ($pscmdlet.ShouldProcess($($child.servercomment))) {
                                    $child.Put("LogFileDirectory",$logdir)
                                    $child.SetInfo()
                                    Write-Host -fore Green "$($child.servercomment): Log location set to $logdir"
                                    }
                                }
                            }
                        "site" {
                                If ($child.KeyType -eq "IIsWebServer" -AND $child.servercomment -eq $website) {
                                If ($pscmdlet.ShouldProcess($($child.servercomment))) {
                                    $child.Put("LogFileDirectory",$logdir)
                                    $child.SetInfo()
                                    Write-Host -fore Green "$($child.servercomment): Log location set to $logdir"
                                    }
                                }
                            }
                        }
                    }
            }
        }
    }
}

# Example
Set-IISLogLocation -computer SATCHARON10 -logdir "D:\IIS\Logs"