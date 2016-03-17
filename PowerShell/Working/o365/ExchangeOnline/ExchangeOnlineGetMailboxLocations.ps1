## Exchange Online: PowerShell Script to Determine in which datacenters and Geographic locations Mailboxes for your Tenant are located ##


<#
 
 Name:        ExchangeOnlineGetMailboxLocations.ps1                                                             
                                                                                                   
 Version:     1.1                                                                                   
                                                                                                   
 Description: Determines the number of datacenters and locations where Exchange Online mailboxes    
              are distributed.                                                                      
                                                                                                    
 Limitations: Table of datacenters is static and may need to be expanded as Microsoft brings        
              additional datacenters online.
                                                                                                                                                                        
 Assumptions: The original table of datacenters listed "Bay Area" which is assumed to be "San       
              Francisco, California, USA".  Datacenter codes have been truncated to two characters  
              with the assumption that it designates the location.                                  
                                                                                                   
 Usage:       Additional information on the usage of this script can found at the following         
              blog post:  http://blogs.perficient.com/microsoft/?p=30871                            
                                                                                                    
 Requires:    Remote PowerShell Connection to Exchange Online                                      
                                                                                                   
 Author:      Joe Palarchio                                                                         
                                                                                                    
 Disclaimer:  This script is provided AS IS without any support. Please test in a lab environment   
              prior to production use.
              
 Resource: https://blogs.perficient.com/microsoft/2016/03/office-365-script-to-determine-exchange-online-mailbox-location                                                                          
                                                                                                    
#>

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic –AllowRedirection
Import-PSSession $Session

$Datacenter = @{}
$Datacenter["CP"]=@("LAM","Brazil")
$Datacenter["GR"]=@("LAM","Brazil")
$Datacenter["HK"]=@("APC","Hong Kong")
$Datacenter["SI"]=@("APC","Singapore")
$Datacenter["SG"]=@("APC","Singapore")
$Datacenter["KA"]=@("JPN","Japan")
$Datacenter["OS"]=@("JPN","Japan")
$Datacenter["TY"]=@("JPN","Japan")
$Datacenter["AM"]=@("EUR","Amsterdam, Netherlands")
$Datacenter["DB"]=@("EUR","Dublin, Ireland")
$Datacenter["HE"]=@("EUR","Finland")
$Datacenter["VI"]=@("EUR","Austria")
$Datacenter["BL"]=@("NAM","Virginia, USA")
$Datacenter["SN"]=@("NAM","San Antonio, Texas, USA")
$Datacenter["BN"]=@("NAM","Virginia, USA")
$Datacenter["DM"]=@("NAM","Des Moines, Iowa, USA")
$Datacenter["BY"]=@("NAM","San Francisco, California, USA")
$Datacenter["CY"]=@("NAM","Cheyenne, Wyoming, USA")
$Datacenter["CO"]=@("NAM","Quincy, Washington, USA")
$Datacenter["CH"]=@("NAM","Chicago, Illinois, USA")

Write-Host
Write-Host "Getting Mailbox Information..."

$Mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -ne "DiscoveryMailbox"}

$ServerCount = ($Mailboxes | Group-Object {$_.ServerName}).count

$Mailboxes = $Mailboxes | Group-Object {$_.ServerName.SubString(0,2)} | Select @{Name="Datacenter";Expression={$_.Name}}, Count

$Locations=@()

# Not pretty error handling but allows counts to add properly when a datacenter location could not be identified from the table
$E = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

ForEach ($Mailbox in $Mailboxes) {
  $Object = New-Object -TypeName PSObject
  $Object | Add-Member -Name 'Datacenter' -MemberType NoteProperty -Value $Mailbox.Datacenter
  $Object | Add-Member -Name 'Region' -MemberType NoteProperty -Value $Datacenter[$Mailbox.Datacenter][0]
  $Object | Add-Member -Name 'Location' -MemberType NoteProperty -Value $Datacenter[$Mailbox.Datacenter][1]
  $Object | Add-Member -Name 'Count' -MemberType NoteProperty -Value $Mailbox.Count
  $Locations += $Object
}

$ErrorActionPreference = $E

$TotalMailboxes = ($Locations | Measure-Object Count -Sum).sum

$LocationsConsolidated = $Locations | Group-Object Location | ForEach {
  New-Object PSObject -Property @{
  Location = $_.Name
  Mailboxes = ($_.Group | Measure-Object Count -Sum).Sum
  }
} | Sort-Object Count -Descending

Write-Host
Write-Host -NoNewline "Your "
Write-Host -NoNewline -ForegroundColor Yellow $TotalMailboxes
Write-Host -NoNewline " mailboxes are spread across "
Write-Host -NoNewline -ForegroundColor Yellow $ServerCount
Write-Host -NoNewline " servers in "
Write-Host -NoNewline -ForegroundColor Yellow $Locations.Count
Write-Host -NoNewline " datacenters in "
Write-Host -NoNewline -ForegroundColor Yellow $LocationsConsolidated.Count
Write-Host " geographical locations."
Write-Host
Write-Host "The distribution of mailboxes is shown below:"

$LocationsConsolidated | Select Location, Mailboxes