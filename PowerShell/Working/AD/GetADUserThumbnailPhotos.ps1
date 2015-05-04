## PowerShell: Script to Export User Account Thumbnail Photos (thumbnailPhoto) From Active Directory (AD) to Disk ##

## Overview: PowerShell Script that uses the 'ActiveDirectory' Module to get all AD users thumbnail photos, and exports these to a file location in JPG file format

## Usage: Edit the '$Directory' variable to match your environment and run the script. Feel free to add additional parameters to the 'GET-ADuser' commandlet

Import-Module "ActiveDirectory" -ErrorAction SilentlyContinue

$list=GET-ADuser –filter * -properties thumbnailphoto

Foreach ($User in $list)

{

$Directory='C:\ztemp\ADPhotos\' #Change this path to match your environment (Note: Remember to keep the trailing '\' backslash)

If ($User.thumbnailphoto)

  {

  $Filename=$Directory+$User.samaccountname+'.jpg'

  [System.Io.File]::WriteAllBytes($Filename, $User.Thumbnailphoto)

  }

}