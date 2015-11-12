## FTP: PowerShell Script to Recursively list all files in FTP directory (recursive) ##

## Overview: PowerShell function to Recursively list all files in a FTP directory

## Usage: Edit the Variables to match your FTP server and directory path and run the script

## Resource: https://gist.github.com/arthurdent/0fd3880bd07e484a0af6

### Start Variables ###
$Server = "ftp://YourServerName/site/wwwroot"
$User = "YourFTPUserName"
$Pass = "YourFTPPassword"
### End Variables ###

Function Get-FtpDirectory($Directory) {
    
    # Credentials
    $FTPRequest = [System.Net.FtpWebRequest]::Create("$($Server)$($Directory)")
    $FTPRequest.Credentials = New-Object System.Net.NetworkCredential($User,$Pass)
    $FTPRequest.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails

    # Don't want Binary, Keep Alive unecessary.
    $FTPRequest.UseBinary = $False
    $FTPRequest.KeepAlive = $False

    $FTPResponse = $FTPRequest.GetResponse()
    $ResponseStream = $FTPResponse.GetResponseStream()

    # Create a nice Array of the detailed directory listing
    $StreamReader = New-Object System.IO.Streamreader $ResponseStream
    $DirListing = (($StreamReader.ReadToEnd()) -split [Environment]::NewLine)
    $StreamReader.Close()

    # Remove first two elements ( . and .. ) and last element (\n)
    $DirListing = $DirListing[2..($DirListing.Length-2)] 

    # Close the FTP connection so only one is open at a time
    $FTPResponse.Close()
    
    # This array will hold the final result
    $FileTree = @()

    # Loop through the listings
    foreach ($CurLine in $DirListing) {

        # Split line into space separated array
        $LineTok = ($CurLine -split '\ +')

        # Get the filename (can even contain spaces)
        $CurFile = $LineTok[8..($LineTok.Length-1)]

        # Figure out if it's a directory. Super hax.
        $DirBool = $LineTok[0].StartsWith("d")

        # Determine what to do next (file or dir?)
        If ($DirBool) {
            # Recursively traverse sub-directories
            $FileTree += ,(Get-FtpDirectory "$($Directory)$($CurFile)/")
        } Else {
            # Add the output to the file tree
            $FileTree += ,"$($Directory)$($CurFile)"
        }
    }
    
    Return $FileTree

}

# Now call the function
Get-FtpDirectory | Out-GridView