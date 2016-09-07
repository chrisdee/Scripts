## IIS Server: Get Application Pool User Name (Identity) and Password Using appcmd ##

$AppPoolName = "YourAppPoolName" #Provide your application pool name here

cd "C:\Windows\System32\inetsrv"

./appcmd.exe list apppool "$AppPoolName" /text:*