## Yammer: PowerShell Script to Compare an Export of Yammer Users Against Azure AD (o365 / Azure AD) ##

<# 

Copyright 2016 

Microsoft Licensed under the Apache License, Version 2.0 (the "License"); 

you may not use this file except in compliance with the License. 

You may obtain a copy of the License at     


http://www.apache.org/licenses/LICENSE-2.0 


Unless required by applicable law or agreed to in writing, software 

distributed under the License is distributed on an "AS IS" BASIS, 

WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 

See the License for the specific language governing permissions 

and limitations under the License. 


Yammer auditing tool for Office 365 looks for active Yammer accounts 

that  are missing from Office 365 / Azure AD. 


Takes User.csv file from Yammer Data Export as the input file.  

Compares all Active Yammer accounts in the input file to user  

lookup in Azure AD. User is searched by both email and proxyAddresses.  


The output csv file is exactly matching the source file, but it includes 

three new columns: exists_in_azure_ad, object_id and azure_licenses: 

exists_in_azure_ad: Will be TRUE or FALSE, and signals that the user

                     can be, or cannot be found in Office 365 / Azure AD 

object_id: For users that can be found, lists the ObjectId in Azure AD 

azure_licenses: For users that can be found, lists the SKUs assigned to the

                 user in Azure AD. This information can be used to double check

                 licenses are assigned correctly for each user. 

Params - 

UseExistingConnection: Defines if the script should try to use an existing

                        Azure AD connection. Will prompt for credentials and will

                        start a new connection if $FALSE. Default is $FALSE 

InputFile: Source CSV file of users, coming from the Yammer User Export tool - https://www.yammer.com/YourTenant/data_exports/new_user_export

OutputFile: Output location to save the final CSV to 


Example - 

./YammerUserMatchToAzureAD.ps1 -InputFile .\Users.csv -OutputFile .\Results.csv 



#> 

Param(

   [bool]$UseExistingConnection = $FALSE,

   [string]$InputFile = ".\Users.csv",

   [string]$Outputfile = ".\Results.csv"

  ) 

if(!$UseExistingConnection){

     Write-Host "Creating a new connection. Login with your Office 365 Global Admin Credentials..."

     $msolcred = get-credential

     connect-msolservice -credential $msolcred

 }

 Write-Host "Loading all Office 365 users from Azure AD. This can take a while depending on the number of users..."

 $o365usershash = @{}

 get-msoluser -All | Select userprincipalname,proxyaddresses,objectid,@{Name="licenses";Expression={$_.Licenses.AccountSkuId}} | ForEach-Object {

     $o365usershash.Add($_.userprincipalname.ToUpperInvariant(), $_)

     $_.proxyaddresses | ForEach-Object {

         $email = ($_.ToUpperInvariant() -Replace "SMTP:(\\*)*", "").Trim()

         if(!$o365usershash.Contains($email))

         {

             $o365usershash.Add($email, $_)

         }

     }

 }

 Write-Host "Matching Yammer users to Office 365 users"

 $yammerusers = Import-Csv -Path $InputFile | Where-Object {$_.state -eq "active"}


 $yammerusers | ForEach-Object {

     $o365user = $o365usershash[$_.email.ToUpperInvariant()]

     $exists_in_azure_ad = ($o365user -ne $Null)

     $objectid = if($exists_in_azure_ad) { $o365user.objectid } else { "" }

     $licenses = if($exists_in_azure_ad) { $o365user.licenses } else { "" }



     $_ | Add-Member -MemberType NoteProperty -Name "exists_in_azure_ad" -Value $exists_in_azure_ad

     $_ | Add-Member -MemberType NoteProperty -Name "azure_object_id" -Value $objectid

     $_ | Add-Member -MemberType NoteProperty -Name "azure_licenses" -Value $licenses

 } 


Write-Host "Writting the output csv file..."

$yammerusers | Export-Csv $Outputfile -NoTypeInformation 


Write-Host "Done." 