PowerShell FTP Client Module 
The PSFTP module allow you to connect and manage the contents of ftp account. 
Module contain set of function to get list of items, download and send files on ftp location.

Module can be installed manualy by downloading Zip file and extract in two places:

%USERPROFILE%\Documents\WindowsPowerShell\Modules
%WINDIR%\System32\WindowsPowerShell\v1.0\Modules

Change Log:

v1.4 - basic IIS6 compatibility mode
v1.3 - view the contents of directories recursively
v1.2.6 - support for username with '@'

Available function list:

 Get-FTPChildItem
Get-FTPItem (alias Receive-FTPItem)
Get-FTPItemSize
New-FTPItem
Remove-FTPItem
Rename-FTPItem
Add-FTPItem (alias Send-FTPItem)
Set-FTPConnection

Sample functions (full content of module in attachment):