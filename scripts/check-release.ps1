# Script to check release pipeline status and artifacts
# Usage: .\scripts\check-release.ps1 [tag]

Param(
    [string]$Tag = ""
)

Write-Host "🔍 Checking Release Status..." -ForegroundColor Cyan
Write-Host ""

# Get latest release if no tag specified
if ([string]::IsNullOrEmpty($Tag)) {
    Write-Host "📦 Latest Release:" -ForegroundColor Yellow
    $release = gh api repos/survivorsunited/mods-su-compostables/releases --jq '.[0] | {name: .name, tag: .tag_name, published: .published_at, asset_count: (.assets | length), assets: [.assets[] | {name: .name, size: (.size / 1024 | floor)}]}' | ConvertFrom-Json
    
    Write-Host "  Name: $($release.name)" -ForegroundColor White
    Write-Host "  Tag: $($release.tag)" -ForegroundColor White
    Write-Host "  Published: $($release.published)" -ForegroundColor White
    Write-Host "  Asset Count: $($release.asset_count)" -ForegroundColor $(if ($release.asset_count -eq 6) { "Green" } else { "Red" })
    Write-Host ""
    Write-Host "  Assets:" -ForegroundColor Yellow
    foreach ($asset in $release.assets) {
        Write-Host "    - $($asset.name) ($($asset.size) KB)" -ForegroundColor White
    }
    
    $Tag = $release.tag
} else {
    Write-Host "📦 Release for tag: $Tag" -ForegroundColor Yellow
    $releaseJson = gh api repos/survivorsunited/mods-su-compostables/releases/tags/$Tag --jq '{name: .name, tag: .tag_name, published: .published_at, asset_count: (.assets | length), assets: [.assets[] | {name: .name, size: (.size / 1024 | floor)}]}' 2>&1
    $errorOutput = $releaseJson | Where-Object { $_ -match "message" }
    
    if ($errorOutput) {
        Write-Host "  ⏳ Release not found yet (may still be building) or error: $errorOutput" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
    
    $release = $releaseJson | ConvertFrom-Json
    
    Write-Host "  Name: $($release.name)" -ForegroundColor White
    Write-Host "  Tag: $($release.tag)" -ForegroundColor White
    Write-Host "  Published: $($release.published)" -ForegroundColor White
    Write-Host "  Asset Count: $($release.asset_count)" -ForegroundColor $(if ($release.asset_count -eq 6) { "Green" } else { "Red" })
    Write-Host ""
    Write-Host "  Assets:" -ForegroundColor Yellow
    foreach ($asset in $release.assets) {
        Write-Host "    - $($asset.name) ($($asset.size) KB)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "🔧 Checking Pipeline Status..." -ForegroundColor Cyan
Write-Host ""

# Get latest workflow runs for tag creation events
$runs = gh run list --workflow=build.yml --limit 5 --json databaseId,status,conclusion,event,headBranch,createdAt --jq '.[] | select(.event == "create") | {id: .databaseId, status: .status, conclusion: .conclusion, branch: .headBranch, created: .createdAt}' | ConvertFrom-Json

if ($runs) {
    $latestRun = $runs | Select-Object -First 1
    Write-Host "  Latest Run ID: $($latestRun.id)" -ForegroundColor White
    Write-Host "  Status: $($latestRun.status)" -ForegroundColor $(if ($latestRun.status -eq "completed") { "Green" } else { "Yellow" })
    Write-Host "  Conclusion: $($latestRun.conclusion)" -ForegroundColor $(if ($latestRun.conclusion -eq "success") { "Green" } elseif ($latestRun.conclusion -eq "failure") { "Red" } else { "Yellow" })
    Write-Host "  Branch/Tag: $($latestRun.branch)" -ForegroundColor White
    Write-Host "  Created: $($latestRun.created)" -ForegroundColor White
    Write-Host ""
    
    if ($latestRun.conclusion -eq "failure") {
        Write-Host "  ❌ Pipeline failed! Checking logs..." -ForegroundColor Red
        Write-Host ""
        
        # Get failed steps
        $failedSteps = gh run view $latestRun.id --json jobs --jq '.jobs[] | select(.name == "release-manual") | .steps[] | select(.conclusion == "failure") | {name: .name, number: .number}' | ConvertFrom-Json
        
        if ($failedSteps) {
            Write-Host "  Failed Steps:" -ForegroundColor Red
            foreach ($step in $failedSteps) {
                Write-Host "    - $($step.name) (step $($step.number))" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "  View full logs: gh run view $($latestRun.id) --log" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  No pipeline runs found for tag creation events" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Check complete!" -ForegroundColor Green


