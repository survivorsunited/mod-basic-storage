param(
    [string]$Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $Target) {
    Write-Host "Please supply -Target" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir ("rm-{0}.log" -f $timestamp)
$resolvedTarget = Resolve-Path -Path (Join-Path $repoRoot $Target) -ErrorAction SilentlyContinue

if (-not $resolvedTarget) {
    "[$(Get-Date -Format o)] Path '$Target' not found" | Tee-Object -FilePath $logFile
    Write-Host "Log written to $logFile" -ForegroundColor Yellow
    exit 0
}

$resolvedTarget = $resolvedTarget.Path
"[$(Get-Date -Format o)] Removing $resolvedTarget" | Tee-Object -FilePath $logFile

try {
    Remove-Item -Path $resolvedTarget -Recurse -Force
    "Removal succeeded" | Tee-Object -FilePath $logFile -Append
    $exitCode = 0
} catch {
    $err = $_ | Out-String
    "Removal failed: $err" | Tee-Object -FilePath $logFile -Append
    $exitCode = 1
}

Write-Host "Log written to $logFile" -ForegroundColor Green
exit $exitCode

