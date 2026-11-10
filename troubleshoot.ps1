<#
.SYNOPSIS
    Basic troubleshooting: make sure the Print Spooler is running and clear out old log files.

.DESCRIPTION
    1. Checks the Print Spooler service and starts it if it isn't running.
    2. Deletes items in the log folder that haven't been modified in the last 30 days.
    Errors are reported as warnings so one failed step doesn't stop the rest.

.EXAMPLE
    .\troubleshoot.ps1 -WhatIf
    Preview mode: lists what would be started or deleted without changing anything.

.EXAMPLE
    .\troubleshoot.ps1
    Runs for real.

.NOTES
    Starting a service requires an elevated (Run as administrator) PowerShell prompt.
#>

# SupportsShouldProcess adds the -WhatIf and -Confirm switches. Start-Service and
# Remove-Item below automatically respect them.
[CmdletBinding(SupportsShouldProcess)]
param()

# --- Settings ---
$serviceName   = 'Spooler'          # Windows service to check (Print Spooler)
$logFolder     = 'C:\Temp\Logs'     # Folder to clean up
$maxLogAgeDays = 30                 # Items older than this many days are deleted
$cutoffDate    = (Get-Date).AddDays(-$maxLogAgeDays)

# --- Step 1: Make sure the Print Spooler service is running ---
try {
    $spoolerService = Get-Service -Name $serviceName -ErrorAction Stop
    if ($spoolerService.Status -ne 'Running') {
        Start-Service -Name $serviceName -ErrorAction Stop
    }
}
catch {
    Write-Warning "Could not check or start service '$serviceName': $($_.Exception.Message)"
}

# --- Step 2: Delete log items older than the cutoff date ---
if (Test-Path -Path $logFolder) {
    $logFiles = Get-ChildItem -Path $logFolder
    foreach ($logFile in $logFiles) {
        if ($logFile.LastWriteTime -lt $cutoffDate) {
            try {
                # With -WhatIf this prints "What if: ... Remove File" instead of deleting
                Remove-Item -Path $logFile.FullName -ErrorAction Stop
            }
            catch {
                # Keep going so one locked or protected file doesn't stop the cleanup
                Write-Warning "Could not delete '$($logFile.FullName)': $($_.Exception.Message)"
            }
        }
    }
}
else {
    Write-Warning "Log folder '$logFolder' not found; skipping cleanup."
}

Write-Host "done"
