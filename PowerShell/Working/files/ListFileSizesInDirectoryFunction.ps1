## PowerShell: Function to Convert File Length Properties into a more Readable Human Format ##

$properties = @(
    'Name'
    'Directory'
    @{
        Label = 'Size'
        Expression = {
            if ($_.Length -ge 1GB)
            {
                '{0:F2} GB' -f ($_.Length / 1GB)
            }
            elseif ($_.Length -ge 1MB)
            {
                '{0:F2} MB' -f ($_.Length / 1MB)
            }
            elseif ($_.Length -ge 1KB)
            {
                '{0:F2} KB' -f ($_.Length / 1KB)
            }
            else
            {
                '{0} bytes' -f $_.Length
            }
        }
    }
)

##Usage Example:
Get-ChildItem -Path '\\SPTALOS13\i$\MSSQL11.SQL13\MSSQL\DATA\' -Recurse -Include *.MDF -ErrorAction SilentlyContinue |
Sort-Object -Property Length -Descending |
Format-Table -Property $properties #|
#Out-File 'C:\ztemp\files.txt'