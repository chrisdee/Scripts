 ## Active Directory: PowerShell Function that uses the Active Directory Module to check AD whether Machines are Online and whether anyone is Logged On to them ##
 
 <#
            .SYNOPSIS
                Find specific machines in AD, check if they're online and if so, who's logged on
 
            .DESCRIPTION
                Find a specific machine in Active Directory using filters.
                If machine is [or multiple machines are] found, check if you can connect to said machine.
                If you can connect to the machine, try and find out who's currently logged on to the machine.
                If noone's logged on, display this as well
 
            .PARAMETER ComputerName
                The ComputerName you are looking for.
                You can include wildcards in the ComputerName to make sure similarly names machines are also found
 
            .PARAMETER OU
                In case you want to restrict your search to a specific Organization Unit you can enter the OU's Distinguished Name to limit your search results
 
            .RESOURCE
                http://powershellpr0mpt.com/2015/08/20/script-dumpster-online-adcomputers
 
            .USAGE EXAMPLE
                Online-ADComputers -ComputerName "CONTOSO-WKS*"
                Online-ADComputers -OU "OU=Servers2012,DC=YourPrefix,DC=YourDomain,DC=com"
    #>

Import-Module ActiveDirectory

Function Online-ADComputers {

Param (
    $ComputerName = '*',
    $OU
)
 
 
if ($OU) {
        $Computers = Get-ADComputer -Filter {Name -like $ComputerName} -SearchBase $OU
    }
 
else {
 
        $Computers = Get-ADComputer -Filter {Name -like $ComputerName}
    }
 
if ($Computers) {
 
foreach ($Computer in $Computers){
    $Connection = Test-Connection -Count 1 -Quiet -ComputerName $Computer.Name
 
    if ($Connection) {
        $user = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $($Computer.Name) -ErrorAction SilentlyContinue | ForEach-Object {$_.UserName}        
        if ([string]::IsNullOrEmpty($user)) { $user = 'No User Logged on'}
    }
    else { 
        $user = 'Machine turned off'
    }
 
    $properties = @{'ComputerName'=$Computer.Name;
                    'Online'=$Connection;
                    'User'=$user}
 
 
    $obj = New-Object -TypeName PSObject -Property $properties
    $obj
 
    }
}
 
else {
	Write-Output "No computers like $ComputerName known in Active Directory" 
	}

}
