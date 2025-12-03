# Generic git push script - Non-interactive
param(
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = ""

& git push $Remote $Branch 2>&1 | Out-Null

exit 0
