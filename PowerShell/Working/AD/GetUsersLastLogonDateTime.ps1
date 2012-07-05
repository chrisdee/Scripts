## PowerShell: Script to Query Active Directory to Return All Users Last Logon Date and Time ##

$SearchAD = New-Object DirectoryServices.DirectorySearcher([adsi]"")

$SearchAD.filter = "(objectclass=user)"
$users = $SearchAD.findall()

Foreach($user in $users)
{
if($user.properties.item("lastLogon") -ne 0)
{
$a = [datetime]::FromFileTime([int64]::Parse($user.properties.item("lastLogon")))
"$($user.properties.item(`"name`")) $a"
}
}