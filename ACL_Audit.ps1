<#
    https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-9.0
#>

function Get-SACLAudit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Verbose -Message "SACL for $Path : $($acl.AuditToString)"
    $sacl = Get-Acl -Path $Path -Audit
    # $sacl.AuditToString
    $auditRules = $sacl.Audit | Select-Object -Property @{Name="Path";Expression={$Path}}, IdentityReference, FileSystemRights, AuditFlags, IsInherited, InheritanceFlags, PropagationFlags
    return $auditRules
}

function Set-SACLAudit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$IdentityReference,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "ReadData", "WriteData", "AppendData", "ReadExtendedAttributes",
            "WriteExtendedAttributes", "ExecuteFile", "DeleteSubdirectoriesAndFiles",
            "ReadAttributes", "WriteAttributes", "Delete", "ReadPermissions",
            "Write", "Modify", "FullControl", "Synchronize", "TakeOwnership",
            "ChangePermissions", "Traverse", "ListDirectory", "CreateFiles",
            "CreateDirectories"
        )]
        [string]$FileSystemRights,

        [Parameter(Mandatory = $true)]
        [ValidateSet("None", "Success", "Failure")]
        [string]$AuditFlags
    )

    # Confirmation prompt
    $confirmation = Read-Host "Are you sure you want to overwrite all audit rules for this path? (y/n)"
    if ($confirmation -ne "y") {
        Write-Output "Operation canceled."
        return
    }

    $sacl = Get-Acl -Path $Path -Audit
    Write-Verbose -Message "Current SACL for $Path : $($sacl.AuditToString)"
    
    # Clear existing rules
    $sacl.SetAuditRuleProtection($true, $false)
    foreach ($rule in $sacl.Audit) {
        $sacl.RemoveAuditRule($rule)
    }

    # Add new rule
    $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
        $IdentityReference,
        [System.Security.AccessControl.FileSystemRights]::$FileSystemRights,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AuditFlags]::$AuditFlags
    )
    $sacl.AddAuditRule($auditRule)
    Set-Acl -Path $Path -AclObject $sacl
    Write-Verbose -Message "Set new SACL for $Path : $($sacl.AuditToString)"
}

function Add-SACLAudit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$IdentityReference,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "ReadData", "WriteData", "AppendData", "ReadExtendedAttributes", 
            "WriteExtendedAttributes", "ExecuteFile", "DeleteSubdirectoriesAndFiles", 
            "ReadAttributes", "WriteAttributes", "Delete", "ReadPermissions", 
            "Write", "Modify", "FullControl", "Synchronize", "TakeOwnership", 
            "ChangePermissions", "Traverse", "ListDirectory", "CreateFiles", 
            "CreateDirectories"
        )]
        [string]$FileSystemRights,

        [Parameter(Mandatory = $true)]
        [ValidateSet("None", "Success", "Failure")]
        [string]$AuditFlags
    )

    $sacl = Get-Acl -Path $Path -Audit
    Write-Verbose -Message "Current SACL for $Path : $($sacl.AuditToString)"
    $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
        $IdentityReference,
        [System.Security.AccessControl.FileSystemRights]::$FileSystemRights,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AuditFlags]::$AuditFlags
    )
    $sacl.AddAuditRule($auditRule)
    Set-Acl -Path $Path -AclObject $sacl
    Write-Verbose -Message "Added SACL for $Path : $($sacl.AuditToString)"
}


function Remove-SACLAudit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$IdentityReference,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "ReadData", "WriteData", "AppendData", "ReadExtendedAttributes",
            "WriteExtendedAttributes", "ExecuteFile", "DeleteSubdirectoriesAndFiles",
            "ReadAttributes", "WriteAttributes", "Delete", "ReadPermissions",
            "Write", "Modify", "FullControl", "Synchronize", "TakeOwnership",
            "ChangePermissions", "Traverse", "ListDirectory", "CreateFiles",
            "CreateDirectories"
        )]
        [string]$FileSystemRights,

        [Parameter(Mandatory = $true)]
        [ValidateSet("None", "Success", "Failure")]
        [string]$AuditFlags
    )

    # Confirmation prompt
    $confirmation = Read-Host "Are you sure you want to remove the audit rule? (y/n)"
    if ($confirmation -ne "y") {
        Write-Output "Operation canceled."
        return
    }

    $sacl = Get-Acl -Path $Path -Audit
    Write-Verbose -Message "Current SACL for $Path : $($sacl.AuditToString)"
    $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
        $IdentityReference,
        [System.Security.AccessControl.FileSystemRights]::$FileSystemRights,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AuditFlags]::$AuditFlags
    )
    $sacl.RemoveAuditRule($auditRule)
    Set-Acl -Path $Path -AclObject $sacl
    Write-Verbose -Message "Removed SACL for $Path : $($sacl.AuditToString)"
}

function Get-SACLAudit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Path,

        [switch]$Recurse,

        [switch]$Children
    )

    process {
        foreach ($p in $Path) {
            if (-not (Test-Path -Path $p)) {
                Write-Warning "Path $p does not exist. Skipping..."
                continue
            }

            if (Test-Path -Path $p -PathType Container) {
                # Handle directories
                if ($Recurse) {
                    $items = Get-ChildItem -Path $p -Recurse
                } elseif ($Children) {
                    $items = Get-ChildItem -Path $p
                } else {
                    $items = $p
                }
            } else {
                # Handle files
                $items = $p
            }

            foreach ($item in $items) {
                $sacl = Get-Acl -Path $item -Audit
                $auditRules = $sacl.Audit | Select-Object -Property @{Name = "Path"; Expression = { $item } }, IdentityReference, FileSystemRights, AuditFlags, IsInherited, InheritanceFlags, PropagationFlags

                # Output audit rules
                $auditRules | ForEach-Object { $_ }
            }
        }
    }
}

$a = ("C:\temp\test.txt", "c:\temp\test2.txt")
$a | Get-SACLAudit -Recurse -verbose | select -ExcludeProperty IsInherited, InheritanceFlags, PropagationFlags | Format-Table -AutoSize
("C:\temp\test.txt", "c:\temp\test2.txt") | Get-SACLAudit -Recurse -verbose | select -ExcludeProperty IsInherited, InheritanceFlags, PropagationFlags | Format-Table -AutoSize
Get-SACLAudit -Path "C:\temp\test.txt", "c:\temp\test2.txt" -verbose | select -ExcludeProperty IsInherited, InheritanceFlags, PropagationFlags | Format-Table -AutoSize
