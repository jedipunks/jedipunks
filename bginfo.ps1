<#
    BGInfo Wallpaper Generator Script
    This script generates a desktop wallpaper with system information and sets it as the current wallpaper.
    It supports customization of background color, text color, label color, data color, font name, and font size.
    It also includes logging functionality and an option to show license information.

    Usage:
        .\bginfo.ps1 -BackgroundColor "Blue" -TextColor "White" -LabelColor "Yellow" -DataColor "Green" -FontName "Arial" -FontSize 14 -ShowLicense -maxLogSizeKB 500 -logPath "C:\Logs" -skipRemove

    Parameters:
        -BackgroundColor: Background color of the wallpaper (default: Black)
        -TextColor: Color of the text (default: White)
        -LabelColor: Color of the labels (default: White)
        -DataColor: Color of the data values (default: Purple)
        -FontName: Font name for the text (default: Segoe UI)
        -FontSize: Font size for the text (default: 16)
        -ShowLicense: Show license information in the generated wallpaper
        -maxLogSizeKB: Maximum log file size in KB before archiving (default: 1000)
        -logPath: Path to save log files (default: C:\temp)
        -skipRemove: Skip removing the generated wallpaper file after setting it as wallpaper

    Version: 1.0
        - Initial release with basic functionality
#>

Param(
    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$BackgroundColor = "Black",  # Default: Black background

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$TextColor = "White",  # Default: White text

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$LabelColor = "White",  # Default: White text

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$DataColor = "Purple",  # Default: White text

    [string]$FontName = "Segoe UI",  # Default font

    [ValidateRange(9, 45)]
    [int]$FontSize = 16,  # Default font size

    [switch]$ShowLicense,  # Show license information

    [int]$maxLogSizeKB = 1000,  # Maximum log file size in KB before archiving

    $logPath = "C:\temp", # Default log path

    [switch]$skipRemove  # Skip removing the generated wallpaper file, default is to remove it
)

$appName = "BGINFO" # Application name for logging
$date = Get-Date -Format MMddyyyy # Date for log file naming
$OutFile = "$($env:temp)\BGInfo_$((Get-Date -Format 'yyyyMMddHHmmss')).png"  # Temp output file

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][ValidateSet('Information','Warning','Error')][string]$Severity,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $logFile = "$logPath\$appName`_Log.txt" # Log file path

    if(!(Test-Path $logFile)){
        New-Item -Path $logPath -Name "$appName`_Log.txt" -ItemType File -ErrorAction SilentlyContinue | Out-Null
    }

    # Check if log is too big
    if ((Get-ChildItem $logFile).Length / 1KB -gt $maxLogSizeKB) {
        Rename-Item -Path $logFile -NewName "Archive_$appName`_Log_$(Get-Date -Format MMddyyyy_HHmmss).txt" -Force
        New-Item -Path $logPath -Name "$appName`_Log.txt" -ItemType File -ErrorAction SilentlyContinue | Out-Null
        Compress-Archive -Path "$logPath\Archive_$appName`_Log_*.txt" -DestinationPath "$logPath\Archive_$appName`_Logs.zip" -Force
        Remove-Item -Path "$logPath\Archive_$appName`_Log_*.txt" -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    if($Severity -eq 'Error'){
        $global:errorMsg = [PSCustomObject]@{
            'Error Name' = $ErrorRecord.Exception.Message.ToString()
            'Line Number' = $ErrorRecord.InvocationInfo.ScriptLineNumber.ToString()
            'Stack' = ($ErrorRecord.ScriptStackTrace.ToString() -replace "`n", " `t`t") # `r for return `n for new line `t tab
        }

        "[$Severity]`t`t$(Get-Date) $message $errorMsg" | Out-File $logFile -Append ascii
    } else {
        "[$Severity]`t$(Get-Date) $message" | Out-File $logFile -Append ascii
    }
}

if($ShowLicense){
    if(-not (Test-Path -Path e:\powershell\Get-License.ps1)) {
        Write-Log -Message "License script not found at e:\powershell\Get-License.ps1" -Severity 'Error'
        throw "License script not found. Please ensure the path is correct."
    } else {
        . e:\powershell\Get-License.ps1
    }
}

