# Generic git add script - Non-interactive
param([string[]]$Files = @("."))

$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = ""

if ($Files -eq "." -or $Files.Count -eq 0) {
    & git add . 2>&1 | Out-Null
} else {
    & git add $Files 2>&1 | Out-Null
}

exit 0
