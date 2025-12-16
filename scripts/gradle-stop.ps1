Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir ("gradle-stop-{0}.log" -f $timestamp)

"[$(Get-Date -Format o)] Running ./gradlew --stop" | Tee-Object -FilePath $logFile

try {
    Push-Location $repoRoot
    ./gradlew --stop 2>&1 | Tee-Object -FilePath $logFile -Append
    $exitCode = $LASTEXITCODE
} catch {
    $exitCode = 1
    $err = $_ | Out-String
    "Failed to stop Gradle: $err" | Tee-Object -FilePath $logFile -Append
} finally {
    Pop-Location
}

Write-Host "Log written to $logFile" -ForegroundColor Green
exit $exitCode

