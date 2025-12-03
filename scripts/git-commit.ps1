# Generic git commit script
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

git commit -m $Message
exit $LASTEXITCODE

