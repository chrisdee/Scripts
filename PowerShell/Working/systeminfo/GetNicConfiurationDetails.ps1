## NIC Configuration: PowerShell Script to Get System NIC Configuration Details ##

[cmdletbinding()]
param (
 [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$ComputerName = $env:computername
)            

begin {}
process {
 foreach ($Computer in $ComputerName) {
  if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
   $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer | ? {$_.IPEnabled}
   foreach ($Network in $Networks) {
    $IPAddress  = $Network.IpAddress[0]
   $IPAddress1  = $Network.IpAddress[1]
   $IPAddress2  = $Network.IpAddress[2]
   $IPAddress3  = $Network.IpAddress[3]
   $IPAddress4  = $Network.IpAddress[4]
    $SubnetMask  = $Network.IPSubnet[0]
    $DefaultGateway = $Network.DefaultIPGateway
    $DNSServers  = $Network.DNSServerSearchOrder
    $IsDHCPEnabled = $false
    If($network.DHCPEnabled) {
     $IsDHCPEnabled = $true
    }
    $MACAddress  = $Network.MACAddress
    $OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress1 -Value $IPAddress1
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress2 -Value $IPAddress2
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress3 -Value $IPAddress3
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress4 -Value $IPAddress4
    $OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
    $OutputObj | Add-Member -MemberType NoteProperty -Name Gateway -Value $DefaultGateway
    $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
    $OutputObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value $DNSServers
    $OutputObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACAddress
    $OutputObj
   }
  }
 }
}            

end {}