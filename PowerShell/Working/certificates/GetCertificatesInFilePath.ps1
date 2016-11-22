## PowerShell: Function to list Certificate Details from a Specified File Path ##

<# 
.Synopsis 
   Get certificate files from a specified path or paths and 
   get an object of the certificate including File name, Subject name, 
   the signature algoritm used, validity dates, and thumbprint. 
.DESCRIPTION 
   Get certificate files from a specified path or paths and 
   get an object of the certificate including file name, subject name, 
   the signature algoritm used, validity dates, and thumbprint. The  
   script requires the certutil.exe to read the certificate files 
   and parse the text output. 
 
   Certificates in the file system used by applications may need to 
   be monitored and checked for expiriation as well as deprecated  
   cipher suites/signature algorithm (i.e. sha1, md5).  
.NOTES 
   Created by: Jason Wasser @wasserja 
   Modified Date: 9/24/2015 09:20:44 AM  
 
   Changelog: 
   * Version 1.1 
        * Fixes to work with PowerShell 2.0 
   * Version 1.0 
        * Initial Script 
.EXAMPLE 
   Get-CertificateFile 
   Outputs a list of certificate files in the current path. 
.EXAMPLE 
   Get-CertificateFile -Path c:\temp 
   Outputs a list of certificate files from c:\temp. 
.EXAMPLE 
   Get-CertificateFile -Path C:\inetpub -Recurse 
   Outputs a list of certificate files from c:\inetpub including subdirectories. 
.LINK 
   https://gallery.technet.microsoft.com/scriptcenter/Get-CertificateFile-bf1360f2 
#> 
function Get-CertificateFile 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$false, 
                    ValueFromPipeline=$true, 
                    Position=0)] 
        [string[]]$Path = '.', 
        [string]$CertUtilPath = 'C:\Windows\System32\certutil.exe', 
        [string[]]$CertificateFileType = ('*.cer','*.crt','*.p7b'), 
        [switch]$Recurse = $false 
    ) 
 
    Begin 
    { 
    } 
    Process 
    { 
        foreach ($CertPath in $Path) { 
            # Gather certificates from the $CertPath 
            if (Test-Path -Path $CertPath) { 
                Write-Verbose "$CertPath exists. Checking for certificate files." 
                $Certificates = Get-ChildItem -Path $CertPath\* -Include $CertificateFileType -Recurse:([bool]$Recurse.IsPresent) 
                if ($Certificates) { 
                    foreach ($Certificate in $Certificates) { 
                        Write-Verbose "Found $Certificate" 
                        $CertificateDump = Invoke-Expression -Command "$CertUtilPath -dump '$($Certificate.fullname)'" 
                        Write-Verbose 'Getting NotBefore time stamp.' 
                        if ([bool]($CertificateDump | Select-String -Pattern 'NotBefore')) {  
                            $NotBefore = [datetime]($CertificateDump | Select-String -Pattern 'NotBefore' | Select-Object -First 1).ToString().Split(':',2)[1].Trim() 
                            Write-Verbose "NotBefore $NotBefore" 
                            } 
                        else { 
                            $NotBefore = $null 
                            Write-Verbose "NotBefore $NotBefore" 
                            } 
                        Write-Verbose 'Getting NotAfter time stamp.' 
                        if ([bool]($CertificateDump | Select-String -Pattern 'NotAfter')) { 
                            $NotAfter = [datetime]($CertificateDump | Select-String -Pattern 'NotAfter' | Select-Object -First 1).ToString().Split(':',2)[1].Trim() 
                            Write-Verbose "NotAfter $NotAfter" 
                            $Days = ($NotAfter - (Get-Date)).Days 
                            Write-Verbose "Days $Days" 
                            } 
                        else { 
                            $NotAfter = $null 
                            Write-Verbose "NotAfter $NotAfter" 
                            $Days = $null 
                            Write-Verbose "Days $Days" 
                            } 
                        $Subject = ($CertificateDump | Select-String -Pattern 'CN=' | Select-Object -First 1).ToString().TrimStart() 
                        Write-Verbose "Subject $Subject" 
                        $SignatureAlgoritm = ($CertificateDump | Select-String -Pattern 'Signature Algorithm' -Context 0,1 | Select-Object -First 1).tostring().trim().Split(' ')[11]  
                        Write-Verbose "SignatureAlgorithm $SignatureAlgoritm" 
                        if (($CertificateDump | Select-String -SimpleMatch 'Cert Hash(sha1)')) { 
                            $Thumbprint = ($CertificateDump | Select-String -SimpleMatch 'Cert Hash(sha1)' | Select-Object -First 1).ToString().split(':')[1].trim() -replace ' ','' 
                            Write-Verbose "Thumbprint $Thumbprint" 
                            } 
                        if ($PSVersionTable.PSVersion.Major -lt 3) { 
                            $CertificateProperties = @{ 
                                FileName           = $Certificate.FullName 
                                Subject            = $Subject 
                                SignatureAlgorithm = $SignatureAlgoritm 
                                NotBefore          = $NotBefore 
                                NotAfter           = $NotAfter 
                                Days               = $Days 
                                Thumbprint         = $Thumbprint 
                                } 
                            } 
                        else { 
                            $CertificateProperties = [ordered]@{ 
                                FileName           = $Certificate.FullName 
                                Subject            = $Subject 
                                SignatureAlgorithm = $SignatureAlgoritm 
                                NotBefore          = $NotBefore 
                                NotAfter           = $NotAfter 
                                Days               = $Days 
                                Thumbprint         = $Thumbprint 
                                } 
                            } 
                     
                        $objCertificate = New-Object PSObject -Property $CertificateProperties 
                        if ($PSVersionTable.PSVersion.Major -lt 3) { 
                            $objCertificate | Select-Object FileName,Subject,SignatureAlgorithm,NotBefore,NotAfter,Days,Thumbprint 
                            } 
                        else { 
                            $objCertificate 
                            } 
                        } 
                    } 
                else { 
                    Write-Verbose "No certificates found in $CertPath" 
                    } 
                } 
            else { 
                Write-Error "Unable to access $CertPath" 
                } 
            } 
    } 
    End 
    { 
    } 
} 

Get-CertificateFile -Path "T:\TGF\Drive_C\Projects\ManagedServices\ADFS\SupportIssues\ADFS1CertRenewals\November2016\CHG32974_1116"