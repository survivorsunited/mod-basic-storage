# Generic git commit script - Non-interactive
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = ""

& git commit -m $Message 2>&1 | Out-Null

exit 0
