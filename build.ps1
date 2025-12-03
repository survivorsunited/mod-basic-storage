# Minecraft Fabric Mod Build and Test Server Script
# Builds the mod and optionally starts a test server

param(
    [switch]$StartServer,
    [switch]$Clean,
    [string]$MinecraftVersion = "1.21.5"
)

# Set the correct JDK 21 path
$jdkPath = "C:\data\apps\#dev\jdk\jdk-21.0.7"
$env:JAVA_HOME = $jdkPath
$env:Path = "$jdkPath\bin;" + $env:Path

Write-Host "JAVA_HOME set to $jdkPath" -ForegroundColor Green

# Always clean Loom cache when switching versions to avoid conflicts
# Use version-specific Gradle user home to isolate caches
$gradleUserHome = "$PWD\.gradle-$MinecraftVersion"
$env:GRADLE_USER_HOME = $gradleUserHome
Write-Host "🧹 Using isolated Gradle cache for ${MinecraftVersion}: ${gradleUserHome}" -ForegroundColor Cyan
# Clean entire version-specific cache to avoid conflicts
Remove-Item -Path $gradleUserHome -Recurse -Force -ErrorAction SilentlyContinue
./gradlew --stop | Out-Null

# Update gradle.properties with correct Minecraft version BEFORE building
Write-Host "📝 Updating gradle.properties for Minecraft $MinecraftVersion..." -ForegroundColor Cyan
$versionsJson = Get-Content versions.json | ConvertFrom-Json
$versionConfig = $versionsJson.$MinecraftVersion

if (-not $versionConfig) {
    Write-Host "❌ Unknown Minecraft version: $MinecraftVersion" -ForegroundColor Red
    Write-Host "Supported versions: $($versionsJson.PSObject.Properties.Name -join ', ')" -ForegroundColor Yellow
    exit 1
}

# Read gradle.properties
$gradleProps = Get-Content gradle.properties -Raw

# Update Minecraft version and related properties
$gradleProps = $gradleProps -replace "minecraft_version\s*=\s*[^\r\n]*", "minecraft_version=$MinecraftVersion"
$gradleProps = $gradleProps -replace "yarn_mappings\s*=\s*[^\r\n]*", "yarn_mappings=$($versionConfig.yarn_mappings)"
$gradleProps = $gradleProps -replace "loader_version\s*=\s*[^\r\n]*", "loader_version=$($versionConfig.loader_version)"
$gradleProps = $gradleProps -replace "fabric_loader_version\s*=\s*[^\r\n]*", "fabric_loader_version=$($versionConfig.loader_version)"
$gradleProps = $gradleProps -replace "loom_version\s*=\s*[^\r\n]*", "loom_version=$($versionConfig.loom_version)"
$gradleProps = $gradleProps -replace "fabric_version\s*=\s*[^\r\n]*", "fabric_version=$($versionConfig.fabric_version)"

# Write back
$gradleProps | Set-Content gradle.properties -NoNewline
Write-Host "✅ Updated gradle.properties:" -ForegroundColor Green
Write-Host "   Minecraft: $MinecraftVersion" -ForegroundColor Gray
Write-Host "   Yarn: $($versionConfig.yarn_mappings)" -ForegroundColor Gray
Write-Host "   Loader: $($versionConfig.loader_version)" -ForegroundColor Gray
Write-Host "   Fabric: $($versionConfig.fabric_version)" -ForegroundColor Gray

# Clean build artifacts and Loom cache if requested (required when switching versions)
if ($Clean) {
    Write-Host "🧹 Cleaning build artifacts and Loom cache..." -ForegroundColor Cyan
    # Remove Loom cache and build directory to avoid version conflicts
    Remove-Item -Path ".gradle/loom-cache" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    ./gradlew clean --no-daemon
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Clean failed, continuing anyway..." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Clean successful!" -ForegroundColor Green
    }
    # Stop Gradle daemon to ensure clean state
    ./gradlew --stop
}

# Minecraft Server Download Map
$MinecraftServerDownloadMap = @{
    "1.21.5" = "https://piston-data.mojang.com/v1/objects/6e64dcabba3c01a7271b4fa6bd898483b794c59b/server.jar"
    "1.21.6" = "https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar"
    "1.21.7" = "https://piston-data.mojang.com/v1/objects/05e4b48fbc01f0385adb74bcff9751d34552486c/server.jar"
    "1.21.8" = "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
    "1.21.9" = "https://piston-data.mojang.com/v1/objects/11e54c2081420a4d49db3007e66c80a22579ff2a/server.jar"
    "1.21.10" = "https://piston-data.mojang.com/v1/objects/95495a7f485eedd84ce928cef5e223b757d2f764/server.jar"
}

