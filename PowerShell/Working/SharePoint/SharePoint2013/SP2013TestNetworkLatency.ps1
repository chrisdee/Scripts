## SharePoint Server: PowerShell Script to Check / Test Network Latency with Ping Across a Farm ##

<#

Overview: Useful PowerShell Script that pings specified machines in a Farm on the SQL Instance / App / Web layers to check latency between these machines

Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Farms

Usage: Edit the following variables and run the script on your farm: '$SPServerNames'; '$SQLServername'; '$RunTime'

Resource: http://blogs.msdn.com/b/erica/archive/2013/11/11/sharepoint-2013-network-latency-test-script.aspx

#>

# Edit these variables to match your environment
$SPServerNames = "SPAPP1", "SPAPP2", "SPWEB1", "SPWEB2"
$SQLServername = "SPSQL"

#Edit this if you want to change the durations of the ping test (in minutes)
$RunTime = 10

### test connectivity ###
Write-Host "Test Connectivity:"

Write-Host "Testing Ping"
$ping = New-Object System.Net.NetworkInformation.ping

for($i=0; $i -le $SPServernames[$i].Length-1; $i++){
    Write-Host "  Pinging $($SPServerNames[$i])"
    $status = $ping.send($SPServernames[$i]).Status
        
    if($status -ne "Success"){
        throw "Ping Failed to $($SPSServernames[$i])"
        }
    }
    
Write-Host " - Succeeded `n"

### test SQL connectivity ###
Write-Host "Testing SQL Connection"
#Connect to SQL using SQlCLient the same way that SharePoint Does
$SQLConnection = New-Object System.Data.SQLClient.SQLConnection("Data Source=$SQLServername;Integrated Security=True")
$SQLConnection.Open()
if($SQLConnection.state -ne "Open"){
    throw "SQL Connection Failed"
    }
Write-Host " - Succeeded `n"

### Intra-server latency consistency test ###
Write-Host "Starting network consistency tests @ $([DateTime]::Now)"

$ScriptBlock = {
    # accept the loop variable across the job-context barrier
    param($InHost, $RunTime) 

    $start = [DateTime]::Now
    $ping = New-Object System.Net.NetworkInformation.ping
    
    $PingResults = @()
    while([datetime]::now -le $start.AddMinutes($RunTime)){ 
        $outping = $ping.send($InHost)
        if($outping.Status -ne "Success"){
            $PingResults = $PingResults + 100
            } else{
            $PingResults = $PingResults + $outping.RoundtripTime
            }
        Start-Sleep .1
        } 
    return $PingResults
    }


#run ping jobs in parallel
foreach($i in $SPServernames){
    Start-Job $ScriptBlock -ArgumentList $i, $RunTime -Name "$i.latency_test"
}

Write-Host "`nGathering statistics for $($RunTime) minutes... `n"

#wait and clean up
While (Get-Job -State "Running") { Start-Sleep $($runTime/2) }

$output = @{}
foreach($i in $SPServernames){
    $output[$i] = Receive-Job -Name "$i.latency_test"
}
Remove-Job *

#test results
Write-Host "Processing Data... `n"

$BadPings = @{}
$PercentBadPings = @{}

foreach($i in $SPServernames){
    $BadPings[$i] = $output[$i] | ?{$_ -ge 1}
    $TotalPings = $output[$i].Length
    $PercentBadPingsOver5Ms =  ($BadPings[$i] | ?{$_ -ge 5}).length/$TotalPings * 100
    $PercentBadPingsOver4Ms =  ($BadPings[$i] | ?{$_ -ge 4}).length/$TotalPings * 100
    $PercentBadPingsOver3Ms =  ($BadPings[$i] | ?{$_ -ge 3}).length/$TotalPings * 100
    $PercentBadPingsOver2Ms =  ($BadPings[$i] | ?{$_ -ge 2}).length/$TotalPings * 100
    $PercentBadPingsOver1Ms =  ($BadPings[$i] | ?{$_ -ge 1}).length/$TotalPings * 100
      
    if($PercentBadPingsOver1Ms -ge .1)
    {
        "{0} DOES NOT meet the latency requirements with {1:N2}% of pings >1ms" -f $i, $PercentBadPingsOver1Ms  
        "  ({0:N2}% > 5ms, {1:N2}% > 4ms, {2:N2}% > 3ms, {3:N2}% > 2ms, {4:N2}% > 1ms)`n" -f $PercentBadPingsOver5Ms,$PercentBadPingsOver4Ms,$PercentBadPingsOver3Ms,$PercentBadPingsOver2Ms,$PercentBadPingsOver1Ms
    } 
        else
        {
        "{0} meets the latency requirements with {1:N2}% of pings >1ms`n" -f $i, $PercentBadPingsOver1Ms
        }
    $LatencyTestFailed = 1
    }
    
#if($LatencyTestFailed -eq 1){
#    throw "Farm Latency Test Failed"
#    } 
