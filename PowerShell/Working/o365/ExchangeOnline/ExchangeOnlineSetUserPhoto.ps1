## Exchange Online: PowerShell Script to Add / Update a User Photo in Exchange Online (o365) ##

## Resource: https://blogs.technet.microsoft.com/dpickett/2016/09/09/o365-user-photos-not-updating

### Start Variables ###
$UserName = "Johnny Smith" #Change this to match your User Name
$PhotoPath = "C:\BoxBuild\JSmith.jpg" #Change this path to match your environment
### End Variables ###

Import-PSSession $(New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $(Get-Credential))

Get-UserPhoto $UserName

Remove-UserPhoto $UserName

Set-UserPhoto $UserName –PictureData ([System.IO.File]::ReadAllBytes($PhotoPath))

Get-UserPhoto $UserName