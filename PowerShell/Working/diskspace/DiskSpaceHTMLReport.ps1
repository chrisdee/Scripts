## PowerShell: Script To Show HTML Report / Graph Of Disk Space Used For Each Drive On A Machine ##
## Resource: http://jdhitsolutions.com/blog/2012/02/create-html-bar-charts-from-powershell
## Usage Examples: ./DiskSpaceHTMLReport.ps1 YourMachineName
## 				   ./DiskSpaceHTMLReport.ps1 "YourMachineName1", "YourMachineName2"

Param (
[string[]]$computers=@($env:computername),
[string]$Path="DiskSpaceReport.htm" #Change this to a different location if you need to
)

$Title="Drive Report"

#embed a stylesheet in the html header
$head = @"
<style>
body { background-color:#FFFFFF;
       font-family:Tahoma;
       font-size:12pt; }
td, th { border:1px solid #000033; 
         border-collapse:collapse; }
th { color:white;
     background-color:#000033; }
table, tr, td, th { padding: 0px; margin: 0px }
table { margin-left:10px; }
</style>
<Title>$Title</Title>
<br>
"@ 

#define an array for html fragments
$fragments=@()

#get the drive data
$data=get-wmiobject -Class Win32_logicaldisk -filter "drivetype=3" -computer $computers

#group data by computername
$groups=$Data | Group-Object -Property SystemName

#this is the graph character
[string]$g=[char]9608 

#create html fragments for each computer
#iterate through each group object
        
ForEach ($computer in $groups) {
    
    $fragments+="<H2>$($computer.Name)</H2>"
    
    #define a collection of drives from the group object
    $Drives=$computer.group
    
    #create an html fragment
    $html=$drives | Select @{Name="Drive";Expression={$_.DeviceID}},
    @{Name="SizeGB";Expression={$_.Size/1GB  -as [int]}},
    @{Name="UsedGB";Expression={"{0:N2}" -f (($_.Size - $_.Freespace)/1GB) }},
    @{Name="FreeGB";Expression={"{0:N2}" -f ($_.FreeSpace/1GB) }},
    @{Name="Usage";Expression={
      $UsedPer= (($_.Size - $_.Freespace)/$_.Size)*100
      $UsedGraph=$g * ($UsedPer/2)
      $FreeGraph=$g* ((100-$UsedPer)/2)
      #I'm using place holders for the < and > characters
      "xopenFont color=Redxclose{0}xopen/FontxclosexopenFont Color=Greenxclose{1}xopen/fontxclose" -f $usedGraph,$FreeGraph
    }} | ConvertTo-Html -Fragment 
    
    #replace the tag place holders. It is a hack but it works.
    $html=$html -replace "xopen","<"
    $html=$html -replace "xclose",">"
    
    #add to fragments
    $Fragments+=$html
    
    #insert a return between each computer
    $fragments+="<br>"
    
} #foreach computer

#add a footer
$footer=("<br><I>Report run {0} by {1}\{2}<I>" -f (Get-Date -displayhint date),$env:userdomain,$env:username)
$fragments+=$footer

#write the result to a file
ConvertTo-Html -head $head -body $fragments  | Out-File $Path