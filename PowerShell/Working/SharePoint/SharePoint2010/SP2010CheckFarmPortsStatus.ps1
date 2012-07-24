## SharePoint Server: PowerShell Script To Check Access To Common Ports And Protocols Across An N-Tier Farm ##
## Usage: Edit the IPs and Authentication Options to match your Farm and save and run the script on each server
## Environments: MOSS 2007 and SharePoint Server 2010, along with any other N-Tier web application farms
## Resource: http://blogbaris.blogspot.ch/2012/06/check-ports-for-extranet-sharepoint.html

<#
These values can be modified
Enter the IPS of the server
Ports from http://technet.microsoft.com/en-us/library/cc262849.aspx
#>
$SERVER_APP = "xxx.xxx.xxx.xxx"
$SERVER_WEBAPPS = @("xxx.xxx.xxx.xxx", "xxx.xxx.xxx.xxx")
$SERVER_DB = "xxx.xxx.xxx.xxx"
$SERVER_AD = "xxx.xxx.xxx.xxx"
$SERVER_DNS = "xxx.xxx.xxx.xxx"
$SERVER_SMTP = "xxx.xxx.xxx.xxx"
$CLIENT = "xxx.xxx.xxx.xxx" #IP of a client which should access SharePoint

$USE_KERBEROS = $false
$USE_NETBIOS = $false
$USE_SMTP = $true

# bi = bidirectional
# out = outbound
$CONNECTIONS = @(
  #SQL
  ( "out", $SERVER_APP, $SERVER_DB, "1435", "SQL" ),
  ( "out", $SERVER_WEBAPPS, $SERVER_DB, "1435", "SQL" ),  
  
  #Service Applications
  ( "bi", $SERVER_WEBAPPS[0], $SERVER_WEBAPPS[1], "32843,32844", "Service Applications" )  
  
  #HTTP
  ( "bi", $CLIENT, $SERVER_WEBAPPS, "80,443", "HTTP, HTTPS" ),      
  ( "bi", $SERVER_WEBAPPS, $SERVER_APP, "80,443", "HTTP, HTTPS" ),    

  #SMB
  ( "bi", $SERVER_WEBAPPS, $SERVER_APP, "445", "SMB" ),      
  
  #LDAP
  ( "out", $SERVER_APP, $SERVER_AD, "389, 636" , "LDAP, LDAPS"),
  
  #DNS
  ( "out", $SERVER_APP, $SERVER_DNS, "53", "DNS" )
)

#SMTP ?
if ($USE_SMTP -eq $true) {  
  $CONNECTIONS += ,( "bi", $SERVER_WEBAPPS, $SERVER_SMTP, "25", "SMTP" )
}

#KERBEROS ?
if ($USE_KERBEROS -eq $true) {  
  $CONNECTIONS += ,@( "bi", $SERVER_WEBAPPS, $SERVER_APP, "88,464", "Kerberos")
}

#NETBIOS ?
if ($USE_NETBIOS -eq $true) {  
  $CONNECTIONS += ,@( "bi", $SERVER_WEBAPPS, $SERVER_APP, "137,138,139", "NetBios")
}


<#
---------------------------
Do not touch these ones
---------------------------
#>
$LOCAL_IP = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').ipaddress[0]

Function PingPort {
  $ip = $args[0] 
  $port = [int]$args[1]
  
  $ErrorActionPreference = "SilentlyContinue"
  $socket = new-object System.Net.Sockets.TcpClient($ip, $port)
  if ($socket –eq $null) {    
    $false
  } else {
    $socket = $null
    $true
  }
}

foreach ($conn in $CONNECTIONS) {  
  if ($conn[0] -eq "bi") {    
    $CONNECTIONS += ,@( "out", $conn[2], $conn[1], $conn[3], $conn[4] )
  }
}

foreach ($conn in $CONNECTIONS) {  
  if ( $conn[1] -is [System.Array] ) { $servers1 = $conn[1] }else{ $servers1 = @($conn[1]) }
  if ( $conn[2] -is [System.Array] ) { $servers2 = $conn[2] }else{ $servers2 = @($conn[2]) }    
  $ports = $conn[3] -split ","  
  $desc = $conn[4]
  
  foreach( $port in $ports) {
    foreach( $server1 in $servers1) {    
      foreach( $server2 in $servers2) {            
        if ($LOCAL_IP -eq $server1) {
          Write-Host "`nTesting Connection:"
          Write-Host $server1 " -> " $server2 " -> Port:" $port " [" $desc "]" -foregroundcolor yellow
          $pinged = PingPort $server2 $port
          if ( $pinged -eq $true ){
            Write-Host "Connection O.K." -foregroundcolor green
          }else{
            Write-Host "Port closed." -foregroundcolor red
          }
        }
      }
    }
  }
}   