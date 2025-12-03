# Generic git commit and push script
param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [string[]]$Files = @("."),
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$ErrorActionPreference = "Stop"
$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = "echo"

if ($Files -eq "." -or $Files.Count -eq 0) {
    git add . 2>&1 | Out-Null
} else {
    git add $Files 2>&1 | Out-Null
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

git commit -m $Message 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

git push $Remote $Branch 2>&1 | Out-Null
exit $LASTEXITCODE