Function Generate-Wallpaper {
    Add-Type -AssemblyName System.Windows.Forms # Required for screen dimensions
    Add-Type -AssemblyName System.Drawing # Required for drawing graphics

    # Screen dimensions
    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds # Get primary screen dimensions
    if (-not $Screen) {
        Write-Log -Message "Failed to retrieve screen dimensions." -Severity 'Error'
        throw "Could not determine screen dimensions. Ensure you are running this on a desktop environment."
    }

    # Create bitmap and graphics object
    $png = New-Object System.Drawing.Bitmap($Screen.Width, $Screen.Height) # Create a new bitmap with screen dimensions
    if (-not $png) {
        Write-Log -Message "Failed to create bitmap for wallpaper." -Severity 'Error'
        throw "Could not create bitmap for wallpaper. Ensure you have sufficient permissions."
    }
    $graphics = [System.Drawing.Graphics]::FromImage($png) # Create a graphics object from the bitmap
    if (-not $graphics) {
        Write-Log -Message "Failed to create graphics object for wallpaper." -Severity 'Error'
        throw "Could not create graphics object for wallpaper. Ensure you have sufficient permissions."
    }

    # Background setup
    $brushBackground = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$BackgroundColor) # Create a brush for the background color
    $graphics.FillRectangle($brushBackground, 0, 0, $Screen.Width, $Screen.Height) # Fill the rectangle with the background color

    # Define system info as a custom object array
    $SystemInfo = @(
        [PSCustomObject]@{ Label = "Hostname"; Value = $env:COMPUTERNAME }
        [PSCustomObject]@{ Label = "Username"; Value = $env:USERNAME }
        [PSCustomObject]@{ Label = "Logon Server"; Value = $env:LOGONSERVER }
        [PSCustomObject]@{ Label = "IP Address"; Value = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress }
        [PSCustomObject]@{ Label = "OS"; Value = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption }
        [PSCustomObject]@{ Label = "Boot Time"; Value = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime }
    )

    if ($ShowLicense) {
        $WinKeyInfo = Get-LicenseInfo -Server $env:COMPUTERNAME -noProgress
        $SystemInfo += [PSCustomObject]@{ Label = "Rearm Date"; Value = $WinKeyInfo.'Rearm Date' }
        $SystemInfo += [PSCustomObject]@{ Label = "Days Left"; Value = $WinKeyInfo.'Days Left' }
        $SystemInfo += [PSCustomObject]@{ Label = "Rearms Remaining"; Value = $WinKeyInfo.Rearms }
    }

    # Define spacing & positioning
    $padding = 50 # Padding from edges
    $lineSpacing = $FontSize + 5 # Space between lines
    $currentY = 20 # Start Y position for the first line
    $labelX = $Screen.Width - 500  # Right-side placement for labels
    $valueX = $labelX + 200  # Data positioned to the right of labels

    # Default to $TextColor if LabelColor and DataColor are missing
    if (-not $LabelColor) { $LabelColor = $TextColor }
    if (-not $DataColor) { $DataColor = $TextColor }

    # Define colors
    $brushLabel = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$LabelColor)
    $brushData = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$DataColor)

    # Iterate over the object array and draw each entry
    foreach ($item in $SystemInfo) {
        # Draw label (left side)
        $graphics.DrawString($item.Label, (New-Object System.Drawing.Font($FontName, $FontSize)), $brushLabel, $labelX, $currentY)

        # Draw value (right side)
        $graphics.DrawString($item.Value, (New-Object System.Drawing.Font($FontName, $FontSize)), $brushData, $valueX, $currentY)

        # Move to next line
        $currentY += $lineSpacing
    }

    # Save the image
    $png.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)

    # Cleanup
    $brushBackground.Dispose()
    $brushLabel.Dispose()
    $brushData.Dispose()
    $graphics.Dispose()
    $png.Dispose() # Dispose of the bitmap to free resources
    Write-Log -Message "Wallpaper generated and saved to $OutFile" -Severity 'Information'

    return Get-Item $OutFile
}



