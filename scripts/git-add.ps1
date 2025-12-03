# Generic git add script
param([string[]]$Files = @("."))

if ($Files -eq "." -or $Files.Count -eq 0) {
    git add .
} else {
    git add $Files
}
exit $LASTEXITCODE

