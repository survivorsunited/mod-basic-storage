# Verify release workflow configuration
param(
    [string]$Version = "1.1.0"
)

Write-Host "Verifying release workflow for version: $Version" -ForegroundColor Cyan

# Check if tag exists
$tagExists = git tag -l $Version
if ($tagExists) {
    Write-Host "✅ Tag $Version exists" -ForegroundColor Green
} else {
    Write-Host "⚠️ Tag $Version does not exist" -ForegroundColor Yellow
}

# Check gradle.properties version
$modVersionLine = Select-String -Path gradle.properties -Pattern "mod_version\s*="
if ($modVersionLine) {
    $gradleVersion = ($modVersionLine.Line -replace ".*mod_version\s*=\s*", "").Trim()
    Write-Host "Current mod_version in gradle.properties: $gradleVersion" -ForegroundColor Cyan
} else {
    Write-Host "⚠️ Could not find mod_version in gradle.properties" -ForegroundColor Yellow
}

# Check versions.json
if (Test-Path versions.json) {
    Write-Host "✅ versions.json exists" -ForegroundColor Green
    $versions = Get-Content versions.json | ConvertFrom-Json
    $versionCount = ($versions.PSObject.Properties | Measure-Object).Count
    Write-Host "Configured Minecraft versions: $versionCount" -ForegroundColor Cyan
    $versions.PSObject.Properties.Name | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ versions.json not found" -ForegroundColor Red
    exit 1
}

# Check workflow file
if (Test-Path .github/workflows/build.yml) {
    Write-Host "✅ Build workflow exists" -ForegroundColor Green
    
    # Check if release-manual job exists
    $workflowContent = Get-Content .github/workflows/build.yml -Raw
    if ($workflowContent -match "release-manual") {
        Write-Host "✅ release-manual job found" -ForegroundColor Green
    } else {
        Write-Host "❌ release-manual job not found" -ForegroundColor Red
        exit 1
    }
    
    # Check if it builds all versions
    $mcVersions = @("1.21.5", "1.21.6", "1.21.7", "1.21.8", "1.21.9", "1.21.10")
    foreach ($mcVer in $mcVersions) {
        if ($workflowContent -match $mcVer) {
            Write-Host "  ✅ $mcVer configured" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ $mcVer not found in workflow" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ Build workflow not found" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Release workflow verification complete!" -ForegroundColor Green
exit 0

