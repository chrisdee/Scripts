## FIM Service: PowerShell Function To Clear The Synchronization Service Manager Runs History ##

<#

.OVERVIEW 
Clears the FIM Run History stored in the Forefront Identity Manager FIM Synchronization Service Tool (miisclient.exe)

.DESCRIPTION 
Clears the FIM Run History for Products like SharePoint Server and Microsoft Online Services Directory Synchronization (Microsoft Online Directory Sync)

The Synchronization Service Manager (miisclient.exe) tool can generally be found in the following locations for these products:

.SharePoint Server 2010
C:\Program Files\Microsoft Office Servers\14.0\Synchronization Service\UIShell\miisclient.exe

.SharePoint Server 2013
C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service\UIShell\miisclient.exe

.Microsoft Online Directory Sync
C:\Program Files\Microsoft Online Directory Sync\SYNCBUS\Synchronization Service\UIShell\miisclient.exe

.Windows Azure Active Directory Sync Tool
C:\Program Files\Windows Azure Active Directory Sync\SYNCBUS\Synchronization Service\UIShell\miisclient.exe

.USAGE EXAMPLE 

PS> Clear-FIMRunHistory 30 

Clears the FIM Run History until 30 days ago

.RESOURCE

http://social.technet.microsoft.com/wiki/contents/articles/2096.how-to-use-powershell-to-delete-the-run-history-based-on-a-specific-date-en-us.aspx

#> 

Function Clear-FIMRunHistory { 
 
 
    [CmdletBinding()] 
    param 
    ( 
        [Parameter( 
       Mandatory=$True, 
        ValueFromPipeline=$true, 
        ValueFromPipelineByPropertyName=$true)] 
        [int]$DaysToKeep             
   ) 
  
 
    Begin { } 
  
 
    Process { 
  
 
        $DeleteDay = Get-Date 
        If($DaysToKeep -gt 0) { 
              
 
            $DayDiff = New-Object System.TimeSpan $DaysToKeep, 0, 0, 0, 0 
            $DeleteDay = $DeleteDay.Subtract($DayDiff) 
           
 
            Write-Output "Deleting run history earlier than or equal to:" $DeleteDay.toString('MM/dd/yyyy') 
            $lstSrv = @(get-wmiobject -class "MIIS_SERVER" -namespace "root\MicrosoftIdentityIntegrationServer" -computer ".")  
            Write-Output "Result: " $lstSrv[0].ClearRuns($DeleteDay.toString('yyyy-MM-dd')).ReturnValue 
              
 
        } 
  
 
        Trap {  
            Write-Output "`nError: $($_.Exception.Message)`n" 
            Exit 
        } 
       
 
    } 
      
 
    End { } 
      
 
} 
