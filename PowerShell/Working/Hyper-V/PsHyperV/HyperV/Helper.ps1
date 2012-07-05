Function Add-ZIPContent 
{<#
    .SYNOPSIS
        Adds content to a Zip file
 #>
    [CmdletBinding()]
    Param (
        [parameter(mandatory = $true)][ValidateNotNullOrEmpty()]
        [String]$ZipFile,
        
        [parameter(mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $file
    )
    if (-not $global:ShellApp) {$global:shellApp = New-Object -com Shell.Application }
    if ($ZipFile -notMatch "ZIP$") { $ZipFile += ".ZIP" }
    if (-not (test-path $Zipfile)) { New-Zip $ZipFile | out-null }
    $zipPath = (Resolve-Path $ZipFile).path
    if ($zipPath) {  
        # If we've got a string, convert it to a file/directoryinfo object
       if ($file -is [String])  { $file = (Resolve-Path $file | get-item) }
       if ($file -is [Array])   { $file | forEach-Object {Add-ZIPContent -ZipFile $Zippath -File $_}}
       if (($file -is [System.IO.FileInfo]) -or ($file -is [System.IO.DirectoryInfo])) {
             write-Debug "Copying $($File.fullname) to $ZipPath" 
             $global:shellApp.NameSpace($Zippath).CopyHere($File.fullname) 
             start-sleep -seconds 2
       }        
    } 
}
Function ConvertTo-Enum
{
<#
    .SYNOPSIS
        Converts a hashtable to an enum.
        
    .PARAMETER Table
        Specifies the hashtable to convert.
        
    .PARAMETER Name
        Specifies the name of the int-based enum to create.
        
    .EXAMPLE
        Creates an enum based on a hashtable with the names and values of the three lowest-valued U.S. coins.
        
        PS > @{"Penny" = 1;"Nickle" = 5;"Dime" = 10} | ConvertTo-Enum -Name SmallChange
        PS > [SmallChange]::1
        Penny
        PS > [SmallChange]10
        Dime
        
#>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        [Hashtable]
        [ValidateNotNullOrEmpty()]
        $Table,
        
        [parameter(Mandatory = $true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Name,
        
        [Switch]$CodeOnly
    )
    
    foreach ($key in $Table.Keys) {$items += (",`n {0,20} = {1}" -f $key,$($Table[$key]) ) }
    
    $code = "public enum $Name : int  `n{$($items.Substring(1)) `n}" 
    if ($codeOnly) {$code } else {Add-Type $code}
}
Function Copy-ZipContent
{<#
    .SYNOPSIS
        Copies content out of a zip file
#>
    Param ([parameter(mandatory = $true)][ValidateNotNullOrEmpty()]
           [string]$zipFile, 

           [parameter(mandatory = $true)][ValidateNotNullOrEmpty()]
           [string]$Path
    )
    if(test-path($zipFile)) {$shell = new-object -com Shell.Application
                             $destFolder = $shell.NameSpace($Path)
                             $destFolder.CopyHere(($shell.NameSpace($zipFile).Items()))
    }        
}


Function Get-ZIPContent 
{<#
    .SYNOPSIS
        Returns information about the contents of a zip file 
#>
    Param ([parameter(mandatory = $true)][ValidateNotNullOrEmpty()]
           [string]$zipFile, 
           [Switch]$Raw, 
           [int]$indent=0
    )
    if ($indent -eq 0) {
        if ($ZipFile -match ('zip$')) {$ZipFile += '.zip'} 
        $ZipFile = (resolve-path $ZipFile).path
    }
    $shell = new-object -com Shell.Application
    $NS    = $shell.NameSpace($zipFile)
    $Files = $(foreach ($item in $NS.items() ) {0..8 |
                   ForEach-Object -begin   {$ZipObj = New-Object -TypeName System.Object  } `
                                  -process {Add-Member -inputObject $ZipObj -MemberType NoteProperty -Name ($NS.GetDetailsOf($null,$_)) -Value ($NS.GetDetailsOf($Item,$_).replace([char]8206,"")) }  `
                                  -end     {if ($item.isfolder) {Add-Member -inputObject $ZipObj -MemberType NoteProperty -Name Formatting -value (("| " * $indent) + "+-")
                                                                 $ZipObj 
                                                                 Get-ZipContent -zipfile $item.path -raw -indent ($indent +1 ) }
                                            else                {Add-Member -inputObject $ZipObj -MemberType NoteProperty -Name Formatting -value (("| " * ($indent)) + "|-")
                                                                 if ($indent -eq 0) {$ZipObj.formatting = "|-" }
                                                                 $zipObj  
                                           }
                            }
             } ) 
    if ($raw) {$files} else {$files | format-Table  -property @{label="File"; expression={$_.Formatting + $_.Name}},Type,"Date Modified",Size,"Compressed Size",Ratio,Method -autosize}                                              
}
####################################
#####     Helper functions     #####
####################################

Function Select-Item
{# .ExternalHelp  Maml-Helper.XML
   [CmdletBinding()]
   param ([parameter(ParameterSetName="p1",Position=0)][String[]]$TextChoices,
          [Parameter(ParameterSetName="p2",Position=0)][hashTable]$HashChoices, 
          [String]$Caption="Please make a selection",  [String]$Message="Choices are presented below",  [int]$default=0
    ) 
    $choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
    switch ($PsCmdlet.ParameterSetName) { 
        "p1" {$TextChoices | ForEach-Object       { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_                      )) }  } 
        "p2" {foreach ($key in $HashChoices.Keys) { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $key,$HashChoices[$key] )) }  }            
    }
    $Host.ui.PromptForChoice($caption, $message, $choicedesc, $default)
}


