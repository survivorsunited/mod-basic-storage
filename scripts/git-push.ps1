# Generic git push script
param(
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

git push $Remote $Branch
exit $LASTEXITCODE

