<#
.SYNOPSIS
  Build the mod for every Minecraft version in versions.json. JARs are copied to build-output/.
  Use -NoBump so the version in gradle.properties is not incremented (only first run bumps if -NoBump not set).
.EXAMPLE
  .\build-all.ps1
  .\build-all.ps1 -NoBump
#>
param(
    [switch]$NoBump
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$versionsPath = Join-Path $projectRoot "versions.json"
if (-not (Test-Path $versionsPath)) {
    Write-Host "versions.json not found" -ForegroundColor Red
    exit 1
}

$v = Get-Content $versionsPath -Raw | ConvertFrom-Json
$mcVersions = @()
foreach ($p in $v.minecraft.PSObject.Properties) {
    if ($p.Name -notmatch '^_') { $mcVersions += $p.Name }
}
$mcVersions = $mcVersions | Sort-Object

Write-Host "Building all versions: $($mcVersions -join ', ')" -ForegroundColor Cyan

$built = @()
$failed = @()
$bumpDone = $false

foreach ($mc in $mcVersions) {
    Write-Host "`n--- Building Minecraft $mc ---" -ForegroundColor Yellow
    $doBump = -not $NoBump -and -not $bumpDone
    $bumpDone = $true
    try {
        if ($doBump) {
            & (Join-Path $projectRoot "build.ps1") -MinecraftVersion $mc
        } else {
            & (Join-Path $projectRoot "build.ps1") -MinecraftVersion $mc -NoBump
        }
        if ($LASTEXITCODE -eq 0) { $built += $mc } else { $failed += $mc }
    } catch {
        Write-Host "Build for $mc failed: $_" -ForegroundColor Red
        $failed += $mc
    }
}

Write-Host "`n=== Build summary ===" -ForegroundColor Cyan
Write-Host "Built: $($built -join ', ')" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "Failed: $($failed -join ', ')" -ForegroundColor Red
}
$outPath = Join-Path $projectRoot "build-output"
if (Test-Path $outPath) {
    $jars = Get-ChildItem -Path $outPath -Filter "*.jar" -ErrorAction SilentlyContinue
    Write-Host "JARs in build-output/: $($jars.Count)" -ForegroundColor Cyan
    $jars | ForEach-Object { Write-Host "  $($_.Name)" }
}
if ($failed.Count -gt 0) { exit 1 }
