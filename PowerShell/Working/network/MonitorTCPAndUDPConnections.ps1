#######################################################################################################################
# File:             LogPortsUsedByApplication.ps1                                                                     #
# Version:          1.1                                                                                               #
# Author:           Alexander Petrovskiy                                                                              #
# Publisher:        Alexander Petrovskiy, SoftwareTestingUsingPowerShell.WordPress.Com                                #
# Copyright:        © 2011 Alexander Petrovskiy, SoftwareTestingUsingPowerShell.WordPress.Com. All rights reserved.   #
# Usage:            This scripts collects network connections information in two ways,                                #
#                   using the netstat -ao command to display hostnames and                                            #
#                        .\LogPortsUsedByApplication.ps1 $false                                                       #
#                   using the netstat -ano command to provide only addresses                                          #
#                        .\LogPortsUsedByApplication.ps1 $true                                                        #
#                   or                                                                                                #
#                        .\LogPortsUsedByApplication.ps1                                                              #
#                   Please provide feedback in the SoftwareTestingUsingPowerShell.WordPress.Com blog.                 #
#######################################################################################################################
param(
      [bool]$Numeric = $true
     )

cls
Set-StrictMode -Version Latest

#region user settings
# type below anything that will be used further in the following command:
# (Get-Process $applications[$i]).Id.ToString()
[String[]]$applications = @(
                            "ServiceName",
                            "GUIApplicationName",
                            "UtilityName"
                            );
# type here anything that you need to extract as a string
# i.e. hostname, IP address, port number or any their combination
[String[]]$hosts = @(
                            "hostname",
                            "192.168.1.1",
                            "192.168.100.100",
                            "hostname.dnszone.com"
                            );
#region user settings
#region logs preparation
[string]$netstatParameters = "";
[string]$logfileFull = "";
[string]$logfileSelected = "";
[string]$logfileSqueezed = "";
if ($Numeric){
    $logfileFull = "$($Env:USERPROFILE)\$($Env:COMPUTERNAME)_netstat_fullN.txt";
    $logfileSelected = "$($Env:USERPROFILE)\$($Env:COMPUTERNAME)_netstat_selectedN.txt";
    $logfileSqueezed = "$($Env:USERPROFILE)\$($Env:COMPUTERNAME)_netstat_squeezedN.txt";
    $netstatParameters = "-ano";}
else {
    $logfileFull = "$($Env:USERPROFILE)\$($Env:COMPUTERNAME)_netstat_full.txt";
    $logfileSelected = "$($Env:USERPROFILE)\$($Env:COMPUTERNAME)_netstat_selected.txt";
    $logfileSqueezed = "$($Env:USERPROFILE)\$($Env:COMPUTERNAME)_netstat_squeezed.txt";
    $netstatParameters = "-ao";}
Remove-Item -Path $logfileFull -Force -ErrorAction:SilentlyContinue;
Remove-Item -Path $logfileSelected -Force -ErrorAction:SilentlyContinue;
Remove-Item -Path $logfileSqueezed -Force -ErrorAction:SilentlyContinue;

$recordsDict =
    new-object "System.Collections.Generic.Dictionary``2[[System.String, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089],[System.String, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]";
[String[]]$whatToSearch = $applications + $hosts;
[string]$hostname = $Env:COMPUTERNAME + "`t";
#endregion logs preparation

#region functions
    #region function Get-CurrentTime
function Get-CurrentTime
    <#
        .SYNOPSIS
            The Get-CurrentTime function is used to write in the timestamp in the log file.

        .DESCRIPTION
            The Get-CurrentTime functions is used for getting the current time of operation.
            As s time source used [System.DateTime]::Now.TimeOfDay property.

        .EXAMPLE
            PS C:\> Get-CurrentTime

        .OUTPUTS
            System.String
    #>
{    $timeOfDay = [System.DateTime]::Now.TimeOfDay;
    $time = "$($timeOfDay.Hours):$($timeOfDay.Minutes):$($timeOfDay.Seconds)`t";
    return $time;}
    #endregion function Get-CurrentTime
#endregion functions

[bool]$updateReport = $false;
netstat "$($netstatParameters)" 1 | `
     %{
        if ($_.Length -gt 0){
            [string]$currentTime = Get-CurrentTime + "`t";
            "$($hostname)$($currentTime)*`t$($_)" >> $logfileFull;
            for ($private:i = 0; $private:i -lt $applications.Length; $private:i++)
            {
                if ((Get-Process $applications[$private:i] -ErrorAction:SilentlyContinue) -ne $null)
                {
                    if ($_.Contains((Get-Process $applications[$private:i]).Id.ToString()))
                    {
                        "$($hostname)$($currentTime)$($applications[$private:i])`t$($_)" >> $logfileSelected;
                        try{                    
                            $recordsDict.Add("$($hostname)`t$($applications[$private:i])`t$($_)", "");
                            $updateReport = $true
                            } catch{}
                    }
                }
            }
            for ($private:i = 0; $private:i -lt $hosts.Length; $private:i++)
            {
                if ($_.Contains($hosts[$private:i]))
                {
                    [string]$activityMarker = $_;
                    if ($activityMarker -match "(?<=[\x20])[\d]+?$")
                    {
                        try{
                            $activityMarker = (Get-Process -Id $matches[0] -ErrorAction:SilentlyContinue).ProcessName;
                        }catch{}}
                    else{$activityMarker = $hosts[$private:i];}
                    "$($hostname)$($currentTime)$($activityMarker)`t$($_)" >> $logfileSelected;
                    try{                    
                        $recordsDict.Add("$($hostname)`t$($activityMarker)`t$($_)", "");
                        $updateReport = $true
                        } catch{}
                }
            }
            if ($updateReport){
                # re-write the squeezed report
                Remove-Item -Path "$($logfileSqueezed)_previous" `
                    -Force -ErrorAction:SilentlyContinue;
                Copy-Item -Path $logfileSqueezed -Destination "$($logfileSqueezed)_previous"
                Remove-Item -Path $logfileSqueezed -Force -ErrorAction:SilentlyContinue;
                foreach($key in $recordsDict.Keys)
                {
                    "$($key)" >> $logfileSqueezed;
                }
                $updateReport = $false
            }
        }
    }