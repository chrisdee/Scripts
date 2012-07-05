## PowerShell: Script To Show Percentage Graph Of Disk Space Used For Each Drive On A Machine ##
## Resource: http://jdhitsolutions.com/blog/2012/06/friday-fun-another-powershell-console-graph
## Usage Example: ./DiskSpacePercentageUsedGraph.ps1 YourMachineName

<#
 -----------------------------------------------------------------------------
 Script: DiskSpacePercentageUsedGraph.ps1
 Version: 0.1
 Author: Jeffery Hicks
    http://jdhitsolutions.com/blog
    http://twitter.com/JeffHicks
    http://www.ScriptingGeek.com
 Date: 6/1/2012
 Keywords: Console, Graphing, host
 Comments:

 This is a demo script showing how to create a bar graph
 in the PowerShell console. Don't run this in the ISE.
 You won't get the same result.

 "Those who forget to script are doomed to repeat their work."

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 -----------------------------------------------------------------------------
 #>
 
Param([string]$computername=$env:computername)

Clear-Host

#get the data
$drives=Get-WmiObject -Class Win32_LogicalDisk -Filter "drivetype=3" -computername $computername

#define a set of colors for the graphs
$colors=@("Yellow","Magenta","Green","Cyan","Red")

#set cursor position
$Coordinate = New-Object System.Management.Automation.Host.Coordinates
$Coordinate.X= 10 
$Coordinate.Y= [int]($host.ui.rawui.WindowSize.Height -5)

#save starting coordinates
$startY=$Coordinate.Y
$startX=$Coordinate.X

#counter for colors
$c=0

#adjust Y so we can write the caption
$Coordinate.Y+=1

foreach ($drive in $drives) {
    #set the color to the first color in the array of colors
    $color=$colors[$c]
    $legend=$drive.DeviceID
    #calculate used space value
    $used=$Drive.Size - $Drive.FreeSpace
    [int]$usedValue=($used/($drive.size))*10
    #adjust for values less than 0 so something gets graphed
    if ($usedValue -le 0) {
       [int]$usedValue=($used/($drive.size))*50
    }
    
    #format usage as a percentage
    $usedPer="{0:p2}" -f ($used/($drive.size))
    #set the cursor to the new coordinates
    $host.ui.rawui.CursorPosition=$Coordinate
    #write the caption
    write-host $legend -nonew
    #move the Y coordinate up to start the graph
    $coordinate.Y-=1

    for ($i=$usedValue;$i -gt 0;$i--) {
      $host.ui.rawui.CursorPosition=$Coordinate
      #draw the color space for the graph
      write-host "    " -BackgroundColor $color -nonewline
      #move Y up 1
      $coordinate.y--
      #repeat until we reach the $usedValue
    }
    #set new coordinate
    $host.ui.rawui.CursorPosition=$Coordinate
    #write the usage percentage at the top of the bar
    write-host $usedPer -nonewline
      
    #reset Y to where we started + 1
    $Coordinate.Y=($startY+1)
    #move X to the right
    $coordinate.x+=8
    #reset coordinates
    $host.ui.rawui.CursorPosition=$Coordinate
    #increment the color counter
    $c++

    #repeat for the next drive
   
} #foreach

#reset coordinates so we can write a legend
$coordinate.Y=$StartY+2
$coordinate.X=$startX
$host.ui.rawui.CursorPosition=$Coordinate
write-host ("Drive Usage % for {0}" -f $drives[0].__SERVER)

#move cursor to bottom of the screen and write a blank line
$Coordinate.X=1
$coordinate.Y=[int]($host.ui.rawui.WindowSize.Height-2)
$host.ui.rawui.CursorPosition=$Coordinate
write-host ""

#your PowerShell prompt will now be displayed