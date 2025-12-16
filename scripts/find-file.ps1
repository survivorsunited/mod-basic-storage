param(
    [string]$Root = ".",
    [string]$Pattern = "*.jar",
    [switch]$Recurse
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}
$logFile = Join-Path $logsDir ("findfile-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

$searchRoot = Resolve-Path (Join-Path $repoRoot $Root)
"[$(Get-Date -Format o)] Searching $searchRoot for $Pattern (Recurse=$Recurse)" | Tee-Object -FilePath $logFile

$params = @{
    Path = $searchRoot
    Filter = $Pattern
    ErrorAction = "Stop"
}
if ($Recurse) {
    $params["Recurse"] = $true
}

try {
    Get-ChildItem @params | ForEach-Object { $_.FullName } | Tee-Object -FilePath $logFile -Append
} catch {
    $err = $_ | Out-String
    "Error searching: $err" | Tee-Object -FilePath $logFile -Append
}

Write-Host "Log written to $logFile" -ForegroundColor Green


