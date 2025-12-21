# Test Name: Version Bump Test
# Purpose: Tests that build.ps1 automatically increments the mod version on each build
# Expected: Version increments from X.Y.Z to X.Y.(Z+1) after each build
# Failure: Version does not increment, or increment logic fails

param(
    [string]$MinecraftVersion = "1.21.8"
)

$ErrorActionPreference = "Stop"
$TestName = "002-version-bump"

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

Write-TestLog "TEST: $TestName" "Cyan"
Write-TestLog "Testing automatic version bump functionality" "Yellow"

# Step 1: Read initial version from gradle.properties
Write-TestLog "Step 1: Reading initial version from gradle.properties..." "Yellow"
$gradlePropsPath = Join-Path $projectRoot "gradle.properties"

if (-not (Test-Path $gradlePropsPath)) {
    Write-TestLog "ERROR: gradle.properties not found" "Red"
    exit 1
}

$initialProps = Get-Content $gradlePropsPath -Raw
if ($initialProps -match "mod_version=(.+?)(\r?\n|$)") {
    $initialVersion = $Matches[1].Trim()
    Write-TestLog "Initial version: $initialVersion" "Green"
} else {
    Write-TestLog "ERROR: Could not find mod_version in gradle.properties" "Red"
    exit 1
}

# Parse version to extract patch number
if ($initialVersion -match "^(\d+)\.(\d+)\.(\d+)(.*)$") {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $suffix = $Matches[4]
    $expectedVersion1 = "$major.$minor.$($patch + 1)$suffix"
    $expectedVersion2 = "$major.$minor.$($patch + 2)$suffix"
    Write-TestLog "Expected version after first build: $expectedVersion1" "Cyan"
    Write-TestLog "Expected version after second build: $expectedVersion2" "Cyan"
} else {
    Write-TestLog "ERROR: Could not parse version format: $initialVersion" "Red"
    exit 1
}

# Step 2: Run first build and verify version increment
Write-TestLog "Step 2: Running first build..." "Yellow"
try {
    $buildOutput = & ".\build.ps1" -MinecraftVersion $MinecraftVersion 2>&1 | Out-String
    Add-Content -Path $logFile -Value "`n=== BUILD OUTPUT ===" 
    Add-Content -Path $logFile -Value $buildOutput
    
    if ($LASTEXITCODE -ne 0) {
        Write-TestLog "ERROR: First build failed with exit code $LASTEXITCODE" "Red"
        exit 1
    }
    Write-TestLog "First build completed successfully" "Green"
} catch {
    Write-TestLog "ERROR: First build threw exception: $_" "Red"
    exit 1
}

# Verify version was incremented
Write-TestLog "Step 3: Verifying version was incremented..." "Yellow"
$propsAfterBuild1 = Get-Content $gradlePropsPath -Raw
if ($propsAfterBuild1 -match "mod_version=(.+?)(\r?\n|$)") {
    $versionAfterBuild1 = $Matches[1].Trim()
    Write-TestLog "Version after first build: $versionAfterBuild1" "Cyan"
    
    if ($versionAfterBuild1 -eq $expectedVersion1) {
        Write-TestLog "PASS: Version correctly incremented to $expectedVersion1" "Green"
    } else {
        Write-TestLog "FAIL: Version is $versionAfterBuild1, expected $expectedVersion1" "Red"
        exit 1
    }
} else {
    Write-TestLog "ERROR: Could not read version after first build" "Red"
    exit 1
}

# Step 4: Run second build and verify version increments again
Write-TestLog "Step 4: Running second build..." "Yellow"
try {
    $buildOutput2 = & ".\build.ps1" -MinecraftVersion $MinecraftVersion 2>&1 | Out-String
    Add-Content -Path $logFile -Value "`n=== SECOND BUILD OUTPUT ===" 
    Add-Content -Path $logFile -Value $buildOutput2
    
    if ($LASTEXITCODE -ne 0) {
        Write-TestLog "ERROR: Second build failed with exit code $LASTEXITCODE" "Red"
        exit 1
    }
    Write-TestLog "Second build completed successfully" "Green"
} catch {
    Write-TestLog "ERROR: Second build threw exception: $_" "Red"
    exit 1
}

# Verify version was incremented again
Write-TestLog "Step 5: Verifying version was incremented again..." "Yellow"
$propsAfterBuild2 = Get-Content $gradlePropsPath -Raw
if ($propsAfterBuild2 -match "mod_version=(.+?)(\r?\n|$)") {
    $versionAfterBuild2 = $Matches[1].Trim()
    Write-TestLog "Version after second build: $versionAfterBuild2" "Cyan"
    
    if ($versionAfterBuild2 -eq $expectedVersion2) {
        Write-TestLog "PASS: Version correctly incremented to $expectedVersion2" "Green"
    } else {
        Write-TestLog "FAIL: Version is $versionAfterBuild2, expected $expectedVersion2" "Red"
        exit 1
    }
} else {
    Write-TestLog "ERROR: Could not read version after second build" "Red"
    exit 1
}

# Step 6: Verify JAR files were created with correct versions
Write-TestLog "Step 6: Verifying JAR files were created..." "Yellow"
$jar1 = Join-Path $projectRoot "build\libs\basicstorage-$expectedVersion1.jar"
$jar2 = Join-Path $projectRoot "build\libs\basicstorage-$expectedVersion2.jar"

if (Test-Path $jar1) {
    Write-TestLog "PASS: JAR file exists: basicstorage-$expectedVersion1.jar" "Green"
} else {
    Write-TestLog "WARNING: JAR file not found: basicstorage-$expectedVersion1.jar" "Yellow"
}

if (Test-Path $jar2) {
    Write-TestLog "PASS: JAR file exists: basicstorage-$expectedVersion2.jar" "Green"
} else {
    Write-TestLog "WARNING: JAR file not found: basicstorage-$expectedVersion2.jar" "Yellow"
}

# Step 7: Restore original version (optional - comment out if you want to keep the bumped version)
Write-TestLog "Step 7: Restoring original version..." "Yellow"
$restoredProps = $propsAfterBuild2 -replace "mod_version=.*", "mod_version=$initialVersion"
Set-Content -Path $gradlePropsPath -Value $restoredProps -NoNewline
Write-TestLog "Restored version to: $initialVersion" "Green"

# Final result
Write-TestLog "`n=== TEST RESULT ===" "Cyan"
Write-TestLog "Result: PASSED" "Green"
Write-TestLog "Version bump functionality is working correctly!" "Green"
Write-TestLog "Log file: $logFile" "Cyan"

exit 0