# Fabric Loader Download Map
$FabricLoaderDownloadMap = @{
    "1.21.5" = "https://meta.fabricmc.net/v2/versions/loader/1.21.5/0.16.14/1.0.3/server/jar"
    "1.21.6" = "https://meta.fabricmc.net/v2/versions/loader/1.21.6/0.16.14/1.0.3/server/jar"
    "1.21.7" = "https://meta.fabricmc.net/v2/versions/loader/1.21.7/0.17.3/1.1.0/server/jar"
    "1.21.8" = "https://meta.fabricmc.net/v2/versions/loader/1.21.8/0.17.3/1.1.0/server/jar"
    "1.21.9" = "https://meta.fabricmc.net/v2/versions/loader/1.21.9/0.17.3/1.1.0/server/jar"
    "1.21.10" = "https://meta.fabricmc.net/v2/versions/loader/1.21.10/0.17.3/1.1.0/server/jar"
}

# Fabric API Download Map
$FabricApiDownloadMap = @{
    "1.21.5" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/vNBWcMLP/fabric-api-0.127.1%2B1.21.5.jar"
    "1.21.6" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/F5TVHWcE/fabric-api-0.128.2%2B1.21.6.jar"
    "1.21.7" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/JntuF9Ul/fabric-api-0.129.0%2B1.21.7.jar"
    "1.21.8" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/g58ofrov/fabric-api-0.136.1%2B1.21.8.jar"
    "1.21.9" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/iHrvVvaM/fabric-api-0.134.0%2B1.21.9.jar"
    "1.21.10" = "https://cdn.modrinth.com/data/P7dR8mSH/versions/dQ3p80zK/fabric-api-0.138.3%2B1.21.10.jar"
}

# Build the mod
Write-Host "🔨 Building mod for Minecraft $MinecraftVersion..." -ForegroundColor Cyan
./gradlew build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green

# Rename JAR to include Minecraft version (like pipeline does)
$modVersion = (Select-String -Path gradle.properties -Pattern "mod_version\s*=" | ForEach-Object { ($_.Line -replace ".*mod_version\s*=\s*", "").Trim() })
$jarName = (Select-String -Path gradle.properties -Pattern "jar_name\s*=" | ForEach-Object { ($_.Line -replace ".*jar_name\s*=\s*", "").Trim() })
if (-not $jarName) {
    $jarName = (Select-String -Path gradle.properties -Pattern "archives_base_name\s*=" | ForEach-Object { ($_.Line -replace ".*archives_base_name\s*=\s*", "").Trim() })
}

$originalJar = Get-ChildItem -Path "build/libs" -Filter "${jarName}-${modVersion}.jar" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*-sources.jar" -and $_.Name -notlike "*-dev.jar" } | Select-Object -First 1

