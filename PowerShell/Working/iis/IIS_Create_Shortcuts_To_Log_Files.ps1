## IIS Server: PowerShell Script to create Short Cuts to the IIS Logs by their 'friendly' Site Names ##

<#

Overview: This PowerShell Script creates a Shortcuts directory, then creates shortcuts to the IIS Log file directories based off of their 'friendly' IIS website name

Usage: Edit the following variables to match your environment: '$shortcutbasedir'; '$shortcutsdir'

The Script must be run locally on the web server, and must have sufficient access to the IIS and specified shortcuts directory

Resouce: https://blog.netnerds.net/2014/07/powershell-create-human-readable-shortcuts-to-iis-log-file-directories

#>
#############################################################
 
# Set the folder where the Shortcuts folder will be 
# created and populated. If left at default, it will use IIS's 
# global default log directory. Usually C:\inetpub\logs\LogFiles
 
$shortcutbasedir = "default" #Change this to match your environment
 
#############################################################
# 
# No additional changes are required below
# 
#############################################################
 
Import-Module "WebAdministration" -ErrorAction Stop
 
# Get global log file directory from IIS
if ($shortcutbasedir -eq "default") {
    $xml = [xml](Get-Content C:\Windows\System32\inetsrv\config\applicationHost.config)
    $shortcutbasedir = $xml.configuration."system.applicationHost".log.centralW3CLogFile.directory
}
 
# Convert old school env variables to PowerShell env variable if needed
if ($shortcutbasedir -match "%") {
    $sc = ($shortcutbasedir -split "%")
    $sysvar = $sc[1]
    $sysvar = (get-item env:$sysvar).Value
    $shortcutbasedir = $sysvar + $sc[2]
}
 
$shortcutsdir = "$shortcutbasedir\Shortcuts" #Change the 'Shortcuts' to match your environment
 
# If shortcuts directory doesn't exist, create it. Otherwise, empty it out.
if (!(Test-path $shortcutsdir)) { 
    $null = New-Item -ItemType Directory -Path $shortcutsdir 
    } else { 
    $null = Remove-Item "$shortcutsdir\*"
}
 
# Get websites from IIS
$sites = Get-ChildItem IIS:\Sites
 
    foreach($site in $sites)
    {
        # Get website info
        $sitename = $site.Name
        $siteid = $site.id
        $basedir = (Get-ItemProperty IIS:\Sites\$sitename -name logFile.directory).Value
        $folder = "$basedir\W3SVC$siteid"
 
        # Create the shortcut
        $wshshell = New-Object -ComObject WScript.Shell
        $shortcut = $wshshell.Createshortcut("$shortcutsdir\$sitename.lnk")
        $shortcut.TargetPath = "$basedir\W3SVC$siteid"
        $shortcut.Save()
    }