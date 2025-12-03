# Generic git commit and push script - Non-interactive
param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [string[]]$Files = @("."),
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = ""

if ($Files -eq "." -or $Files.Count -eq 0) {
    & git add . 2>&1 | Out-Null
} else {
    & git add $Files 2>&1 | Out-Null
}

& git commit -m $Message 2>&1 | Out-Null
& git push $Remote $Branch 2>&1 | Out-Null

exit 0
