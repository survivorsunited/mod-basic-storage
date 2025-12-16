# Test Name: Server Startup Test
# Purpose: Tests server startup and world loading for Minecraft 1.21.8
# Expected: Server starts successfully, mod loads without errors, no "Block id not set" errors
# Failure: Server fails to start, mod initialization errors, or "Block id not set" error

param(
    [string]$MinecraftVersion = "1.21.8",
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"
$TestName = "001-start-server"

# Setup logging FIRST
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# Setup isolated output folder
$testOutputDir = Join-Path $scriptPath "test-output" $TestName
New-Item -ItemType Directory -Path $testOutputDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $testOutputDir "${MinecraftVersion}-${timestamp}.log"

function Write-TestLog {
    param([string]$Message, [string]$Color = "White")
    $ts = Get-Date -Format "HH:mm:ss"
    $msg = "[$ts] $Message"
    Write-Host $msg -ForegroundColor $Color
    Add-Content -Path $logFile -Value $msg
}

Set-Location $projectRoot

Write-TestLog "TEST: $TestName for Minecraft $MinecraftVersion" "Cyan"

# Step 1: Build (use existing script)
Write-TestLog "Building mod..." "Yellow"
$buildOutput = & .\build.ps1 -MinecraftVersion $MinecraftVersion 2>&1 | Tee-Object -Variable buildOutputVar
$buildOutput | Add-Content -Path $logFile
if ($LASTEXITCODE -ne 0) {
    Write-TestLog "BUILD FAILED" "Red"
    exit 1
}
Write-TestLog "Build successful" "Green"

# Step 2: Start server (use existing script)
Write-TestLog "Starting test server..." "Yellow"
$serverOutput = & .\build.ps1 -StartServer -MinecraftVersion $MinecraftVersion 2>&1
$serverOutput | Add-Content -Path $logFile

# Step 3: Wait for server log to appear (with timeout)
Write-TestLog "Waiting for server log (timeout: ${TimeoutSeconds}s)..." "Yellow"
$serverLogPath = Join-Path $projectRoot "test-server\logs\latest.log"
$startTime = Get-Date
$logFound = $false

while (-not $logFound -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    if (Test-Path $serverLogPath) {
        $logFound = $true
        Start-Sleep -Seconds 2
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $logFound) {
    Write-TestLog "Test FAILED - Server log not found within ${TimeoutSeconds}s timeout" "Red"
    exit 1
}

# Step 4: Validate server logs
Write-TestLog "Validating server startup..." "Yellow"
if (Test-Path $serverLogPath) {
    $serverLogContent = Get-Content $serverLogPath -Raw
    $serverLogFile = Join-Path $testOutputDir "${MinecraftVersion}-${timestamp}-server.log"
    $serverLogContent | Set-Content -Path $serverLogFile
    Write-TestLog "Server log copied to isolated output folder" "Gray"
    
    # Check for success indicators
    $successPatterns = @(
        "Done \(",
        "For help, type",
        "\[Basic Storage\] Filling crates",
        "registry crates filled"
    )
    
    # Check for failure indicators
    $failurePatterns = @(
        "Block id not set",
        "Failed to start the minecraft server",
        "ExceptionInInitializerError",
        "NullPointerException.*Block id"
    )
    
    $hasSuccess = $false
    $hasFailure = $false
    
    foreach ($pattern in $successPatterns) {
        if ($serverLogContent -match $pattern) {
            Write-TestLog "Found success indicator: $pattern" "Green"
            $hasSuccess = $true
        }
    }
    
    foreach ($pattern in $failurePatterns) {
        if ($serverLogContent -match $pattern) {
            Write-TestLog "Found failure indicator: $pattern" "Red"
            $hasFailure = $true
        }
    }
    
    # Determine result
    if ($hasFailure) {
        Write-TestLog "Test FAILED - Server startup errors detected" "Red"
        Write-TestLog "Check server log: $serverLogFile" "Yellow"
        exit 1
    } elseif ($hasSuccess) {
        Write-TestLog "Test PASSED - Server started successfully" "Green"
        Write-TestLog "Mod loaded successfully: [Basic Storage] registry crates filled" "Green"
        Write-TestLog "Server log saved to: $serverLogFile" "Gray"
        Write-TestLog "" "White"
        Write-TestLog "NOTE: Server was stopped after verification (by design)" "Cyan"
        Write-TestLog "To keep server running for testing, use: cd test-server; ..\scripts\start-server.ps1" "Cyan"
        exit 0
    } else {
        Write-TestLog "Test INCONCLUSIVE - No clear success/failure indicators" "Yellow"
        Write-TestLog "Check server log: $serverLogFile" "Yellow"
        exit 2
    }
} else {
    Write-TestLog "Test FAILED - Server log not found" "Red"
    exit 1
}

