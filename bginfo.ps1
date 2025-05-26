Param(
    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$BackgroundColor = "Black",  # Default: Black background

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$TextColor = "White",  # Default: White text

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$LabelColor = "White",  # Default: White text

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$DataColor = "Orange",  # Default: White text

    [string]$FontName = "Segoe UI",  # Default font

    [ValidateRange(9, 45)]
    [int]$FontSize = 16,  # Default font size

    [switch]$ShowLicense,  # Show license information

    [int]$maxLogSizeKB = 5000,

    $logPath = "C:\temp"
)

$appName = "BGINFO"
$date = Get-Date -Format MMddyyyy
$OutFile = "$($env:temp)\BGInfo_$((Get-Date -Format 'yyyyMMddHHmmss')).png"  # Temp output file


function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][ValidateSet('Information','Warning','Error')][string]$Severity,
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [switch]$test
    )

    #New-Item -Path C:\temp -Name "test_log_$date.txt" -ItemType File -ErrorAction SilentlyContinue | Out-Null
    $logFile = "$logPath\$date`_$appName`_Log.txt"

    if(!(Test-Path $logFile)){
        New-Item -Path $logPath -Name "$date`_$appName`_Log.txt" -ItemType File -ErrorAction SilentlyContinue | Out-Null
    }

    # Check if log is too big
    if ((Get-ChildItem $logFile).Length / 1KB -gt $maxLogSizeKB) {
        Rename-Item -Path $logFile -NewName "Archive_$appName`_Log_$(Get-Date -Format MMddyyyy_HHmmss).txt" -Force
        New-Item -Path $logPath -Name "$date`_$appName`_Log.txt" -ItemType File -ErrorAction SilentlyContinue | Out-Null
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
    . e:\powershell\Get-License.ps1
}

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
    $padding = 50
    $lineSpacing = $FontSize + 5
    $currentY = 20
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
    $png.Dispose()

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
    $padding = 20
    $lineSpacing = $FontSize + 5
    $startXLeft = $padding
    $startXRight = $Screen.Width - $padding
    $currentY = 10

    # Loop through each item and align correctly
    foreach ($key in $info.Keys) {
        $value = $info[$key]

        # Draw left-aligned header
        $graphics.DrawString($key, $font, $brushText, $startXLeft, $currentY)

        # Measure text width for right-aligned value
        $textWidth = $graphics.MeasureString($value, $font).Width
        $graphics.DrawString($value, $font, $brushText, $startXRight - $textWidth, $currentY)

        # Move to next line
        $currentY += $lineSpacing
    }

    # Save the image
    $png.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)

    # Cleanup
    $brushBackground.Dispose()
    $brushText.Dispose()
    $graphics.Dispose()
    $png.Dispose()

    return Get-Item $OutFile
}

if ($Wallpaper) {
    Set-Wallpaper -Path $Wallpaper.FullName
    # Remove the generated wallpaper file after setting it
    Remove-Item -Path $Wallpaper.FullName -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log -Message "Wallpaper file removed: $($Wallpaper.FullName)" -Severity 'Information'
} else {
    Write-Log -Message "Failed to generate wallpaper." -Severity Warning
}
