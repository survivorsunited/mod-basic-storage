# Generic git commit script
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$ErrorActionPreference = "Stop"
$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = "echo"

git commit -m $Message 2>&1 | Out-Null
exit $LASTEXITCODE
