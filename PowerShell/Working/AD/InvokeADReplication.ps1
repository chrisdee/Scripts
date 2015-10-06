## Active Directory: PowerShell Function that Invokes / Triggers Replication between Domain Controllers (DCs) ##

<#
.Synopsis
   Invoke-ADReplication forces an immediate replication between domain controllers.
.DESCRIPTION
   Invoke-ADReplication is a PowerShell advanced function that uses repadmin to 
   force immediate replication of a domain controllers within a given domain. By 
   default the function initiate replicates all domain controllers in the domain 
   where the script is run. You can specify alternate domains assuming there is a 
   trust. You can also specify specific domain controllers to initiate replication.
   

   To Do:
    * Add ability to synchronize specific naming context.
    * Add ability to synchronize specific domain controllers.
    * Verify permissions first and/or supply alternate credentials.
   
   Requires:
    * Write-Log: https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
    * repadmin.exe needs to be installed on the local computer. 

   KNOWN ISSUES:
    * none
.NOTES
   Created by: Jason Wasser
   Modified: 4/20/2015 11:14:40 AM  
   Version 1.0
.EXAMPLE
   Invoke-ADReplication
   Initiates a KCC and syncall on all domain controllers in the current domain.
.EXAMPLE
   Invoke-ADReplication -DomainName domain.local
   Initiates a KCC and syncall on all domain controllers in domain.local.
.EXAMPLE
   Invoke-ADReplication -DomainName domain.local -ComputerName dc03.domain.local
   Initiates a KCC and syncall on domain controller dc03.domain.local in domain.local.
.EXAMPLE
   Invoke-ADReplication -ComputerName dc0*
   Initiates a KCC and syncall on domain controllers with name like dc0* in the current domain.
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Invoke-ADReplication-29e52f4f
#>
#Requires -Modules ActiveDirectory

Import-Module ActiveDirectory

function Invoke-ADReplication
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$DomainName,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=1)]
        [string]$ComputerName="*",
        #[string]$NamingContext="DC=DomainDnsZones,DC=Domain,DC=com",
        [string]$LogFileName="C:\Logs\Invoke-ADReplication.log"
    )

    Begin
    {
        # This is only for PowerShell 2.0 which doesn't support 
        #if (!(Get-Module -Name ActiveDirectory)) {
        #    Import-Module -Name ActiveDirectory
        #    }

        # Begin Logging
        Write-Log "--------------------------------------------" -Path $LogFileName -Level Info
        Write-Log "Beginning $($MyInvocation.InvocationName) on $($env:COMPUTERNAME) by $env:USERDOMAIN\$env:USERNAME" -Path $LogFileName

    }
    Process
    {
        if ($DomainName) {
            $ADDomain = Get-ADDomain -Identity $DomainName
            $DCs = $ADDomain.ReplicaDirectoryServers | Where-Object -FilterScript {$_ -like $ComputerName}
            $ADDCs = @()
            foreach ($DC in $DCs) {
                $ADDCs += Get-ADDomainController -Server $DC
                }
            }
        else {
            $ADDCs = Get-ADDomainController -Filter {Name -like $ComputerName}
            }
        
        if ($ADDCs) {
            foreach ($ADDC in $ADDCs) {
            Write-Log "Checking $($ADDC.HostName)" -LogPath $LogFileName -Level Info
            if (Test-Connection -ComputerName $ADDC.HostName -Quiet -Count 1) {
                Write-Log "$($ADDC.HostName) is accessible." -LogPath $LogFileName -Level Info
                Write-Log "Initiating KCC" -LogPath $LogFileName -Level Info
                c:\windows\system32\repadmin.exe /kcc $ADDC.Hostname | Tee-Object -FilePath $LogFileName -Append
                Write-Log "Initiating synchronization." -LogPath $LogFileName -Level Info
                c:\windows\system32\repadmin.exe /syncall /A /e $ADDC.Hostname | Tee-Object -FilePath $LogFileName -Append
                }   
            else {
                Write-Log "$($ADDC.HostName) is not accessible." -LogPath $LogFileName -Level Error
                }
            }
            }
        else {
            Write-Log -Message "No matching DC's found for $ComputerName" -LogPath $LogFileName -Level Error
            }
    }
    End
    {
        # Clean up
        Write-Log "$($MyInvocation.InvocationName) complete." -Path $LogFileName -Level Info
        Write-Log "--------------------------------------------" -Path $LogFileName -Level Info
        # Rotate Log file
        if (Test-Path $LogFileName) {
            $TimeStamp = Get-Date -Format "yyyyMMddhhmmss"
            $LogFilePath = Get-ChildItem -Path $LogFileName
            Rename-Item $LogFileName -NewName "$($LogFilePath.BaseName)-$TimeStamp.log"
            }
    }
}