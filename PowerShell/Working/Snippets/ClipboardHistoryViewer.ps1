<#
    .SYNOPSIS
        UI that will display the history of clipboard items

    .DESCRIPTION
        UI that will display the history of clipboard items. Options include filtering for text by
        typing into the filter textbox, context menu for removing and copying text as well as a menu to 
        clear all entries in the clipboard and clipboard history viewer.

        Use keyboard shortcuts to run common commands:

        Ctrl + C -> Copy selected text from viewer
        Ctrl + R -> Remove selected text from viewer
        Ctrl + E -> Exit the clipboard viewer

    .NOTES
        Author: Boe Prox
        Created: 10 July 2014
        Version History:
            1.0 - Boe Prox - 10 July 2014
                -Initial Version
            1.1 - Boe Prox - 24 July 2014
                -Moved Filter from timer to TextChanged Event
                -Add capability to select multiple items to remove or add to clipboard
                -Able to now use mouse scroll wheel to scroll when over listbox
                - Added Keyboard shortcuts for common operations (copy, remove and exit)
#>
#Requires -Version 3.0
$Runspacehash = [hashtable]::Synchronized(@{})
$Runspacehash.Host = $Host
$Runspacehash.runspace = [RunspaceFactory]::CreateRunspace()
$Runspacehash.runspace.ApartmentState = "STA"
$Runspacehash.runspace.Open() 
$Runspacehash.runspace.SessionStateProxy.SetVariable("Runspacehash",$Runspacehash)
$Runspacehash.PowerShell = {Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase}.GetPowerShell() 
$Runspacehash.PowerShell.Runspace = $Runspacehash.runspace 
$Runspacehash.Handle = $Runspacehash.PowerShell.AddScript({ 
    Function Get-ClipBoard {
        [Windows.Clipboard]::GetText()
    }
    Function Set-ClipBoard {
        $Script:CopiedText = @"
$($listbox.SelectedItems | Out-String)
"@
        [Windows.Clipboard]::SetText($Script:CopiedText)
    }
    Function Clear-Viewer {
        [void]$Script:ObservableCollection.Clear()
        [Windows.Clipboard]::Clear()
    }
    #Build the GUI
    [xml]$xaml = @"
    <Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="Powershell Clipboard History Viewer" WindowStartupLocation = "CenterScreen" 
        Width = "350" Height = "425" ShowInTaskbar = "True" Background = "White">
        <Grid >
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid.Resources>
                <Style x:Key="AlternatingRowStyle" TargetType="{x:Type Control}" >
                    <Setter Property="Background" Value="LightGray"/>
                    <Setter Property="Foreground" Value="Black"/>
                    <Style.Triggers>
                        <Trigger Property="ItemsControl.AlternationIndex" Value="1">
                            <Setter Property="Background" Value="White"/>
                            <Setter Property="Foreground" Value="Black"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </Grid.Resources>
            <Menu Width = 'Auto' HorizontalAlignment = 'Stretch' Grid.Row = '0'>
            <Menu.Background>
                <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
                    <LinearGradientBrush.GradientStops> 
                    <GradientStop Color='#C4CBD8' Offset='0' /> 
                    <GradientStop Color='#E6EAF5' Offset='0.2' /> 
                    <GradientStop Color='#CFD7E2' Offset='0.9' /> 
                    <GradientStop Color='#C4CBD8' Offset='1' /> 
                    </LinearGradientBrush.GradientStops>
                </LinearGradientBrush>
            </Menu.Background>
                <MenuItem x:Name = 'FileMenu' Header = '_File'>
                    <MenuItem x:Name = 'Clear_Menu' Header = '_Clear' />
                </MenuItem>
            </Menu>
            <GroupBox Header = "Filter"  Grid.Row = '2' Background = "White">
                <TextBox x:Name="InputBox" Height = "25" Grid.Row="2" />
            </GroupBox>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"  
            Grid.Row="3" Height = "Auto">
                <ListBox x:Name="listbox" AlternationCount="2" ItemContainerStyle="{StaticResource AlternatingRowStyle}" 
                SelectionMode='Extended'>
                <ListBox.Template>
                    <ControlTemplate TargetType="ListBox">
                        <Border BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderBrush}">
                            <ItemsPresenter/>
                        </Border>
                    </ControlTemplate>
                </ListBox.Template>
                <ListBox.ContextMenu>
                    <ContextMenu x:Name = 'ClipboardMenu'>
                        <MenuItem x:Name = 'Copy_Menu' Header = 'Copy'/>      
                        <MenuItem x:Name = 'Remove_Menu' Header = 'Remove'/>  
                    </ContextMenu>
                </ListBox.ContextMenu>
                </ListBox>
            </ScrollViewer >
        </Grid>
    </Window>
"@
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $Window=[Windows.Markup.XamlReader]::Load( $reader )

    #Connect to Controls
    $listbox = $Window.FindName('listbox')
    $InputBox = $Window.FindName('InputBox')
    $Copy_Menu = $Window.FindName('Copy_Menu')
    $Remove_Menu = $Window.FindName('Remove_Menu')
    $Clear_Menu = $Window.FindName('Clear_Menu')

    #Events
    $Clear_Menu.Add_Click({
        Clear-Viewer
    })
    $Remove_Menu.Add_Click({
        @($listbox.SelectedItems) | ForEach {
            [void]$Script:ObservableCollection.Remove($_)
        }
    })
    $Copy_Menu.Add_Click({
        Set-ClipBoard
    })
    $Window.Add_Activated({
        $InputBox.Focus()
    })

    $Window.Add_SourceInitialized({
        #Create observable collection
        $Script:ObservableCollection = New-Object System.Collections.ObjectModel.ObservableCollection[string]
        $Listbox.ItemsSource = $Script:ObservableCollection

        #Create Timer object
        $Script:timer = new-object System.Windows.Threading.DispatcherTimer 
        $timer.Interval = [TimeSpan]"0:0:.1"

        #Add event per tick
        $timer.Add_Tick({
            $text =  Get-Clipboard
            If (($Script:Previous -ne $Text -AND $Script:CopiedText -ne $Text) -AND $text.length -gt 0) {
                #Add to collection
                [void]$Script:ObservableCollection.Add($text)
                $Script:Previous = $text
            }     
        })
        $timer.Start()
        If (-NOT $timer.IsEnabled) {
            $Window.Close()
        }
    })

    $Window.Add_Closed({
        $Script:timer.Stop()
        $Script:ObservableCollection.Clear()
        $Runspacehash.PowerShell.Dispose()
    })

    $InputBox.Add_TextChanged({
        [System.Windows.Data.CollectionViewSource]::GetDefaultView($Listbox.ItemsSource).Filter = [Predicate[Object]]{             
            Try {
                $args[0] -match [regex]::Escape($InputBox.Text)
            } Catch {
                $True
            }
        }    
    })
    
    $listbox.Add_MouseRightButtonUp({
        If ($Script:ObservableCollection.Count -gt 0) {
            $Remove_Menu.IsEnabled = $True
            $Copy_Menu.IsEnabled = $True
        } Else {
            $Remove_Menu.IsEnabled = $False
            $Copy_Menu.IsEnabled = $False
        }
    })

    $Window.Add_KeyDown({ 
        $key = $_.Key  
        If ([System.Windows.Input.Keyboard]::IsKeyDown("RightCtrl") -OR [System.Windows.Input.Keyboard]::IsKeyDown("LeftCtrl")) {
            Switch ($Key) {
            "C" {
                Set-ClipBoard          
            }
            "R" {
                @($listbox.SelectedItems) | ForEach {
                    [void]$Script:ObservableCollection.Remove($_)
                }            
            }
            "E" {
                $This.Close()
            }
            Default {$Null}
            }
        }
    })

    [void]$Window.ShowDialog()
}).BeginInvoke()