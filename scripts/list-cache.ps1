param(
    [string]$Path = ".",
    [string]$Filter = "*",
    [switch]$Recurse,
    [int]$Take = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}
$logFile = Join-Path $logsDir ("list-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

function Resolve-PathSafe {
    param([string]$InputPath)
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        return $repoRoot
    }
    $fullPath = Join-Path $repoRoot $InputPath
    if (Test-Path $fullPath) {
        return (Resolve-Path $fullPath).Path
    }
    throw "Path $InputPath not found."
}

$targetPath = Resolve-PathSafe -InputPath $Path
"[$(Get-Date -Format o)] Listing $targetPath (Filter=$Filter Recurse=$Recurse Take=$Take)" | Tee-Object -FilePath $logFile

$params = @{
    Path   = $targetPath
    Filter = $Filter
}
if ($Recurse) {
    $params["Recurse"] = $true
}

$items = Get-ChildItem @params | Sort-Object FullName
if ($Take -gt 0) {
    $items = $items | Select-Object -First $Take
}

$items | Select-Object FullName, Length | Format-Table -AutoSize | Out-String -Width 4096 | Tee-Object -FilePath $logFile -Append

Write-Host "Log written to $logFile" -ForegroundColor Green


