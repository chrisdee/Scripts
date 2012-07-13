## PowerShell Script to store and use the same credentials for PSRemoting scripting ##

# Set your PowerShell Variables here

$PasswordFileLocation = "C:\FolderName\psremotingpassword.txt" #Change the path here to suit your environment
$PSRemotingUser = "DOMAIN\User" #Change the domain and user here to suit your environment
$RemoteMachine = "MachineName" #Change the remote machine name here to suit your environment

# Get host input to encrypt PSRemoting password to an encrypted text file

Read-Host "Please enter your PSRemoting password" -AsSecureString | ConvertFrom-SecureString | out-file $PasswordFileLocation

# Now read the PSRemoting password to a SecureString

$pwd = Get-Content $PasswordFileLocation | ConvertTo-SecureString

# Now create the credential to be used

$crd = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $PSRemotingUser,$pwd

# Now use your credentials for a new PSRemoting session

Enter-PSSession -ComputerName $RemoteMachine -Authentication CredSSP -Credential $crd 