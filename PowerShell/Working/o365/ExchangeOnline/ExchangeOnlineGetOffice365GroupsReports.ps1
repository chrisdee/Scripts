## Exchange Online: PowerShell Script to Get Office 365 Group Information and Membership Details (o365 Groups) ##

## Resource: https://alexholmeset.blog/2017/08/24/office-365-groups-reporting

#Connect to Exchange Online
Import-PSSession $(New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $(Get-Credential))

#Create $Info Membership array.
$Info = @()
 
#Create $GroupInfo Summary array.
$GroupInfo = @()
 
#Collects all groups and specified properties
$Groups = Get-UnifiedGroup | Select-Object Alias,Accesstype,ManagedBy,PrimarySmtpAddress,Displayname,Notes,GroupMemberCount,GroupExternalMemberCount,WhenChanged
 
#Counts number of groups.
$GroupsCount = ($Groups).count
 
#Creates a input to $Info for evry owner and member of each group.
#First inputs evry owner of the group, then evry member of the group.
#Creates a input to $GroupInfo for each group.
foreach($Group in $Groups) {
 
    Write-Host -Object "Number of Groups left to process $GroupsCount" -ForegroundColor Green
    $Members = Get-UnifiedGroupLinks -Identity $Group.alias -LinkType members
    $Owners = Get-UnifiedGroupLinks -Identity $Group.alias -LinkType owners
    $OwnerCount = $Group.ManagedBy
 
    $Object=[PSCustomObject]@{
        Group = $Group.Displayname
        NumberOfOwners = $OwnerCount.count
        NumberOfMembers = $Group.GroupMemberCount
        NumberOfExternalMembers = $Group.ExternalMemberCount
    }
    $GroupInfo+=$Object
 
    foreach($Owner in $Owners){
        $Object=[PSCustomObject]@{
            Name = $Group.Displayname
            Group = $Group.Alias
            Email = $Group.PrimarySmtpAddress
            UserName = $Owner.name
            NumberOfMembers = $Group.GroupMemberCount
            MemberOrOwner = 'Owner'
            NumberOfOwners = $OwnerCount.count
            GroupType = $Group.AccessType
            ExternalMemberCount = $Group.GroupExternalMemberCount
            WhenChanged = $Group.WhenChanged
            Description = $Group.Notes
            }#EndPSCustomObject
        $Info+=$object
    }
 
    foreach($Member in $Members){
        $Object=[PSCustomObject]@{
            Name = $Group.Displayname
            Group = $Group.Alias
            Email = $Group.PrimarySmtpAddress
            UserName = $Member.name
            NumberOfMembers = $Group.GroupMemberCount
            MemberOrOwner = 'Member'
            NumberOfOwners = $OwnerCount.count
            GroupType = $Group.AccessType
            ExternalMemberCount = $Group.GroupExternalMemberCount
            WhenChanged = $Group.WhenChanged
            Description = $Group.Notes
            }#EndPSCustomObject
        $Info+=$object
    }
 
    $GroupsCount--
 
}
 
$Info | Export-Csv "C:\temp\o365GroupInfoMembership.csv" -Encoding utf8 -NoTypeInformation -NoClobber #Change this path to match your environment
$GroupInfo | Export-Csv "C:\temp\o365GroupInfoSummary.csv" -Encoding utf8 -NoTypeInformation -NoClobber #Change this path to match your environment

