# Generic pipeline status checker
param(
    [string]$Workflow = "build.yml",
    [int]$Limit = 3
)

$runs = gh run list --workflow=$Workflow --limit $Limit --json databaseId,status,conclusion,displayTitle,headBranch | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Recent Pipeline Runs:" -ForegroundColor Cyan
$runs | ForEach-Object {
    $status = if ($_.status -eq "completed") { 
        if ($_.conclusion -eq "success") { "✅" } else { "❌" }
    } else { "🔄" }
    Write-Host "$status $($_.displayTitle) - $($_.status)/$($_.conclusion) - Branch: $($_.headBranch)" -ForegroundColor $(if ($_.conclusion -eq "success") { "Green" } elseif ($_.conclusion -eq "failure") { "Red" } else { "Yellow" })
}

return $runs
exit 0

