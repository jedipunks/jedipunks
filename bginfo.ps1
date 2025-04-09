Param(
    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$BackgroundColor = "Black",  # Default: Black background

    [ValidateSet("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Cyan", "Magenta", "Orange", "Purple", "Brown", "Pink", "Lime", "Navy", "Teal", "Silver", "Gold", "Maroon", "Olive")]
    [string]$TextColor = "White",  # Default: White text

    [string]$FontName = "Segoe UI",  # Default font

    [ValidateRange(9, 45)]
    [int]$FontSize = 16,  # Default font size

    [string]$OutFile = "$($env:temp)\BGInfo_$((Get-Date -Format 'yyyyMMddHHmmss')).png"  # Temp output file
)

. e:\powershell\Get-License.ps1

Function Generate-Wallpaper {
    Add-Type -AssemblyName System.Windows.Forms

    # Collect system information
    $HostName = $env:COMPUTERNAME
    $UserName = $env:USERNAME
    $BootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $IPAddress = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress
    $OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $WinKeyInfo = Get-LicenseInfo -Server $env:COMPUTERNAME -noProgress

    $InfoText = @"
Hostname: $HostName
Username: $UserName
IP Address: $IPAddress
$OS
Boot Time: $BootTime
Rearm Date: $($WinKeyInfo.'Rearm Date')
Days Left: $($WinKeyInfo.'Days Left')
Rearms Remaining: $($WinKeyInfo.Rearms)
"@

    Try {
        # Load drawing assemblies
        Add-Type -AssemblyName System.Drawing
        $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

        # Create bitmap and graphics object
        $png = New-Object System.Drawing.Bitmap($Screen.Width, $Screen.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($png)

        # Fill background
        $brushBackground = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$BackgroundColor)
        $graphics.FillRectangle($brushBackground, 0, 0, $Screen.Width, $Screen.Height)

        # Draw text centered in the image
        $font = New-Object System.Drawing.Font($FontName, $FontSize, [System.Drawing.FontStyle]::Regular)
        $brushText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::$TextColor)

        $format = New-Object System.Drawing.StringFormat
        $format.Alignment = [System.Drawing.StringAlignment]::Far  # Center text horizontally
        $format.LineAlignment = [System.Drawing.StringAlignment]::Near  # Center text vertically

        $textRect = New-Object System.Drawing.RectangleF(0, 0, $Screen.Width, $Screen.Height)
        $graphics.DrawString($InfoText, $font, $brushText, $textRect, $format)

        # Save the bitmap to PNG file
        $png.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)

        # Clean up resources
        $brushBackground.Dispose()
        $brushText.Dispose()
        $graphics.Dispose()
        $png.Dispose()

        return Get-Item $OutFile
    } Catch {
        Write-Warning "Failed to generate wallpaper: $_"
    }
}

Function Set-Wallpaper {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    Try {
        # Add interop type definition for setting the wallpaper
        if (-not ([System.Management.Automation.PSTypeName]'Wallpaper.Setter').Type) {
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;

            public class Wallpaper {
                public const int SetDesktopWallpaper = 20;
                public const int UpdateIniFile = 0x01;
                public const int SendWinIniChange = 0x02;

                [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

                public static void SetWallpaper(string path) {
                    SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
                }
            }
"@ -ErrorAction Stop
        }

        # Set the wallpaper using interop
        [Wallpaper]::SetWallpaper($Path)
        Write-Host "Wallpaper set successfully!"
    } Catch {
        Write-Warning "Failed to set wallpaper: $_"
    }
}

# Generate wallpaper and set it as the desktop background
$Wallpaper = Generate-Wallpaper

if ($Wallpaper) {
    Set-Wallpaper -Path $Wallpaper.FullName
    # Remove the generated wallpaper file after setting it
    Remove-Item -Path $Wallpaper.FullName -Force -ErrorAction SilentlyContinue
}