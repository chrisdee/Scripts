## PowerShell: Useful Query To Compare Hot Fixes Between 2 Machines ##

$node1 = Get-HotFix -ComputerName "MachineName1"
$node2 = Get-HotFix -ComputerName "MachineName2"
Compare-Object -ReferenceObject $node1 -DifferenceObject $node2 -Property HotFixID