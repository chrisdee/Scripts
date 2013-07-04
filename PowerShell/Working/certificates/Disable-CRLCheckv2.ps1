## PowerShell: Scripts to Disable The Certificate Revocation List Check (CRL) ##

## Resource: http://joelblogs.co.uk/2011/09/20/certificate-revocation-list-check-and-sharepoint-2010-without-an-internet-connection

#the following statement goes on one line
set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -name State -value 146944

#the following statement goes on one line also
set-ItemProperty -path "REGISTRY::\HKEY_USERS\.Default\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -name State -value 146944

#UPDATED: and the following statement goes on one line too
get-ChildItem REGISTRY::HKEY_USERS | foreach-object {set-ItemProperty -ErrorAction silentlycontinue -path ($_.Name + "\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing")  -name State -value 146944}

#Doing this at Machine Config level like the AutoSPInstaller solution approach
Write-Host -ForegroundColor White " - Disabling Certificate Revocation List (CRL) check..."
ForEach($bitsize in ("","64")) 
{			
  $xml = [xml](Get-Content $env:windir\Microsoft.NET\Framework$bitsize\v2.0.50727\CONFIG\Machine.config)
  If (!$xml.DocumentElement.SelectSingleNode("runtime")) { 
    $runtime = $xml.CreateElement("runtime")
    $xml.DocumentElement.AppendChild($runtime) | Out-Null
  }
  If (!$xml.DocumentElement.SelectSingleNode("runtime/generatePublisherEvidence")) {
    $gpe = $xml.CreateElement("generatePublisherEvidence")
    $xml.DocumentElement.SelectSingleNode("runtime").AppendChild($gpe)  | Out-Null
  }
  $xml.DocumentElement.SelectSingleNode("runtime/generatePublisherEvidence").SetAttribute("enabled","false")  | Out-Null
  $xml.Save("$env:windir\Microsoft.NET\Framework$bitsize\v2.0.50727\CONFIG\Machine.config")
}

