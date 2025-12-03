# Comprehensive Version Validation Script
# Builds, validates, and tests server startup for all Minecraft versions in versions.json
#
# Usage:
#   .\scripts\validate-all-versions.ps1                           # Validate all versions
#   .\scripts\validate-all-versions.ps1 -Versions "1.21.8"       # Validate specific versions
#   .\scripts\validate-all-versions.ps1 -SkipServer               # Build only, skip server tests
#   .\scripts\validate-all-versions.ps1 -SkipBuild                # Server tests only, skip builds
#   .\scripts\validate-all-versions.ps1 -CleanAll                 # Clean everything before building
#   .\scripts\validate-all-versions.ps1 -CleanBuild                # Clean build artifacts only
#   .\scripts\validate-all-versions.ps1 -CleanGradle              # Clean Gradle/Loom cache only
#
# Parameters:
#   -Versions          : Array of specific versions to validate (default: all from versions.json)
#   -SkipBuild         : Skip building, only validate existing JARs
#   -SkipServer        : Skip server startup tests
#   -CleanBuild        : Remove build/ directory before building
#   -CleanGradle       : Remove Gradle cache and Loom cache before building
#   -CleanAll          : Remove build artifacts, Gradle cache, and Loom cache (combines CleanBuild + CleanGradle)
#   -ServerTimeout     : Timeout in seconds for server startup (default: 120)

param(
    [switch]$SkipBuild,
    [switch]$SkipServer,
    [switch]$CleanBuild,
    [switch]$CleanGradle,
    [switch]$CleanAll,
    [int]$ServerTimeout = 120,
    [string[]]$Versions = @()
)

# Set the correct JDK 21 path (with fallback to system Java)
$jdkPath = "C:\data\apps\#dev\jdk\jdk-21.0.7"
if (Test-Path $jdkPath) {
    $env:JAVA_HOME = $jdkPath
    $env:Path = "$jdkPath\bin;" + $env:Path
    Write-Host "✅ JAVA_HOME set to $jdkPath" -ForegroundColor Green
} else {
    Write-Host "⚠️  JDK path not found: $jdkPath" -ForegroundColor Yellow
    Write-Host "   Using system Java. Ensure Java 21+ is installed." -ForegroundColor Yellow
    # Try to find JDK 21 or 22 in common locations
    $possiblePaths = @(
        "C:\Program Files\Java\jdk-21",
        "C:\Program Files\Java\jdk-22",
        "C:\Program Files\Eclipse Adoptium\jdk-21*",
        "C:\Program Files\Eclipse Adoptium\jdk-22*"
    )
    $foundJdk = $null
    foreach ($path in $possiblePaths) {
        $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
        if ($resolved) {
            $foundJdk = $resolved[0].Path
            $env:JAVA_HOME = $foundJdk
            $env:Path = "$foundJdk\bin;" + $env:Path
            Write-Host "✅ Using JDK from: $foundJdk" -ForegroundColor Green
            break
        }
    }
    if (-not $foundJdk) {
        Write-Host "⚠️  No JDK 21/22 found in common locations. Using system Java." -ForegroundColor Yellow
    }
}

