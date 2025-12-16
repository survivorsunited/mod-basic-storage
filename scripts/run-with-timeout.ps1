# Wrapper script to run commands with timeout
param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    [int]$TimeoutSeconds = 60,
    [string]$LogFile = ""
)

$ErrorActionPreference = "Stop"

$job = Start-Job -ScriptBlock {
    param($cmd)
    Invoke-Expression $cmd 2>&1
} -ArgumentList $Command

$result = Wait-Job -Job $job -Timeout $TimeoutSeconds | Receive-Job

if ($job.State -eq "Running") {
    Stop-Job -Job $job
    Remove-Job -Job $job
    Write-Error "Command timed out after ${TimeoutSeconds}s: $Command"
    exit 1
}

Remove-Job -Job $job

if ($LogFile -and $LogFile -ne "") {
    $result | Add-Content -Path $LogFile
}

$result | Write-Output

exit 0

