param(
    [string]$MinecraftVersion,
    [switch]$StartServer,
    [switch]$Clean,
    [switch]$Tail
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir ("build-{0}.log" -f $timestamp)
$buildScript = Join-Path $repoRoot "build.ps1"

$forwardArgs = @{}
if ($MinecraftVersion) {
    $forwardArgs["MinecraftVersion"] = $MinecraftVersion
}
if ($StartServer) {
    $forwardArgs["StartServer"] = $true
}
if ($Clean) {
    $forwardArgs["Clean"] = $true
}

$argPreview = if ($forwardArgs.Count -gt 0) {
    ($forwardArgs.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join " "
} else {
    ""
}
"[$(Get-Date -Format o)] Running build.ps1 $argPreview" | Tee-Object -FilePath $logFile

try {
    & $buildScript @forwardArgs 2>&1 | Tee-Object -FilePath $logFile -Append
    $exitCode = $LASTEXITCODE
} catch {
    $exitCode = 1
    $errText = $_ | Out-String
    "Build script threw an exception: $errText" | Tee-Object -FilePath $logFile -Append
}

Write-Host "Log written to $logFile" -ForegroundColor Green

if ($Tail) {
    Get-Content $logFile -Wait
}

exit $exitCode