Write-Host "🔍 Version Validation Script" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Show cleanup options if any are set
if ($CleanAll -or $CleanBuild -or $CleanGradle) {
    Write-Host "🧹 Cleanup Options:" -ForegroundColor Yellow
    if ($CleanAll) {
        Write-Host "   - CleanAll: Removing build artifacts, Gradle cache, and Loom cache" -ForegroundColor Gray
    } else {
        if ($CleanBuild) {
            Write-Host "   - CleanBuild: Removing build artifacts" -ForegroundColor Gray
        }
        if ($CleanGradle) {
            Write-Host "   - CleanGradle: Removing Gradle and Loom cache" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Load versions.json
$versionsJson = Get-Content "versions.json" | ConvertFrom-Json
$allVersions = if ($Versions.Count -gt 0) { $Versions } else { $versionsJson.PSObject.Properties.Name | Sort-Object }

Write-Host "📋 Versions to validate: $($allVersions -join ', ')" -ForegroundColor Yellow
Write-Host ""

# Results tracking
$results = @{}
$failedVersions = @()
$passedVersions = @()

foreach ($mcVersion in $allVersions) {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "🔨 Processing Minecraft $mcVersion" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    $versionResult = @{
        Version = $mcVersion
        BuildSuccess = $false
        JARExists = $false
        JARValid = $false
        ServerStarted = $false
        ModLoaded = $false
        ErrorsFound = $false
        ErrorMessages = @()
    }
    
    # Step 1: Update gradle.properties
    Write-Host "📝 Updating gradle.properties for $mcVersion..." -ForegroundColor Cyan
    $versionConfig = $versionsJson.$mcVersion
    if (-not $versionConfig) {
        $versionResult.ErrorMessages += "Version $mcVersion not found in versions.json"
        $results[$mcVersion] = $versionResult
        $failedVersions += $mcVersion
        continue
    }
    
    $gradleProps = Get-Content "gradle.properties" -Raw
    $gradleProps = $gradleProps -replace "minecraft_version\s*=\s*[^\r\n]*", "minecraft_version=$mcVersion"
    $gradleProps = $gradleProps -replace "yarn_mappings\s*=\s*[^\r\n]*", "yarn_mappings=$($versionConfig.yarn_mappings)"
    $gradleProps = $gradleProps -replace "loader_version\s*=\s*[^\r\n]*", "loader_version=$($versionConfig.loader_version)"
    $gradleProps = $gradleProps -replace "fabric_loader_version\s*=\s*[^\r\n]*", "fabric_loader_version=$($versionConfig.loader_version)"
    $gradleProps = $gradleProps -replace "loom_version\s*=\s*[^\r\n]*", "loom_version=$($versionConfig.loom_version)"
    $gradleProps = $gradleProps -replace "fabric_version\s*=\s*[^\r\n]*", "fabric_version=$($versionConfig.fabric_version)"
    $gradleProps | Set-Content "gradle.properties" -NoNewline
    Write-Host "✅ gradle.properties updated" -ForegroundColor Green
    
    # Step 2: Build the mod
    if (-not $SkipBuild) {
        Write-Host "🔨 Building mod for $mcVersion..." -ForegroundColor Cyan
        
        # Use version-specific Gradle cache
        $gradleUserHome = "$PWD\.gradle-$mcVersion"
        $env:GRADLE_USER_HOME = $gradleUserHome
        
        # Cleanup based on flags
        if ($CleanAll -or $CleanGradle) {
            Write-Host "🧹 Stopping Gradle daemon..." -ForegroundColor Cyan
            & ./gradlew --stop 2>&1 | Out-Null
            Start-Sleep -Seconds 2
            
            Write-Host "🧹 Removing version-specific Gradle cache: $gradleUserHome" -ForegroundColor Cyan
            if (Test-Path $gradleUserHome) {
                Remove-Item -Path $gradleUserHome -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        if ($CleanAll -or $CleanBuild) {
            Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Cyan
            Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
            # Also clean any Loom cache in build directory
            Remove-Item -Path "build/loom-cache" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        if ($CleanAll -or $CleanGradle) {
            Write-Host "🧹 Cleaning Loom cache..." -ForegroundColor Cyan
            # Clean all possible Loom cache locations
            Remove-Item -Path ".gradle/loom-cache" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "build/loom-cache" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path ".fabric" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path ".loom" -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $gradleUserHome) {
                Remove-Item -Path "$gradleUserHome/loom-cache" -Recurse -Force -ErrorAction SilentlyContinue
                # Clean transforms cache that might have Loom data
                Get-ChildItem -Path "$gradleUserHome/caches" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    Remove-Item -Path "$($_.FullName)/transforms" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        # Clean and build
        Write-Host "Running: ./gradlew clean build --no-daemon" -ForegroundColor Gray
        $buildOutput = & ./gradlew clean build --no-daemon 2>&1 | Tee-Object -Variable buildOutputFull
        $buildExitCode = $LASTEXITCODE
        
        if ($buildExitCode -ne 0) {
            Write-Host "Build output (last 20 lines):" -ForegroundColor Yellow
            $buildOutput | Select-Object -Last 20 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
            
            $versionResult.ErrorMessages += "Build failed with exit code $buildExitCode"
            $versionResult.ErrorMessages += "Last 20 build output lines:"
            $versionResult.ErrorMessages += ($buildOutput | Select-Object -Last 20)
            
            # Try to find the actual error
            $errorLines = $buildOutput | Select-String -Pattern "error|ERROR|FAILURE|failed|Exception" -CaseSensitive:$false
            if ($errorLines) {
                $versionResult.ErrorMessages += "Error lines found:"
                $versionResult.ErrorMessages += ($errorLines | Select-Object -First 5)
            }
            
            $results[$mcVersion] = $versionResult
            $failedVersions += $mcVersion
            Write-Host "❌ Build failed for ${mcVersion}" -ForegroundColor Red
            continue
        }
        
        $versionResult.BuildSuccess = $true
        Write-Host "✅ Build successful" -ForegroundColor Green
    } else {
        Write-Host "⏭️  Skipping build (SkipBuild flag set)" -ForegroundColor Yellow
        $versionResult.BuildSuccess = $true
    }
    
    # Step 3: Validate JAR exists and content
    Write-Host "📦 Validating JAR file..." -ForegroundColor Cyan
    $modJars = Get-ChildItem -Path "build/libs" -Filter "*.jar" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*-sources.jar" }
    
    if ($modJars.Count -eq 0) {
        $versionResult.ErrorMessages += "No mod JAR found in build/libs"
        $results[$mcVersion] = $versionResult
        $failedVersions += $mcVersion
        Write-Host "❌ No JAR file found" -ForegroundColor Red
        continue
    }
    
    $modJar = $modJars[0]
    $versionResult.JARExists = $true
    Write-Host "✅ JAR found: $($modJar.Name) ($([math]::Round($modJar.Length / 1MB, 2)) MB)" -ForegroundColor Green
    
    # Validate JAR content (check if it's a valid ZIP/JAR)
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($modJar.FullName)
        $entries = $zip.Entries.Count
        $zip.Dispose()
        
        if ($entries -gt 0) {
            $versionResult.JARValid = $true
            Write-Host "✅ JAR is valid (contains $entries entries)" -ForegroundColor Green
            
            # Check for fabric.mod.json in JAR
            $zip = [System.IO.Compression.ZipFile]::OpenRead($modJar.FullName)
            $fabricModJson = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" }
            if ($fabricModJson) {
                Write-Host "✅ fabric.mod.json found in JAR" -ForegroundColor Green
            } else {
                $versionResult.ErrorMessages += "fabric.mod.json not found in JAR"
                Write-Host "⚠️  fabric.mod.json not found in JAR" -ForegroundColor Yellow
            }
            $zip.Dispose()
        } else {
            $versionResult.ErrorMessages += "JAR appears to be empty"
            Write-Host "⚠️  JAR appears to be empty" -ForegroundColor Yellow
        }
    } catch {
        $versionResult.ErrorMessages += "Failed to validate JAR: $($_.Exception.Message)"
        Write-Host "⚠️  JAR validation error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Step 4: Start server and validate logs
    if (-not $SkipServer) {
        Write-Host "🚀 Starting test server for $mcVersion..." -ForegroundColor Cyan
        
        # Create version-specific test server directory to keep all files and caches isolated
        $testServerDir = "test-server-$mcVersion"
        if (-not (Test-Path $testServerDir)) {
            New-Item -ItemType Directory -Path $testServerDir | Out-Null
        }
        
        # Get absolute path to ensure proper isolation
        $testServerDir = (Resolve-Path $testServerDir).Path
        Write-Host "📁 Using isolated server directory: $testServerDir" -ForegroundColor Gray
        
        Push-Location $testServerDir
        
        try {
            # Download server and dependencies (reuse logic from build.ps1)
            $serverJar = "server-$mcVersion.jar"
            $fabricServerJar = "fabric-server-launch.jar"
            $modsDir = "mods"
            
            if (-not (Test-Path $modsDir)) {
                New-Item -ItemType Directory -Path $modsDir | Out-Null
            }
            
            # Download Minecraft server if needed
            if (-not (Test-Path $serverJar)) {
                $serverUrl = @{
                    "1.21.5" = "https://piston-data.mojang.com/v1/objects/6e64dcabba3c01a7271b4fa6bd898483b794c59b/server.jar"
                    "1.21.6" = "https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar"
                    "1.21.7" = "https://piston-data.mojang.com/v1/objects/05e4b48fbc01f0385adb74bcff9751d34552486c/server.jar"
                    "1.21.8" = "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
                    "1.21.9" = "https://piston-data.mojang.com/v1/objects/11e54c2081420a4d49db3007e66c80a22579ff2a/server.jar"
                    "1.21.10" = "https://piston-data.mojang.com/v1/objects/95495a7f485eedd84ce928cef5e223b757d2f764/server.jar"
                }[$mcVersion]
                
                Write-Host "📥 Downloading Minecraft server..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $serverUrl -OutFile $serverJar
            }
            
            # Download Fabric loader if needed
            if (-not (Test-Path $fabricServerJar)) {
                $loaderUrl = @{
                    "1.21.5" = "https://meta.fabricmc.net/v2/versions/loader/1.21.5/0.16.14/1.0.3/server/jar"
                    "1.21.6" = "https://meta.fabricmc.net/v2/versions/loader/1.21.6/0.16.14/1.0.3/server/jar"
                    "1.21.7" = "https://meta.fabricmc.net/v2/versions/loader/1.21.7/0.17.3/1.1.0/server/jar"
                    "1.21.8" = "https://meta.fabricmc.net/v2/versions/loader/1.21.8/0.17.3/1.1.0/server/jar"
                    "1.21.9" = "https://meta.fabricmc.net/v2/versions/loader/1.21.9/0.17.3/1.1.0/server/jar"
                    "1.21.10" = "https://meta.fabricmc.net/v2/versions/loader/1.21.10/0.17.3/1.1.0/server/jar"
                }[$mcVersion]
                
                Write-Host "📥 Downloading Fabric loader..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $loaderUrl -OutFile $fabricServerJar
            }
            
            # Download Fabric API if needed
            $fabricApiFile = Get-ChildItem -Path $modsDir -Filter "fabric-api*.jar" -ErrorAction SilentlyContinue
            if (-not $fabricApiFile) {
                $fabricApiUrl = @{
                    "1.21.5" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/vNBWcMLP/fabric-api-0.127.1%2B1.21.5.jar"
                    "1.21.6" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/F5TVHWcE/fabric-api-0.128.2%2B1.21.6.jar"
                    "1.21.7" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/JntuF9Ul/fabric-api-0.129.0%2B1.21.7.jar"
                    "1.21.8" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/g58ofrov/fabric-api-0.136.1%2B1.21.8.jar"
                    "1.21.9" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/iHrvVvaM/fabric-api-0.134.0%2B1.21.9.jar"
                    "1.21.10" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/dQ3p80zK/fabric-api-0.138.3%2B1.21.10.jar"
                }[$mcVersion]
                
                Write-Host "📥 Downloading Fabric API..." -ForegroundColor Yellow
                try {
                    Invoke-WebRequest -Uri $fabricApiUrl -OutFile "$modsDir/fabric-api.jar"
                    Write-Host "✅ Fabric API downloaded" -ForegroundColor Green
                } catch {
                    Write-Host "⚠️  Failed to download Fabric API: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # Download YACL if needed
            $yaclFile = Get-ChildItem -Path $modsDir -Filter "yet-another-config-lib*.jar" -ErrorAction SilentlyContinue
            if (-not $yaclFile) {
                $yaclVersionMap = @{
                    "1.21.5" = "3.8.0+1.21.5"
                    "1.21.6" = "3.8.0+1.21.6"
                    "1.21.7" = "3.8.0+1.21.6"
                    "1.21.8" = "3.8.0+1.21.6"
                    "1.21.9" = "3.8.0+1.21.9"
                    "1.21.10" = "3.8.0+1.21.9"
                }
                $yaclVersion = if ($yaclVersionMap.ContainsKey($mcVersion)) { $yaclVersionMap[$mcVersion] } else { "3.8.0+1.21.9" }
                
                Write-Host "📥 Downloading YACL $yaclVersion..." -ForegroundColor Yellow
                $yaclMavenUrl = "https://maven.isxander.dev/releases/dev/isxander/yet-another-config-lib/$yaclVersion-fabric/yet-another-config-lib-$yaclVersion-fabric.jar"
                try {
                    Invoke-WebRequest -Uri $yaclMavenUrl -OutFile "$modsDir/yet-another-config-lib-$yaclVersion-fabric.jar"
                    Write-Host "✅ YACL downloaded" -ForegroundColor Green
                } catch {
                    Write-Host "⚠️  Failed to download YACL: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # Copy mod JAR
            Copy-Item "../build/libs/$($modJar.Name)" -Destination "$modsDir/$($modJar.Name)" -Force
            
            # Accept EULA
            "eula=true" | Out-File -FilePath "eula.txt" -Encoding utf8 -Force
            
            # Create logs directory
            $logsDir = "logs"
            if (-not (Test-Path $logsDir)) {
                New-Item -ItemType Directory -Path $logsDir | Out-Null
            }
            
            # Start server and monitor logs
            # Minecraft server writes to logs/latest.log, but we'll also capture console output
            # All server files, caches, and world data will be contained in the version-specific directory
            $consoleLogFile = "server.log"
            $logFile = "logs/latest.log"
            $javaOpts = @("-Xms2G", "-Xmx4G", "-XX:+UseG1GC", "-XX:+ParallelRefProcEnabled", "-XX:MaxGCPauseMillis=200", "-XX:+UnlockExperimentalVMOptions", "-XX:+DisableExplicitGC", "--enable-native-access=ALL-UNNAMED")
            
            # Ensure Java runs in the version-specific directory to keep all caches isolated
            $javaCmd = "java " + ($javaOpts -join " ") + " -jar `"$fabricServerJar`" nogui"
            
            Write-Host "⏱️  Starting server (timeout: ${ServerTimeout}s)..." -ForegroundColor Yellow
            Write-Host "📄 Monitoring log: $logFile" -ForegroundColor Gray
            Write-Host "📁 All server files and caches isolated in: $testServerDir" -ForegroundColor Gray
            
            $job = Start-Job -ScriptBlock {
                param($cmd, $consoleLog, $workDir)
                # Set working directory to ensure all files are created in version-specific folder
                Set-Location $workDir
                Invoke-Expression "$cmd 2>&1 | Tee-Object -FilePath `"$consoleLog`""
            } -ArgumentList $javaCmd, $consoleLogFile, $testServerDir
            
            $elapsed = 0
            $serverStarted = $false
            $modLoaded = $false
            $errors = @()
            
            while ($elapsed -lt $ServerTimeout -and !$serverStarted) {
                Start-Sleep -Seconds 2
                $elapsed += 2
                
                # Check both log locations (server.log for console output, logs/latest.log for server logs)
                $logContent = @()
                if (Test-Path $logFile) {
                    $logContent += Get-Content $logFile -ErrorAction SilentlyContinue
                }
                if (Test-Path $consoleLogFile) {
                    $logContent += Get-Content $consoleLogFile -ErrorAction SilentlyContinue
                }
                $logContent = $logContent | Select-Object -Unique
                
                if ($logContent) {
                    # Check for server started
                    if ($logContent -match "Done \(\d+\.\d+s\)! For help, type") {
                        $serverStarted = $true
                        $versionResult.ServerStarted = $true
                        Write-Host "✅ Server started successfully!" -ForegroundColor Green
                    }
                    
                    # Check for mod loaded
                    if ($logContent -match "customportals" -or $logContent -match "Custom Portals") {
                        $modLoaded = $true
                        $versionResult.ModLoaded = $true
                        Write-Host "✅ Mod loaded successfully!" -ForegroundColor Green
                    }
                    
                    # Check for errors (but ignore known harmless warnings)
                    $errorPatterns = @(
                        "ERROR",
                        "FATAL",
                        "Exception",
                        "Failed to",
                        "Could not",
                        "Unable to"
                    )
                    
                    # Patterns to ignore (harmless warnings)
                    $ignorePatterns = @(
                        "WARN.*refmap.*could not be read.*development environment",
                        "WARN.*Reference map.*could not be read",
                        "WARN.*deprecated",
                        "DEBUG",
                        "TRACE"
                    )
                    
                    foreach ($pattern in $errorPatterns) {
                        $errorLines = $logContent | Select-String -Pattern $pattern -CaseSensitive:$false
                        if ($errorLines) {
                            foreach ($line in $errorLines) {
                                $shouldIgnore = $false
                                foreach ($ignorePattern in $ignorePatterns) {
                                    if ($line.Line -match $ignorePattern) {
                                        $shouldIgnore = $true
                                        break
                                    }
                                }
                                if (-not $shouldIgnore) {
                                    $errors += $line.Line
                                }
                            }
                        }
                    }
                }
                
                if ($elapsed % 10 -eq 0) {
                    Write-Host "⏱️  Waiting... ($elapsed/$ServerTimeout seconds)" -ForegroundColor Gray
                }
            }
            
            # Stop server
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -ErrorAction SilentlyContinue
            
            # Analyze final log (check both locations)
            $hasLogFile = (Test-Path $logFile) -or (Test-Path $consoleLogFile)
            if ($hasLogFile) {
                # Read from both log files if they exist
                $finalLogContent = @()
                if (Test-Path $logFile) {
                    $finalLogContent += Get-Content $logFile -ErrorAction SilentlyContinue
                }
                if (Test-Path $consoleLogFile) {
                    $finalLogContent += Get-Content $consoleLogFile -ErrorAction SilentlyContinue
                }
                $logContent = $finalLogContent | Select-Object -Unique
                # Final checks
                if (-not $serverStarted) {
                    $versionResult.ErrorMessages += "Server did not start within timeout period"
                }
                
                if (-not $modLoaded) {
                    $versionResult.ErrorMessages += "Mod was not detected in server logs"
                }
                
                # Filter out non-critical errors and known harmless warnings
                $criticalErrors = $errors | Where-Object {
                    $_ -notmatch "DEBUG" -and
                    $_ -notmatch "TRACE" -and
                    $_ -notmatch "WARN.*deprecated" -and
                    $_ -notmatch "WARN.*refmap.*could not be read" -and
                    $_ -notmatch "WARN.*Reference map.*could not be read" -and
                    $_ -notmatch "Using.*instead of" -and
                    $_ -notmatch "development environment.*ignore"
                }
                
                if ($criticalErrors.Count -gt 0) {
                    $versionResult.ErrorsFound = $true
                    $versionResult.ErrorMessages += "Critical errors found in log:"
                    $versionResult.ErrorMessages += ($criticalErrors | Select-Object -First 5)
                }
            }
            
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "⏭️  Skipping server test (SkipServer flag set)" -ForegroundColor Yellow
    }
    
    # Determine overall result
    $allChecks = @(
        $versionResult.BuildSuccess,
        $versionResult.JARExists,
        $versionResult.JARValid
    )
    
    if (-not $SkipServer) {
        $allChecks += $versionResult.ServerStarted
        $allChecks += $versionResult.ModLoaded
        $allChecks += (-not $versionResult.ErrorsFound)
    }
    
    if ($allChecks -notcontains $false) {
        $passedVersions += $mcVersion
        Write-Host "✅ ${mcVersion}: ALL CHECKS PASSED" -ForegroundColor Green
    } else {
        $failedVersions += $mcVersion
        Write-Host "❌ ${mcVersion}: SOME CHECKS FAILED" -ForegroundColor Red
    }
    
    $results[$mcVersion] = $versionResult
    Write-Host ""
}

# Final Summary
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "📊 VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

Write-Host "✅ Passed: $($passedVersions.Count) version(s)" -ForegroundColor Green
if ($passedVersions.Count -gt 0) {
    Write-Host "   $($passedVersions -join ', ')" -ForegroundColor Gray
}

Write-Host "❌ Failed: $($failedVersions.Count) version(s)" -ForegroundColor Red
if ($failedVersions.Count -gt 0) {
    Write-Host "   $($failedVersions -join ', ')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Detailed errors:" -ForegroundColor Yellow
    foreach ($version in $failedVersions) {
        Write-Host "  ${version}:" -ForegroundColor Red
        foreach ($errorMsg in $results[$version].ErrorMessages) {
            Write-Host "    - $errorMsg" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan

# Exit with appropriate code
if ($failedVersions.Count -gt 0) {
    exit 1
} else {
    exit 0
}
