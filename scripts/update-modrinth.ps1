# Update Modrinth Project Description
# Updates the project description on Modrinth using the API

param(
    [Parameter(Mandatory=$false)]
    [string]$ModrinthToken = $env:MODRINTH_TOKEN,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectId = $env:PROJECT_ID,
    
    [string]$DescriptionFile = "docs/docs/modrinth.md",
    [switch]$Help
)

# Show help
if ($Help) {
    Write-Host @"
Update Modrinth Project Description

Usage: .\scripts\update-modrinth.ps1 [options]

Options:
  -ModrinthToken <token>    Modrinth API token (or set MODRINTH_TOKEN env var)
  -ProjectId <id>          Project ID/slug (or set PROJECT_ID env var)
  -DescriptionFile <path>   Path to description file (default: docs/docs/modrinth.md)
  -Help                    Show this help message

Environment Variables:
  MODRINTH_TOKEN   Your Modrinth API token
  PROJECT_ID       Your project ID/slug (e.g., su-compostables)

Example:
  .\scripts\update-modrinth.ps1 -ModrinthToken "your-token" -ProjectId "su-compostables"
"@
    exit 0
}

# Function to check if command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Check for required tools
if (-not (Test-CommandExists "curl")) {
    Write-Host "❌ curl is required but not found!" -ForegroundColor Red
    Write-Host "Please install curl or use Git Bash / WSL" -ForegroundColor Yellow
    exit 1
}

# Validate parameters
if (-not $ModrinthToken) {
    Write-Host "❌ Modrinth token is required!" -ForegroundColor Red
    Write-Host "Set the MODRINTH_TOKEN environment variable or use -ModrinthToken parameter" -ForegroundColor Yellow
    Write-Host "Get your token from: https://modrinth.com/settings/account" -ForegroundColor Cyan
    exit 1
}

if (-not $ProjectId) {
    Write-Host "❌ Project ID is required!" -ForegroundColor Red
    Write-Host "Set the PROJECT_ID environment variable or use -ProjectId parameter" -ForegroundColor Yellow
    Write-Host "Find your project ID in the Modrinth project URL" -ForegroundColor Cyan
    exit 1
}

# Check if description file exists
if (-not (Test-Path $DescriptionFile)) {
    Write-Host "❌ Description file not found: $DescriptionFile" -ForegroundColor Red
    Write-Host "Please ensure the description file exists" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Updating Modrinth project description..." -ForegroundColor Cyan
Write-Host "Project ID: $ProjectId" -ForegroundColor Gray
Write-Host "Description file: $DescriptionFile" -ForegroundColor Gray

try {
    # Read and prepare description
    # Extract content after front matter
    $content = Get-Content $DescriptionFile -Raw
    # Remove front matter (everything between first two --- lines)
    $description = ($content -split '---')[2..($content -split '---').Length] -join '---'
    $description = $description.Trim()
    
    # Create temporary file for JSON payload
    $tempFile = [System.IO.Path]::GetTempFileName()
    $jsonPayload = @{
        description = $description
    } | ConvertTo-Json -Depth 10 -Compress
    
    $jsonPayload | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
    
    # Make API request
    Write-Host "📡 Sending API request..." -ForegroundColor Gray
    
    $curlArgs = @(
        "-X", "PATCH"
        "-H", "Authorization: Bearer $ModrinthToken"
        "-H", "Content-Type: application/json"
        "-d", "@$tempFile"
        "https://api.modrinth.com/v3/project/$ProjectId"
        "--fail-with-body"
        "--silent"
        "--show-error"
    )
    
    $result = & curl $curlArgs 2>&1
    $exitCode = $LASTEXITCODE
    
    # Clean up temp file
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    
    if ($exitCode -eq 0) {
        Write-Host "✅ Modrinth project description updated successfully!" -ForegroundColor Green
        
        # Try to parse and display response info
        try {
            $response = $result | ConvertFrom-Json
            if ($response.title) {
                Write-Host "Project: $($response.title)" -ForegroundColor Gray
            }
            if ($response.description) {
                $descLength = $response.description.Length
                Write-Host "Description length: $descLength characters" -ForegroundColor Gray
            }
        } catch {
            # If response isn't JSON, just show success
        }
        
        Write-Host "🌐 View your project: https://modrinth.com/mod/$ProjectId" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Failed to update Modrinth project description" -ForegroundColor Red
        Write-Host "Error response: $result" -ForegroundColor Yellow
        
        # Common error messages
        if ($result -like "*401*" -or $result -like "*unauthorized*") {
            Write-Host "`n💡 Common fixes for 401 Unauthorized:" -ForegroundColor Cyan
            Write-Host "- Check that your API token is valid" -ForegroundColor Gray
            Write-Host "- Ensure you have permission to edit this project" -ForegroundColor Gray
            Write-Host "- Verify the token hasn't expired" -ForegroundColor Gray
        } elseif ($result -like "*404*" -or $result -like "*not found*") {
            Write-Host "`n💡 Common fixes for 404 Not Found:" -ForegroundColor Cyan
            Write-Host "- Check that the project ID '$ProjectId' is correct" -ForegroundColor Gray
            Write-Host "- Verify the project exists and is published" -ForegroundColor Gray
        }
        
        exit 1
    }
} catch {
    Write-Host "❌ Unexpected error: $_" -ForegroundColor Red
    exit 1
}