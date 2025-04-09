function Get-LicenseInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]$Server,
        [Parameter(Position = 0)]
        [String]$InputFile,
        [switch]$NoProgress
    )

    begin {
        $Output = @()
    }

    process {
        if ($InputFile) {
            $ServerList = Get-Content -Path $InputFile
        } elseif ($Server) {
            $ServerList = $Server
        } else {
            $ServerList = $env:COMPUTERNAME
        }

        $totalServers = $ServerList.Count
        $progress = 0

        foreach ($server in $ServerList) {
            $progress++
            $percentComplete = ($progress / $totalServers) * 100
            $status = "$server"
            if (-not $NoProgress) {
                Write-Progress -PercentComplete $percentComplete -Status $status -Activity "Collecting Information"
            }
            
            $data = Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $server -ErrorAction SilentlyContinue | Where-Object { $_.name -match 'windows' -and $_.licensefamily }
            if ($data) {
                $endDate = $data.graceperiodremaining
                $currentDate = Get-Date
                $preOutput = [PSCustomObject]@{
                    'Server'     = $server
                    'Days Left'  = [math]::Round($data.graceperiodremaining / 1440, 2)
                    'Rearm Date' = $currentDate.AddMinutes($endDate)
                    'Rearms'     = $data.RemainingSkuReArmCount
                }
                $Output += $preOutput
            }
        }
    }

    end {
        # Clear the progress bar
        if (-not $NoProgress) {
            Write-Progress -PercentComplete 100 -Status "Completed" -Activity "Collecting Information" -Completed
        }
        $Output
    }
}

# Example usage:
# Get-LicenseInfo -InputFile "C:\Path\To\ServerList.txt"
# "Server1", "Server2" | Get-LicenseInfo
# Get-LicenseInfo -Server "Server3"
# Get-LicenseInfo  # Defaults to local computer
# Get-LicenseInfo -Server 'server01','server02','server03'
# $pipeServers = @('server01','server02','server03')
# $pipServers | Get-LicenseInfo
