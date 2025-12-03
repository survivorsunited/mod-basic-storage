# Watch pipeline until completion
param(
    [string]$Workflow = "build.yml",
    [int]$MaxWait = 600,
    [int]$CheckInterval = 15
)

Write-Host "Watching pipeline..." -ForegroundColor Cyan
$elapsed = 0

while ($elapsed -lt $MaxWait) {
    $run = gh run list --workflow=$Workflow --limit 1 --json databaseId,status,conclusion,displayTitle | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    
    $status = if ($run.status -eq "completed") { 
        if ($run.conclusion -eq "success") { "✅ SUCCESS" } else { "❌ FAILED" }
    } else { "🔄 RUNNING" }
    
    Write-Host "[$elapsed s] $status - $($run.displayTitle)" -ForegroundColor $(if ($run.status -eq "completed") { if ($run.conclusion -eq "success") { "Green" } else { "Red" } } else { "Yellow" })
    
    if ($run.status -eq "completed") {
        if ($run.conclusion -eq "failure") {
            Write-Host "`nChecking errors..." -ForegroundColor Red
            .\scripts\get-pipeline-errors.ps1
            exit 1
        }
        exit 0
    }
    
    Start-Sleep -Seconds $CheckInterval
    $elapsed += $CheckInterval
}

if ($elapsed -ge $MaxWait) {
    Write-Host "Timeout waiting for pipeline" -ForegroundColor Yellow
    exit 1
}

exit 0


