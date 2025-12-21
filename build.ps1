param(
    [string]$MinecraftVersion = "1.21.8",
    [switch]$StartServer,
    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = Get-Location
}

# Set JAVA_HOME if not set
if (-not $env:JAVA_HOME) {
    $javaHome = "C:\data\apps\#dev\jdk\jdk-21.0.7"
    if (Test-Path $javaHome) {
        $env:JAVA_HOME = $javaHome
        Write-Host "JAVA_HOME set to $javaHome" -ForegroundColor Cyan
    }
}

# Function to increment minor version
function Increment-ModVersion {
    param([string]$CurrentVersion)
    
    # Parse version like "1.1.2+1.21.8" -> major=1, minor=1, patch=2, suffix=+1.21.8
    if ($CurrentVersion -match "^(\d+)\.(\d+)\.(\d+)(.*)$") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        $suffix = $Matches[4]
        
        # Increment patch version (third number)
        $patch++
        
        return "$major.$minor.$patch$suffix"
    }
    
    # Fallback: just append .1 if we can't parse
    return "$CurrentVersion.1"
}

# Read current version from gradle.properties
$gradlePropsPath = Join-Path $projectRoot "gradle.properties"
$gradleProps = Get-Content $gradlePropsPath -Raw

# Extract current mod_version
if ($gradleProps -match "mod_version=(.+?)(\r?\n|$)") {
    $currentVersion = $Matches[1].Trim()
    $newVersion = Increment-ModVersion -CurrentVersion $currentVersion
    
    Write-Host "Version bump: $currentVersion -> $newVersion" -ForegroundColor Cyan
    
    # Update gradle.properties with new version
    $gradleProps = $gradleProps -replace "mod_version=.*", "mod_version=$newVersion"
    Set-Content -Path $gradlePropsPath -Value $gradleProps -NoNewline
    
    Write-Host "Updated mod_version in gradle.properties" -ForegroundColor Green
} else {
    Write-Host "Warning: Could not find mod_version in gradle.properties" -ForegroundColor Yellow
}

# Use isolated Gradle cache per Minecraft version
$gradleCacheDir = Join-Path $projectRoot ".gradle-$MinecraftVersion"
$env:GRADLE_USER_HOME = $gradleCacheDir
Write-Host ("Using isolated Gradle cache for {0}: {1}" -f $MinecraftVersion, $gradleCacheDir) -ForegroundColor Cyan

# Update gradle.properties for Minecraft version if needed
$needsUpdate = $false
$propsContent = Get-Content $gradlePropsPath
$updatedContent = @()

foreach ($line in $propsContent) {
    if ($line -match "^minecraft_version=") {
        if ($line -notmatch "minecraft_version=$MinecraftVersion") {
            $updatedContent += "minecraft_version=$MinecraftVersion"
            $needsUpdate = $true
        } else {
            $updatedContent += $line
        }
    } else {
        $updatedContent += $line
    }
}

if ($needsUpdate) {
    Set-Content -Path $gradlePropsPath -Value $updatedContent
    Write-Host "Updated gradle.properties for Minecraft $MinecraftVersion" -ForegroundColor Green
}

# Clean if requested
if ($Clean) {
    Write-Host "Cleaning build..." -ForegroundColor Yellow
    Push-Location $projectRoot
    .\gradlew.bat clean 2>&1 | Out-Host
    Pop-Location
}

# Build
Write-Host "Building mod for Minecraft $MinecraftVersion..." -ForegroundColor Cyan
Push-Location $projectRoot

try {
    $buildOutput = .\gradlew.bat build --no-daemon 2>&1 | Out-String
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build successful!" -ForegroundColor Green
        
        # Find the built JAR
        $jarPattern = "build\libs\basicstorage-*-$MinecraftVersion.jar"
        $jars = Get-ChildItem -Path (Join-Path $projectRoot "build\libs") -Filter "basicstorage-*-$MinecraftVersion.jar" -ErrorAction SilentlyContinue
        
        if ($jars) {
            $latestJar = $jars | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Write-Host "Built JAR: $($latestJar.Name)" -ForegroundColor Green
            
            if ($StartServer) {
                Write-Host "Starting server..." -ForegroundColor Cyan
                & (Join-Path $projectRoot "scripts\start-server.ps1") -MinecraftVersion $MinecraftVersion
            }
        }
    } else {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

