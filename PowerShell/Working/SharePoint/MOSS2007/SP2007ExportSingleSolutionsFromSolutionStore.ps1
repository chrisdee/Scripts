## SharePoint Server: PowerShell Script To Extract Individual Solutions From The Farm Solution Store ##
## Environments: MOSS 2007 and SharePoint Server 2010 Farms
## Resource: http://sharepointpsscripts.codeplex.com/releases/view/32748
## Usage Example: ./Get-SolutionFile.ps1 -name "lifeinsharepoint.metro.wsp" -localpath "C:\BoxBuild\Solutions"

##################################### Get-SolutionFile.PS1 ########################################
#                                                                                                 #
#    Script name:                 Get Solution File                                               #
#    Author:                      Sergey Zelenov (szelenov@microsoft.com), Microsoft PFE UK       #
#                                                                                                 #
#    Synopsis:                    Retrieve a solution file (.wsp or .cab) from the                #
#                                 Configuration Database                                          #
#                                                                                                 #
#    Output:                      None (saves file locally and writes status messages to console) #
#                                                                                                 #
#    Input                                                                                        #
#    parameters:                                                                                  #
#                                                                                                 #
#                  -name          Type:          System.String                                    #
#                                 Value:         Display name of the target solution              #
#                                 Mandatory:     No                                               #
#                                 Default value: None (a list of solutions will be retrieved      #
#                                                and presented to user to choose from)            #
#                                                                                                 #
#    Functions:                   Get-SolutionName                                                #
#                                                                                                 #
#    .NET Assemblies loaded:      Microsoft.SharePoint, Version=12.0.0.0 , Culture=Neutral,       #
#                                 PublicKeyToken=71e9bce111e9429c                                 #
#                                                                                                 #
####################################### Microsoft © 2008 ##########################################
param ([string] $name, [string] $localpath)

#Load the required SharePoint assemblies containing the classes used in the script
#The Out-Null cmdlet instructs the interpreter to not output anything to the interactive shell
#Otherwise information about each assembly being loaded would be displayed
[System.Reflection.Assembly]::Load("Microsoft.SharePoint, Version=12.0.0.0 , Culture=Neutral, PublicKeyToken=71e9bce111e9429c") | Out-Null

########################################### Function ##############################################
#                                                                                                 #
#    Function name:               Get-SolutionName                                                #
#                                                                                                 #
#    Synopsis:                    Presents user with a visual choice from a list of all solutions #
#                                 currently stored in the configuration database, accepts user's  #
#                                 input and returns the name of the selected solution             #
#                                                                                                 #
#    Input parameters:            None                                                            #
#                                                                                                 #
#    Returns:                     String                                                          #
#                                                                                                 #
###################################################################################################
function Get-SolutionName()
{
    # Initialize an empty hashtable to store solution names and indexes
    $solHash = @{};
    
    # Bind to the collections of all solutions in the local farm and process them one by one, storing names in a hashtable
    # under automatically incremented indexes
    # The Foreach-Object cmdlet uses the begin/process/end structure to initialize the $i index counter
    ([Microsoft.SharePoint.Administration.SPFarm]::Local).Solutions | 
        Foreach-Object {$i=1;} {$solHash.$i = $_.displayname; $i++} { }
    
    Write-Host;
    
    # If solutions were found, present the user with selection
    if ($solHash.Count -gt 0)
    {
        Write-Host -Object "The following solutions were found in the farm:" -ForegroundColor Green -BackgroundColor DarkMagenta;
        Write-Host;
        
        # Hashtables are not sortable, so in order to sort solutions by index keys have to be sorted separately first
        $solHash.Keys | Sort-Object | Foreach-Object {Write-Host -Object $("`t[{0}] {1}" -f $_, $solHash[$_]) -ForegroundColor Yellow -BackgroundColor DarkMagenta;}
        Write-Host;
        Write-Host -Object "Enter the index number of the solution you wish to retrieve, or 0 (zero) to exit: " -NoNewLine -ForegroundColor Green -BackgroundColor DarkMagenta;
        
        # Obtain input from user and return the matching value from the hashtable
        return $solHash[[int](Read-Host)];
    }
    
    # No solutions found in the configuration database
    else
    {
        Write-Host -Object "The local farm's solution store contains no solutions." -ForegroundColor Green -BackgroundColor DarkMagenta;
        Write-Host;
    }
}

# Check if name of target solution was specified as a parameter
if (-not $name)
{
    # Name of solution was not specifed, so call the Get-SolutionName function to obtain the name
    $name = Get-SolutionName;
    
    # If after calling the function the name is still unknown, stop execution
    if (-not $name)
    { break; }
}

# Check if local path to save the file to was specified as a parameter
if (-not $localpath)
{
    Write-Host;
    # Prompt and obtain local path value from user
    Write-Host -Object "Enter the local path to the folder you want the solution file to be saved to: " -ForegroundColor Green -BackgroundColor DarkMagenta;
    $localpath = Read-Host;
}

# Check if the path specified is valid and throw an exception if it's not
if (-not $(Test-Path -Path $localpath -PathType Container)) 
{
    throw "`"$localpath`" is not a valid path! If the path contains spaces, it must be enclosed in SINGLE quotes."
}

# Try to bind to the target solution
$solution = ([Microsoft.SharePoint.Administration.SPFarm]::Local).Solutions | Where-Object {$_.Name -eq $name}

Write-Host;

# Check if solution was found
if ($solution -ne $null) 
{
    # Constitute the full local path (including file name)
    $solPath = Join-Path -Path $localpath -ChildPath $solution.SolutionFile.Name;
    
    # Try and save solution file locally
    $solution.SolutionFile.SaveAs($solPath);
    
    # If no errors occurred, display a success message
    if ($?)
    {
       Write-Host "Solution file saved successfully to $solPath" -ForegroundColor Green -BackgroundColor DarkMagenta;
       Write-Host;
    }
}

# Solution not found in the store; display a warning message
else 
{
    Write-Host -Object "Solution `"$name`" could not be found!" -ForegroundColor Red -BackgroundColor DarkMagenta;
    Write-Host;
}