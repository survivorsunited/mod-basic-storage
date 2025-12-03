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
    git add . 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { 
        Write-Error "Failed to add files"
        exit $LASTEXITCODE 
    }
} else {
    git add $Files 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { 
        Write-Error "Failed to add files"
        exit $LASTEXITCODE 
    }
}

# Commit
git commit -m $Message 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Failed to commit"
    exit $LASTEXITCODE 
}

# Push
git push $Remote $Branch 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Failed to push"
    exit $LASTEXITCODE 
}

exit 0

