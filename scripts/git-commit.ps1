# Generic git commit script
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

git commit -m $Message 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Failed to commit"
    exit $LASTEXITCODE 
}

exit 0