if ($originalJar) {
    $versionedJar = "build/libs/${jarName}-${modVersion}-${MinecraftVersion}.jar"
    if (-not (Test-Path $versionedJar)) {
        Copy-Item $originalJar.FullName -Destination $versionedJar -Force
        Write-Host "📦 Created versioned JAR: $versionedJar" -ForegroundColor Green
    } else {
        Write-Host "📦 Versioned JAR already exists: $versionedJar" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Could not find JAR to rename: ${jarName}-${modVersion}.jar" -ForegroundColor Yellow
}

# Start server if requested
if ($StartServer) {
    Write-Host "🚀 Starting test server..." -ForegroundColor Cyan
    
    # Create server directory
    $serverDir = "test-server"
    if (-not (Test-Path $serverDir)) {
        New-Item -ItemType Directory -Path $serverDir | Out-Null
        Write-Host "📁 Created server directory: $serverDir" -ForegroundColor Green
    }
    
    Set-Location $serverDir
    
    # Download Minecraft server if not exists
    $minecraftServerJar = "server.jar"
    if (-not (Test-Path $minecraftServerJar)) {
        $serverUrl = $MinecraftServerDownloadMap[$MinecraftVersion]
        if ($serverUrl) {
            Write-Host "📥 Downloading Minecraft server $MinecraftVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $serverUrl -OutFile $minecraftServerJar
            Write-Host "✅ Minecraft server downloaded" -ForegroundColor Green
        } else {
            Write-Host "❌ Unknown Minecraft version: $MinecraftVersion" -ForegroundColor Red
            Set-Location ..
            exit 1
        }
    }
    
    # Download Fabric server launcher if not exists
    $fabricServerJar = "fabric-server-launch.jar"
    if (-not (Test-Path $fabricServerJar)) {
        $fabricUrl = $FabricLoaderDownloadMap[$MinecraftVersion]
        if ($fabricUrl) {
            Write-Host "📥 Downloading Fabric server launcher $MinecraftVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $fabricUrl -OutFile $fabricServerJar
            Write-Host "✅ Fabric server launcher downloaded" -ForegroundColor Green
        } else {
            Write-Host "❌ Unknown Fabric version for Minecraft: $MinecraftVersion" -ForegroundColor Red
            Set-Location ..
            exit 1
        }
    }
    
    # Create mods directory and copy built mod
    $modsDir = "mods"
    if (-not (Test-Path $modsDir)) {
        New-Item -ItemType Directory -Path $modsDir | Out-Null
        Write-Host "📁 Created mods directory: $modsDir" -ForegroundColor Green
    }

    # Download Fabric API if not exists
    $fabricApiJar = "fabric-api.jar"
    if (-not (Test-Path "$modsDir/$fabricApiJar")) {
        $fabricApiUrl = $FabricApiDownloadMap[$MinecraftVersion]
        if ($fabricApiUrl) {
            Write-Host "📥 Downloading Fabric API for $MinecraftVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $fabricApiUrl -OutFile "$modsDir/$fabricApiJar"
            Write-Host "✅ Fabric API downloaded" -ForegroundColor Green
        } else {
            Write-Host "❌ Unknown Fabric API version for Minecraft: $MinecraftVersion" -ForegroundColor Red
            Set-Location ..
            exit 1
        }
    } else {
        Write-Host "✅ Fabric API already exists in mods directory" -ForegroundColor Green
    }
    
    # Download YACL (Yet Another Config Lib) if not exists
    # Map YACL versions to Minecraft versions
    # Based on available Maven versions: 3.8.0+1.21.1, 1.21.3, 1.21.4, 1.21.5, 1.21.6, 1.21.9
    $yaclVersionMap = @{
        "1.21.5" = "3.8.0+1.21.5"
        "1.21.6" = "3.8.0+1.21.6"
        "1.21.7" = "3.8.0+1.21.6"  # Use 1.21.6 version (closest available)
        "1.21.8" = "3.8.0+1.21.6"  # Use 1.21.6 version (closest available)
        "1.21.9" = "3.8.0+1.21.9"
        "1.21.10" = "3.8.0+1.21.9"  # Use 1.21.9 version (closest available)
    }
    $yaclVersion = if ($yaclVersionMap.ContainsKey($MinecraftVersion)) { $yaclVersionMap[$MinecraftVersion] } else { "3.8.0+1.21.9" }
    
    $yaclFile = Get-ChildItem -Path $modsDir -Filter "yet-another-config-lib*.jar" -ErrorAction SilentlyContinue
    if (-not $yaclFile) {
        Write-Host "📥 Downloading YACL (Yet Another Config Lib) $yaclVersion for MC $MinecraftVersion..." -ForegroundColor Yellow
        # Download from Maven repository (same as Gradle uses)
        $yaclMavenUrl = "https://maven.isxander.dev/releases/dev/isxander/yet-another-config-lib/$yaclVersion-fabric/yet-another-config-lib-$yaclVersion-fabric.jar"
        try {
            Invoke-WebRequest -Uri $yaclMavenUrl -OutFile "$modsDir/yet-another-config-lib-$yaclVersion-fabric.jar"
            Write-Host "✅ YACL downloaded" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Failed to download YACL from Maven. Trying Modrinth..." -ForegroundColor Yellow
            # Fallback: try Modrinth CDN
            try {
                $yaclModrinthUrl = "https://cdn.modrinth.com/data/yacl/versions/$yaclVersion/yacl-$yaclVersion.jar"
                Invoke-WebRequest -Uri $yaclModrinthUrl -OutFile "$modsDir/yacl-$yaclVersion.jar"
                Write-Host "✅ YACL downloaded from Modrinth" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to download YACL automatically. Please download manually:" -ForegroundColor Red
                Write-Host "   Maven: $yaclMavenUrl" -ForegroundColor Cyan
                Write-Host "   Or from: https://modrinth.com/mod/yacl" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "✅ YACL already exists in mods directory" -ForegroundColor Green
    }
    
    # Find and copy the built mod JAR
    $modJars = Get-ChildItem -Path "../build/libs" -Filter "*.jar" | Where-Object { $_.Name -notlike "*-sources.jar" }
    if ($modJars.Count -gt 0) {
        $modJar = $modJars[0]
        Copy-Item $modJar.FullName -Destination "$modsDir/$($modJar.Name)" -Force
        Write-Host "📦 Copied mod JAR: $($modJar.Name)" -ForegroundColor Green
    } else {
        Write-Host "❌ No mod JAR found in build/libs" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
    
    # Accept EULA if not exists
    if (-not (Test-Path "eula.txt")) {
        "eula=true" | Out-File -FilePath "eula.txt" -Encoding utf8
        Write-Host "✅ Accepted EULA" -ForegroundColor Green
    }
    
    # Create server properties with basic config
    if (-not (Test-Path "server.properties")) {
        @"
server-port=25565
gamemode=creative
difficulty=easy
spawn-protection=0
online-mode=false
enable-command-block=true
"@ | Out-File -FilePath "server.properties" -Encoding utf8
        Write-Host "✅ Created server.properties" -ForegroundColor Green
    }
    
    # Start the server
    Write-Host "🚀 Starting Fabric server..." -ForegroundColor Green
    Write-Host "Server will automatically stop after successful startup" -ForegroundColor Yellow
    
    $javaOpts = @(
        "-Xms2G"
        "-Xmx4G"
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "--enable-native-access=ALL-UNNAMED"
    )
    
    $logFile = "server.log"
    $javaCmd = "java " + ($javaOpts -join " ") + " -jar `"$fabricServerJar`" nogui"
    
    try {
        # Start server in background and tee output to log file
        $job = Start-Job -ScriptBlock {
            param($cmd, $log)
            Invoke-Expression "$cmd 2>&1 | Tee-Object -FilePath `"$log`""
        } -ArgumentList $javaCmd, $logFile
        
        Write-Host "📄 Monitoring server log: $logFile" -ForegroundColor Cyan
        
        # Monitor log file for startup completion and show output
        $timeout = 120 # 2 minutes
        $elapsed = 0
        $serverStarted = $false
        $lastLineCount = 0
        
        while ($elapsed -lt $timeout -and !$serverStarted) {
            Start-Sleep -Seconds 1
            $elapsed++
            
            if (Test-Path $logFile) {
                try {
                    # Read all lines and show only new ones
                    $allLines = Get-Content $logFile -ErrorAction SilentlyContinue
                    if ($allLines -and $allLines.Count -gt $lastLineCount) {
                        # Show new lines
                        for ($i = $lastLineCount; $i -lt $allLines.Count; $i++) {
                            Write-Host $allLines[$i]
                            
                            # Check this line for completion
                            if ($allLines[$i] -match "Done \(\d+\.\d+s\)! For help, type") {
                                Write-Host "✅ Server started successfully! Stopping server..." -ForegroundColor Green
                                $serverStarted = $true
                                
                                # Force stop the job
                                Stop-Job $job -PassThru | Remove-Job
                                break
                            }
                        }
                        $lastLineCount = $allLines.Count
                    }
                } catch {
                    # File might be locked, just wait and try again
                    Start-Sleep -Milliseconds 100
                }
            } else {
                # Show progress when no log file yet
                if ($elapsed % 5 -eq 0) {
                    Write-Host "⏱️ Waiting for server to start logging... ($elapsed/$timeout seconds)" -ForegroundColor Yellow
                }
            }
        }
        
        if (!$serverStarted) {
            Write-Host "⚠️ Server startup timeout reached, stopping..." -ForegroundColor Yellow
            Stop-Job $job -PassThru | Remove-Job
        }
        
        # Display last few lines of log
        if (Test-Path $logFile) {
            Write-Host "`n📋 Last few log lines:" -ForegroundColor Cyan
            Get-Content $logFile -Tail 3
        }
        
    } finally {
        # Clean up
        if ($job) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -ErrorAction SilentlyContinue
        }
        Remove-Item "stop_command.txt" -ErrorAction SilentlyContinue
        Set-Location ..
        Write-Host "`n🛑 Server stopped" -ForegroundColor Yellow
    }
} 