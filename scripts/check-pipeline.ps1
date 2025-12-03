# Quick pipeline status checker
$runs = gh run list --workflow=build.yml --limit 3 --json databaseId,status,conclusion,displayTitle,headBranch | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Recent Pipeline Runs:" -ForegroundColor Cyan
$runs | ForEach-Object {
    $status = if ($_.status -eq "completed") { 
        if ($_.conclusion -eq "success") { "✅" } else { "❌" }
    } else { "🔄" }
    Write-Host "$status $($_.displayTitle) - $($_.status)/$($_.conclusion) - Branch: $($_.headBranch)" -ForegroundColor $(if ($_.conclusion -eq "success") { "Green" } elseif ($_.conclusion -eq "failure") { "Red" } else { "Yellow" })
}

$latestFailed = $runs | Where-Object { $_.conclusion -eq "failure" } | Select-Object -First 1

if ($latestFailed) {
    Write-Host "`nChecking latest failed run: $($latestFailed.databaseId)" -ForegroundColor Yellow
    $errorLog = gh run view $latestFailed.databaseId --log-failed 2>&1 | Select-String -Pattern "error|Error|ERROR|failed|Failed|No JAR|mod_version|jar_name|Update Gradle" | Select-Object -First 10
    if ($errorLog) {
        Write-Host "`nErrors found:" -ForegroundColor Red
        $errorLog
    }
}

exit 0


