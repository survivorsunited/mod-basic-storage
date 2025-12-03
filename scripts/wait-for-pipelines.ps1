# Wait for all pipelines to complete
param(
    [int]$MaxWait = 900,  # 15 minutes
    [int]$CheckInterval = 30
)

Write-Host "Waiting for pipelines to complete..." -ForegroundColor Cyan
$elapsed = 0
$allCompleted = $false

while ($elapsed -lt $MaxWait -and !$allCompleted) {
    $runs = gh run list --workflow=build.yml --limit 5 --json databaseId,status,conclusion,displayTitle | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    
    $inProgress = $runs | Where-Object { $_.status -ne "completed" }
    $failed = $runs | Where-Object { $_.conclusion -eq "failure" }
    $succeeded = $runs | Where-Object { $_.conclusion -eq "success" }
    
    Write-Host "[$elapsed s] Running: $($inProgress.Count), Failed: $($failed.Count), Succeeded: $($succeeded.Count)" -ForegroundColor Yellow
    
    if ($inProgress.Count -eq 0) {
        $allCompleted = $true
        Write-Host "`nAll pipelines completed!" -ForegroundColor Green
        if ($failed.Count -gt 0) {
            Write-Host "⚠️ Some pipelines failed. Check with: .\scripts\get-pipeline-errors.ps1" -ForegroundColor Red
            exit 1
        } else {
            Write-Host "✅ All pipelines succeeded!" -ForegroundColor Green
            exit 0
        }
    }
    
    Start-Sleep -Seconds $CheckInterval
    $elapsed += $CheckInterval
}

if ($elapsed -ge $MaxWait) {
    Write-Host "Timeout waiting for pipelines" -ForegroundColor Yellow
    exit 1
}

exit 0

