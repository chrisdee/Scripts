## =====================================================================
## Title       : Get-IEXTip
## Description : Enhanced built-in function Get-Tip with Online switch to list online version of
##               'Exchange Management Shell Tips of the Day'
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXTip [[-number] <Object>] [-Online]
##   
## Output      : System.String
## Usage       : 
##               1. Open 'Exchange Management Shell Tips of the Day' in default browser 
##               Get-IEXTip -Online
## 
##               2. View a random tip of the day (same as Get-Tip) 
##               Get-IEXTip
##
##               3. View a tip number 69
##               Get-IEXTip -Number 69        
## Notes       :
## Tag         : Exchange 2007, tip, online, get
## Change log  :
## ===================================================================== 

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 


function Get-IEXTip
{ 

 param(
  $number = $null,
  [switch]$Online
 ) 

 trap
 {
  continue
 } 

 if ($Online) {
  (New-Object -com shell.application).Open('http://technet.microsoft.com/en-us/library/bb397216.aspx')
  return
 } 

     $exbin = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Exchange\Setup).MsiInstallPath + "bin" 


 if( ($exrandom -eq $null) -or ($exrandom -isnot [System.Random]))
 {
  $exrandom = New-Object System.Random
 } 

     $exchculture = (Get-UICulture).Parent.Name 

 if ( Test-Path "$exbin\$exchculture\extips.xml" )
 {
  $exchculture = $exchculture
 }
 else
 {
  $exchculture = 'en'
 } 

  

 if (Test-Path "$exbin\$exchculture\extips.xml")
 { 

  $tips = [xml](get-content "$exbin\$exchculture\extips.xml")
  if($number -eq $null)
  {
   $temp = $exrandom.Next( 0, $tips.topic.developerConceptualDocument.introduction.table.row.Count )
   write-host -fore Yellow ( "Tip of the day #" + $temp + ":`n" )
   $nav = $tips.topic.developerConceptualDocument.introduction.table.row[$temp].entry.CreateNavigator()
   $null =  $nav.MoveToFirstChild()
   
   do
   {
    write-host $nav.Value
   }
   while( $nav.MoveToNext() )
   write-host
  }
  else
  {
   $nav = $tips.topic.developerConceptualDocument.introduction.table.row[$number].entry.CreateNavigator()
   write-host -fore Yellow ( "Tip of the day #" + $number + ":`n" )
             $null = $nav.MoveToFirstChild()
   
   do
   {
    write-host $nav.Value
   }
   while( $nav.MoveToNext() )
   Write-Host
  }
 }
 else
 {
         "Exchange tips file '$exbin\$exchculture\extips.xml' not found!"
 }
} 

