## SharePoint Server 2010: PowerShell Script To Export And Import User Accounts Across SharePoint Lists ##
## Overview: When copying a list from one site collection to another with a list template 'SPUserField' Information can be out of synch
## Usage: Edit your 'Global Variables' and 'Export' and "Import' list variables and run ./SP2010SynchListUserFields.ps1
## Resource: http://blogbaris.blogspot.ch/2012/05/synch-user-fields-when-copying-lists.html

if((Get-PSSnapin | Where {$_.Name -eq “Microsoft.SharePoint.PowerShell”}) -eq $null) {
       Add-PSSnapin Microsoft.SharePoint.PowerShell
}

## Export Script - Source ##

## Global Variables
$csv = "C:\BoxBuild\Scripts\user.csv" #Change this to suit your environment
$log = "C:\BoxBuild\Scripts\usersynch.log" #Change this to suit your environment 
# ---------------------

Start-Transcript -path $log

## Export List User Variables  
 $web = Get-SPWeb "http://YourWebApp"   
 $list = $web.Lists["YourSourceListName"]  
 $field = "Created By" #'Modified By'
 # ---------------------  
 $userInfos = @()  
 foreach($item in $list.Items) {  
   $userFld = [Microsoft.SharePoint.SPFieldUser] $item.Fields.GetField($field)    
   if ($null -ne $userFld) {          
     if ($null -ne $item[$field]) {  
       $fieldVal = new-object Microsoft.SharePoint.SPFieldUserValue($web, $item[$field].ToString())      
       if ($null -ne $fieldVal){  
         $user = $fieldVal.User        
         $userInfos += New-Object PSObject -Property @{  
           Title = $item.Title  
           Login = $user.LoginName  
         }  
       }  
     }  
   }else{  
     Write-Host "Field: " $field " not found in list!" -foregroundcolor red  
   }  
 }  
 $userinfos | Export-CSV $csv -NoTypeInformation  
 Write-Host "END - Script"  

 ## Import Script - Destination ##

## Import List User Variables 
$web = Get-SPWeb "http://YourWebApp"   
 $list = $web.Lists["YourTargetListName"]  
 $field = "Created By" #'Modified By'
 # --------------------- 
 $items = $list.Items  
 $import = Import-Csv $csv  
 foreach ($obj in $import)  
 {   
   Write-Host "Searching for " $obj.Title -foregroundcolor yellow  
   $items | Where-Object { $_.Title -eq $obj.Title} | foreach {  
     Write-Host " >> Updating item to new user: " $obj.Login -foregroundcolor green  
     try  
     {  
       $_[$field] = $web.EnsureUser($obj.Login).ID  
       $_.Update()      
     } catch [Microsoft.SharePoint.SPException] {  
       Write-Host " >> Error: could not find user: " $obj.Login -foregroundcolor red            
     }   
   }  
   Write-Host "  "  
 }  
 Write-Host "End Synch Process"  
 
 Stop-Transcript