#################################### Get-SPCredentials.PS1 ########################################
#    PowerShell:				  Script to return MOSS 2007 Service Accounts And Passwords		  #
#    Script name:                 Get SharePoint credentials                                      #
#    Author:                      Sergey Zelenov (szelenov@microsoft.com), Microsoft PFE UK       #
#    Resource:					  http://sharepointpsscripts.codeplex.com                         #
#    Synopsis:                    Returns usernames and passwords of all SharePoint service       #
#                                 accounts (app pools and NT services)                            #
#                                                                                                 #
#    Output:                      Array of synthetic objects                                      #
#                                                                                                 #
#    Input                                                                                        #
#    parameters:                  None                                                            #
#                                                                                                 #
#    Functions:                   Create-Object                                                   #
#                                                                                                 #
#    .NET Assemblies loaded:      Microsoft.SharePoint, Version=12.0.0.0 , Culture=Neutral,       #
#                                 PublicKeyToken=71e9bce111e9429c                                 #
#                                                                                                 #
####################################### Microsoft © 2008 ##########################################

#Load the required SharePoint assemblies containing the classes used in the script
#The Out-Null cmdlet instructs the interpreter to not output anything to the interactive shell
#Otherwise information about each assembly being loaded would be displayed
[System.Reflection.Assembly]::Load("Microsoft.SharePoint, Version=12.0.0.0 , Culture=Neutral, PublicKeyToken=71e9bce111e9429c") | Out-Null


########################################### Function #############################################
#                                                                                                #
#    Function name:               Create-Object                                                  #
#                                                                                                #
#    Synopsis:                    Creates a custom object containing information                 #
#                                 about a service account                                        #
#                                                                                                #
#    Input parameters:            $type (String)                                                 #
#                                       Type of object (app pool or NT service account)          #
#                                 $name (String)                                                 #
#                                       Name of service                                          #
#                                 $username                                                      #
#                                       Service account login name                               #
#                                 $password                                                      #
#                                       Service account password                                 #
#                                                                                                #
#    Returns:                     An instance of PSObject                                        #
#                                                                                                #
##################################################################################################
function Create-Object ([string] $type, [string] $name, [string] $username, [string] $password)
{
	New-Object PSObject |
		Add-Member -PassThru -MemberType NoteProperty -Name Type -Value $type |
		Add-Member -PassThru -MemberType NoteProperty -Name Name -Value $name | 
		Add-Member -PassThru -MemberType NoteProperty -Name Username -Value $username |
		Add-Member -PassThru -MemberType NoteProperty -Name Password -Value $password
}

# Bind to the local SharePoint farm
$farm = [Microsoft.SharePoint.Administration.SPFarm]::Local

# Bind to the collection of all farm services
$spcredentials = $farm.Services | 
    # Sort farm services by type
    sort -Property TypeName | 
        # Only select those logical services that are backed up by a physical NT service,
        # excluding services not running under either a domain or LSA account `
        Where-Object {($_ -is [Microsoft.SharePoint.Administration.SPWindowsService]) `
            -and (($spi = $_.ProcessIdentity).Username -notlike "NT AUTHORITY\*")} | 
               # Store information about service account in a custom object through the Create-Object function
               # and store the object in the $spcredentials array
	           ForEach-Object {Create-Object "Service" $_.TypeName $spi.Username $spi.Password}

# Bind to the collection of SPWebService instances in the farm and process them one by one
foreach ($ws in (New-Object -TypeName Microsoft.SharePoint.Administration.SPWebServiceCollection -ArgumentList $farm))
{
	# Bind to the collection of all IIS application pools associated with the current instance of SPWebService
    $spcredentials += $ws.ApplicationPools | 
        # Exclude pools not running under wither a domain or LSA account
        Where-Object {$_.Username -notlike "NT AUTHORITY\*"} | 
            # Store information about service account in a custom object through the Create-Object function
            # and store the object in the $spcredentials array 
            ForEach-Object {Create-Object "ApplicationPool" $_.Name $_.Username $_.Password}
}

# Return account information to the standard output
$spcredentials | Format-List
# Return account information to a file
#$spcredentials | Out-File "D:\Scripts\PowerShell\SPServiceAccounts.txt"