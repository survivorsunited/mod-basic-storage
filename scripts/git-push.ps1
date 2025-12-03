# Generic git push script
param(
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

git push $Remote $Branch 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Failed to push"
    exit $LASTEXITCODE 
}

exit 0

