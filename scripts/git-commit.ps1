# Generic git commit script
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

git commit -m $Message 2>&1 | Out-Null
exit $LASTEXITCODE
