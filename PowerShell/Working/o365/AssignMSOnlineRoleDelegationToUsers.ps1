## Office 365: PowerShell Commands to Get / Add / Remove Members from Delegated Roles ##

Connect-MsolService

##Review the available roles for delegation (Company Administrator is the same as 'Global Administrator')

Get-MsolRole | ft –AutoSize

##Get users already delegated access to a particular role (change the '-RoleName' parameter if required) 

Get-MsolRoleMember -RoleObjectId (Get-MsolRole -RoleName "SharePoint Service Administrator").ObjectId | ft –AutoSize

##Add a user as a member to a particular role (change the '-RoleMemberEmailAddress' parameter, and '-RoleName' if required)

Add-MsolRoleMember -RoleName "SharePoint Service Administrator" -RoleMemberEmailAddress "neal.hicks@summit7systems.com"

##Remove a user from the members of a particular role (change the '-RoleMemberEmailAddress' parameter, and '-RoleName' if required)

Remove-MsolRoleMember -RoleName "SharePoint Service Administrator" -RoleMemberEmailAddress "neal.hicks@summit7systems.com"