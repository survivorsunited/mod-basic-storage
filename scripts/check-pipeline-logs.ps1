# Script to check pipeline logs for a specific run
# Usage: .\scripts\check-pipeline-logs.ps1 [run-id]

Param(
    [Parameter(Mandatory=$false)]
    [string]$RunId = ""
)

if ([string]::IsNullOrEmpty($RunId)) {
    Write-Host "🔍 Getting latest run..." -ForegroundColor Cyan
    $runsJson = gh run list --workflow=build.yml --limit 5 --json databaseId,status,conclusion,event,headBranch
    $runs = $runsJson | ConvertFrom-Json
    $run = $runs | Where-Object { $_.event -eq "create" } | Select-Object -First 1
    if ($run) {
        $RunId = $run.databaseId
        Write-Host "  Using Run ID: $RunId (branch: $($run.headBranch), conclusion: $($run.conclusion))" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "  ❌ No tag creation runs found" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📋 Checking logs for run $RunId..." -ForegroundColor Cyan
Write-Host ""

# Get failed steps
Write-Host "❌ Failed Steps:" -ForegroundColor Red
$failedSteps = gh run view $RunId --json jobs --jq '.jobs[] | select(.name == "release-manual") | .steps[] | select(.conclusion == "failure") | {name: .name, number: .number}' | ConvertFrom-Json

if ($failedSteps) {
    foreach ($step in $failedSteps) {
        Write-Host "  - $($step.name) (step $($step.number))" -ForegroundColor Red
    }
} else {
    Write-Host "  No failed steps found in release-manual job" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Key log messages:" -ForegroundColor Cyan

# Check for specific error patterns
$patterns = @(
    "syntax error",
    "Failed to find JAR",
    "No JARs found",
    "Built:",
    "All JARs collected",
    "Found JARs:",
    "Collect all versioned JARs"
)

$logContent = gh run view $RunId --log 2>&1

foreach ($pattern in $patterns) {
    $matches = $logContent | Select-String -Pattern $pattern -CaseSensitive:$false
    if ($matches) {
        Write-Host ""
        Write-Host "  Pattern: $pattern" -ForegroundColor Yellow
        $matches | Select-Object -First 5 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "💡 View full logs: gh run view $RunId --log" -ForegroundColor Yellow

