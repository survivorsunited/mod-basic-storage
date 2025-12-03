# Get latest pipeline run ID
param(
    [string]$Workflow = "build.yml"
)

$runId = (gh run list --workflow=$Workflow --limit 1 --json databaseId -q '.[0].databaseId')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
return $runId
exit 0

