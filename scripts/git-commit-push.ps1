# Generic git commit and push script
param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [string[]]$Files = @("."),
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

# Add files
if ($Files -eq "." -or $Files.Count -eq 0) {
    git add .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    git add $Files
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# Commit
git commit -m $Message
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Push
git push $Remote $Branch
exit $LASTEXITCODE

