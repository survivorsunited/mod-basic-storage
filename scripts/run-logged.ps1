param(
    [Parameter(Mandatory = $true)]
    [string]$CommandLine,
    [string]$LogPrefix = "run"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}
$logFile = Join-Path $logsDir ("{0}-{1}.log" -f $LogPrefix, (Get-Date -Format "yyyyMMdd-HHmmss"))

"[$(Get-Date -Format o)] Running: $CommandLine" | Tee-Object -FilePath $logFile

Push-Location $repoRoot
try {
    pwsh -NoLogo -NoProfile -Command $CommandLine 2>&1 | Tee-Object -FilePath $logFile -Append
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

"[$(Get-Date -Format o)] Exit code: $exitCode" | Tee-Object -FilePath $logFile -Append

Write-Host "Log written to $logFile" -ForegroundColor Green
exit $exitCode






