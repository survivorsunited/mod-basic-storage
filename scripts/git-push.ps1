# Generic git push script
param(
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$ErrorActionPreference = "Stop"
$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = "echo"

git push $Remote $Branch 2>&1 | Out-Null
exit $LASTEXITCODE
