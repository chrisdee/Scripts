## IIS Server: Get Application Pool User Names (Identity) and Passwords ##

Get-CimInstance -Namespace root/MicrosoftIISv2 -ClassName IIsApplicationPoolSetting -Property Name, WAMUserName, WAMUserPass | Select Name, WAMUserName, WAMUserPass