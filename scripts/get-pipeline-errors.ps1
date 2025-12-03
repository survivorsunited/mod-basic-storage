# Get detailed pipeline errors
$runId = (gh run list --workflow=build.yml --limit 1 --json databaseId -q '.[0].databaseId')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Checking run: $runId" -ForegroundColor Cyan

# Get failed jobs
$jobs = gh run view $runId --json jobs | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$failedJobs = $jobs.jobs | Where-Object { $_.conclusion -eq "failure" }

foreach ($job in $failedJobs) {
    Write-Host "`n❌ Failed Job: $($job.name)" -ForegroundColor Red
    $failedSteps = $job.steps | Where-Object { $_.conclusion -eq "failure" }
    foreach ($step in $failedSteps) {
        Write-Host "  Failed Step: $($step.name)" -ForegroundColor Yellow
    }
}

# Get specific error for build-matrix
$buildMatrix = $failedJobs | Where-Object { $_.name -like "*build-matrix*" } | Select-Object -First 1
if ($buildMatrix) {
    Write-Host "`nChecking build-matrix errors..." -ForegroundColor Cyan
    gh run view $runId --log | Select-String -Pattern "build-matrix.*Rename JAR|No JAR|mod_version|Update Gradle|BUILD FAILED" | Select-Object -First 15
}

exit 0