# https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfoa
Function Set-Wallpaper {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [ValidateSet("Center", "Stretch", "Fill", "Tile", "Fit")]
        [string]$Style = "Stretch"
    )
    Try {
        # Add interop type definition for wallpaper setting
        if (-not ([System.Management.Automation.PSTypeName]'Wallpaper.Setter').Type) {
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            using Microsoft.Win32;

            namespace Wallpaper {
                public enum Style : int {
                    Center, Stretch, Fill, Fit, Tile
                }
                public class Setter {
                    public const int SetDesktopWallpaper = 20;
                    public const int UpdateIniFile = 0x01;
                    public const int SendWinIniChange = 0x02;

                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

                    public static void SetWallpaper(string path, Wallpaper.Style style) {
                        SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
                        RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);

                        switch (style) {
                            case Style.Tile:
                                key.SetValue(@"WallpaperStyle", "0");
                                key.SetValue(@"TileWallpaper", "1");
                                break;
                            case Style.Center:
                                key.SetValue(@"WallpaperStyle", "0");
                                key.SetValue(@"TileWallpaper", "0");
                                break;
                            case Style.Stretch:
                                key.SetValue(@"WallpaperStyle", "2");
                                key.SetValue(@"TileWallpaper", "0");
                                break;
                            case Style.Fill:
                                key.SetValue(@"WallpaperStyle", "10");
                                key.SetValue(@"TileWallpaper", "0");
                                break;
                            case Style.Fit:
                                key.SetValue(@"WallpaperStyle", "6");
                                key.SetValue(@"TileWallpaper", "0");
                                break;
                        }

                        key.Close();
                    }
                }
            }
"@ -ErrorAction Stop
        }

        # Set the wallpaper using interop
        [Wallpaper.Setter]::SetWallpaper($Path, $Style)
    } Catch {
        Write-Warning "Failed to set wallpaper: $_"
    }
}

# Generate wallpaper and set it as the desktop background
$Wallpaper = Generate-Wallpaper
Function Generate-Wallpaper {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Screen dimensions
    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

    # Create bitmap and graphics object
    $png = New-Object System.Drawing.Bitmap($Screen.Width, $Screen.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($png)

    # Background setup
    $brushBackground = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$BackgroundColor)
    $graphics.FillRectangle($brushBackground, 0, 0, $Screen.Width, $Screen.Height)

    # Text properties
    $font = New-Object System.Drawing.Font($FontName, $FontSize, [System.Drawing.FontStyle]::Regular)
    $brushText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$TextColor)

    # Define left-aligned headers and right-aligned values
    $info = @{
        "Hostname:" = $env:COMPUTERNAME
        "Username:" = $env:USERNAME
        "Logon Server:" = $env:LOGONSERVER
        "IP Address:" = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress
        "OS:" = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        "Boot Time:" = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    }

    # Additional info if license is shown
    if ($ShowLicense) {
        $WinKeyInfo = Get-LicenseInfo -Server $env:COMPUTERNAME -noProgress
        $info["Rearm Date:"] = $WinKeyInfo.'Rearm Date'
        $info["Days Left:"] = $WinKeyInfo.'Days Left'
        $info["Rearms Remaining:"] = $WinKeyInfo.Rearms
    }

    # Define spacing
    $padding = 20 # Padding from edges
    $lineSpacing = $FontSize + 5 # Space between lines
    $startXLeft = $padding # Start X for left-aligned text
    $startXRight = $Screen.Width - $padding # Start X for right-aligned text
    $currentY = 10 # Start Y position for the first line

    # Loop through each item and align correctly
    foreach ($key in $info.Keys) {
        $value = $info[$key] # Get the value for the current key

        # Draw left-aligned header
        $graphics.DrawString($key, $font, $brushText, $startXLeft, $currentY)

        # Measure text width for right-aligned value
        $textWidth = $graphics.MeasureString($value, $font).Width
        $graphics.DrawString($value, $font, $brushText, $startXRight - $textWidth, $currentY)

        # Move to next line
        $currentY += $lineSpacing
    }

    # Save the image
    $png.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png) # Save the bitmap as PNG

    # Cleanup
    $brushBackground.Dispose()
    $brushText.Dispose()
    $graphics.Dispose()
    $png.Dispose()

    return Get-Item $OutFile
}

if ($Wallpaper) {
    Set-Wallpaper -Path $Wallpaper.FullName
    if($skipRemove) {
        # If skipRemove is set, do not remove the wallpaper file
        # Removing the wallpaper will cause the desktop to revert to a blank state after a period of time as registered wallpaper is missing due to the removal
        Write-Log -Message "Skipping removal of wallpaper file: $($Wallpaper.FullName)" -Severity 'Information'
    } else {
        # Remove the generated wallpaper file after setting it, default behavior
        Remove-Item -Path $Wallpaper.FullName -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Log -Message "Wallpaper file removed: $($Wallpaper.FullName)" -Severity 'Information'
    Write-Log -Message "Wallpaper set to: $((Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop\').WallPaper)" -Severity 'Information' # Log the wallpaper path
} else {
    Write-Log -Message "Failed to generate wallpaper." -Severity Warning
}
