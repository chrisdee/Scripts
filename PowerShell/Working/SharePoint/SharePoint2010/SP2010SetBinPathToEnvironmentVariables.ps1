## SharePoint Server: PowerShell Script To Add The STSADM Path To The Environment Variables ##
## Usage: Works on both MOSS 2007 and SharePoint Server 2010 Farms

""
"######################################################################"
"#PowerShell: Script to add STSADM path to System Environment Variable#"
"######################################################################"
""
""
$Hive ="C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\{0}\bin\"
$SPS2007= "12"
$SPS2010= "14"
 
#Getting Path Variable
$env =[Environment]::GetEnvironmentVariable("PATH","Machine") 
 
#Settng $add variable to null
$add = ""
 
#Testing Path for SharePoint Sharepoint 2007 and SharePoint 2010.
if (Test-Path([string]::Format( $Hive, $SPS2007))  ) {$add = [string]::Format( $Hive, $SPS2007) }
if (Test-Path ([string]::Format( $Hive, $SPS2010)) ) {$add = [string]::Format( $Hive, $SPS2010) }
 
#If $add is not set then no sharepoint exists
if ($add -eq "") 
{
    "Message: It looks like you don't even have SharePoint installed on this environment.."
    ""
    
    return
}

#If $add is not set then no sharepoint env. exists
if ($env.Contains($add))
{
  [string]::Format("Message: It looks like you already have '{0}' added as a PATH.", $add) 
  "No need to add this again.."
 
  return
}

#if all went well set the stsamd path to the environment variable 
[string]::Format("Message: Adding to the PATH System variables:'{0}'", $add)    
$env = $env + ";" + $add

[Environment]::SetEnvironmentVariable("Path",$env,"Machine")
 
#This next lines are not necessary , they only exists to verify  if the PATH was changed
$env =[Environment]::GetEnvironmentVariable("PATH","Machine")
""
"Message: Here's a summary of your current PATH System variables:" 
""
$env