Function Select-List
{#  .ExternalHelp  Maml-Helper.XML
    Param   ([Parameter(Mandatory=$true  ,valueFromPipeline=$true )][Alias("items")]$InputObject, 
             [Parameter(Mandatory=$true)]$Property, [Switch]$multiple)
 
    begin   { $i= @()  }
    process { $i += $inputobject  }
    end     { if ($i.count -eq 1) {$i[0]} elseif ($i.count -gt 1) {
                  $Global:counter=-1
                  $Property=@(@{Label="ID"; Expression={ ($global:Counter++) }}) + $Property
                  format-table -inputObject $i -autosize -property $Property | out-host
                  if ($multiple) { $response = Read-Host "Which one(s) ?" }
                  else           { $Response = Read-Host "Which one ?" }
                  if ($response -gt "") { 
                       if ($multiple) { $Response.Split(",") | ForEach-Object -Begin {$r = @()} -process {if ($_ -match "^\d+$") {$r += $_} elseif ($_ -match "^\d+\.\.\d+$") {$r += (invoke-expression $_)}} -end {$I[$r] }}
                       else           { $I[$response] }
                  } 
              }
            }
}


Function Select-EnumType
{#  .ExternalHelp  Maml-Helper.XML
    param ([type]$EType , [int]$default) 
    $NamesAndValues= $etype.getfields() |
        foreach-object -begin {$list=@()} `
                       -process { if (-not $_.isspecialName) {$list += $_.getValue($null)}} `
                       -end {$list  | sort-object -property value__ } | 
            select-object -property  @{name="Name"; expression={$_.tostring() -replace "_"," "}},value__ 
    $value = (Select-List -Input $namesAndValues -property Name).value__
    if ($value -eq $null ) {$default} else {$value}
}


Function Out-Tree
{#  .ExternalHelp  Maml-Helper.XML
    Param ([Parameter(Mandatory=$true,ValueFromPipeLine = $true)][alias("items")]$inputObject, 
           [Parameter(Mandatory=$true)]$startAt, 
           [string]$path="Path", [string]$parent="Parent",[string]$label="Label", [int]$indent=0
          )
     begin   { 
         $items = @()
     }     
     process {     
         $items += $inputobject
     }
     end { 
         $children = $items | where-object {( "" + $_.$parent) -eq $startAt.$path.ToString()} 
         if ($children -ne $null) {(("| " * $indent) -replace "\s$","-") + "+$($startAt.$label)" 
                                   $children | ForEach-Object {Out-Tree -inputObject $items -startAt $_ -path $path -parent $parent -label $label -indent ($indent+1)}
         }
         else                     {("| " * ($indent-1)) + "|--$($startAt.$label)" }
     }     
}


Function Select-Tree
{#  .ExternalHelp  Maml-Helper.XML
    Param ([Parameter(Mandatory=$true,ValueFromPipeLine = $true)][alias("items")]$inputObject, 
           [Parameter(Mandatory=$true)]$startAt,  
           [string]$path="Path", [string]$parent="Parent", [string]$label="Label", $indent=0, 
           [Switch]$multiple
           )
     begin   { 
         $items = @()
     }     
     process {     
         $items += $inputobject
     }
     end { 
        if ($Indent -eq 0)  {$Global:treeCounter = -1 ;  $Global:treeList=@() ; $Leader="" }
        $Global:treeCounter++
        $Global:treeList=$global:treeList + @($startAt)
        $children = $items | where-object {$_.$parent -eq $startat.$path.ToString()} 
        if   ($children -eq $null) { "{0,-4} {1}|--{2} " -f  $global:Treecounter, ("| " * ($indent-1)) , $startAt.$Label | out-Host }
        else                       { "{0,-4} {1}+{2} "   -f  $Global:treeCounter, ("| " * ($indent)) ,   $startAt.$label | Out-Host
                                     $children | sort-object $label | ForEach-Object {
                                           Select-Tree -inputObject $items -StartAt $_ -Path $path -parent $parent -label $label -indent ($indent+1)
                                      }
        }
        if ($Indent -eq 0) {if ($multiple) { $Global:treeList[ [int[]](Read-Host "Which one(s) ?").Split(",")] }
                            else           { $Global:treeList[ (Read-Host "Which one ?")] }  
                           } 
  }                         
}


