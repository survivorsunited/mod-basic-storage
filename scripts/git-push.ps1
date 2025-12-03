# Generic git push script
param(
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$env:GIT_TERMINAL_PROMPT = "0"
git push $Remote $Branch 2>&1 | Out-Null
exit $LASTEXITCODE