Function Test-Admin
{#  .ExternalHelp  Maml-Helper.XML
    [CmdletBinding()]
    Param() 
    
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Verbose "isUserAdmin? $isAdmin"
    $isAdmin
}


Function Convert-DiskIDtoDrive
{#  .ExternalHelp  Maml-Helper.XML
    param ([parameter(ParameterSetName="p1",Position=0, ValueFromPipeLine = $true)][ValidateScript({ $_ -ge 0 })][int]$diskIndex,
           [Parameter(ParameterSetName="p2",Position=0 , ValueFromPipeline=$true)] [System.Management.ManagementObject]$Inputobject
    ) 
    process{
        switch ($PsCmdlet.ParameterSetName) { 
            "p1"  { Get-WmiObject -query "select * from win32_diskpartition where diskindex = $DiskIndex" | ForEach-Object{$_.getRelated("win32_Logicaldisk")} | ForEach-Object {$_.deviceID} } 
            "p2"  { get-wmiobject  -computername $inputObject.__SERVER -namespace "root\cimv2"  -Query "associators of {$($inputObject.__path)} where resultclass=Win32_DiskPartition" | 
                    ForEach-Object{$_.getRelated("win32_Logicaldisk")} | ForEach-Object {$_.deviceID} 
                  }
                  
        }
    }     
}


Function Get-FirstAvailableDriveLetter
{#  .ExternalHelp  Maml-Helper.XML
    $UsedLetters = Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk"  | ForEach-object {$_.deviceId.substring(0,1)} 
    [char]$l="A"
    do {
        if   ($usedLetters -notcontains $L) {return $l}
        else {  [char]$l=([byte][char]$l +1 ) }
       } 
    while ($l -le 'Z')
    write-warning "No free drive letters found"
}
Function New-Zip
{<#
    .SYNOPSIS
        Creates a new , empty Zip file
#>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $True)][ValidateNotNullOrEmpty()]
        [string]$ZIPFile
    )
    If ( $ZIPFile -notMatch "ZIP$")  { $ZIPFile += ".ZIP" } 
    set-content $ZIPFile ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
    Start-Sleep -Seconds 2
    Get-ChildItem $ZIPFile
}
Function Test-WMIJob 
{# .ExternalHelp  Maml-Helper.XML
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
	[Alias("JobID")][ValidateNotNullOrEmpty()]
        [WMI]
        $Job,
        
        [switch]$StatusOnly,        

        [Switch]$Wait, 
        
        [string]$Description = "Job"
    )
       
    while (($Job.JobState -eq [JobState]::Running) -and $Wait)     { 
        Write-Progress -activity ("$Description $($Job.Caption)") -Status "% complete" -PercentComplete $Job.PercentComplete
        Start-Sleep -Milliseconds 250
        $Job.PSBase.Get() 
    }
    Write-Progress -activity ("$Description $($Job.Caption)") -Status "% complete" -Completed
    if ($Statusonly )  {([jobstate]$job.JobState)} else {$job}
}

Function Test-WMIResult
{# .ExternalHelp  Maml-Helper.XML   
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, position=0)][ValidateNotNullOrEmpty()]
        $result ,
        
        [String]$JobWaitText,
        [String]$SuccessText, 
        [String]$failText , 
        [switch]$wait )
    
    if ($result.ReturnValue -eq [ReturnCode]::JobStarted) {
        if ( -not $jobWaitText ) {$jobWaitText = ([wmi]$result.job).description }
        if ( -not $SuccessText ) {$SuccessText = ($lstr_JobSuccess -f $jobWaitText) }
        if ( -not $FailText    ) {$FailText    = ($lstr_JobFailure -f $jobWaitText) }              
        $job  = Test-WMIJob -job $result.job -wait:$wait -Description $JobWaitText 
        if     ( $Job.JobState -eq [JobState]::Completed)                   {Write-Verbose ($SuccessText )                                  ;[ReturnCode]::OK }
        elseif (($Job.jobState -eq [JobState]::running) -and -not $wait )   {Write-Warning ($Lstr_jobContinues -f $jobWaitText,$result.job) ;[ReturnCode]::JobStarted }
        else                                                                {write-error ($failText + ":`n" + $job.ErrorDescription + "`n+");[ReturnCode]::Failed }
    }
    elseif ($result.returnValue -eq [ReturnCode]::OK)                       {Write-Verbose ($SuccessText )                                  ;[ReturnCode]::OK }
    Else                                                                    {write-error ($failText + [returnCode]$Result.ReturnValue)      ;[ReturnCode]::Failed }
}
