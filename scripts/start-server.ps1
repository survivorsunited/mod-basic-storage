# Minecraft Fabric Server Startup Script
# Automatically finds and launches the Fabric server JAR file

# Detect available memory and set appropriate JVM options
$totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$maxMemory = [math]::Min([math]::Max(4, [math]::Floor($totalMemory * 0.5)), 16)  # Between 4GB and 16GB
$minMemory = [math]::Max(2, [math]::Floor($maxMemory * 0.5))  # Half of max, minimum 2GB

Write-Host "💾 System memory: $([math]::Round($totalMemory, 1)) GB" -ForegroundColor Cyan
Write-Host "📊 Allocated memory: ${minMemory}G - ${maxMemory}G" -ForegroundColor Cyan

$JavaOpts = @(
  "-server"
  "-XX:+UseG1GC"
  "-XX:+ParallelRefProcEnabled"
  "-XX:MaxGCPauseMillis=200"
  "-XX:+UnlockExperimentalVMOptions"
  "-XX:+DisableExplicitGC"
  "-Xms${minMemory}G"
  "-Xmx${maxMemory}G"
  "--enable-native-access=ALL-UNNAMED"
)

# Set the correct JDK 21 path
$jdkPath = "C:\data\apps\#dev\jdk\jdk-21.0.7"
if (Test-Path $jdkPath) {
    $env:JAVA_HOME = $jdkPath
    $env:Path = "$jdkPath\bin;" + $env:Path
    Write-Host "✅ JAVA_HOME set to $jdkPath" -ForegroundColor Green
} else {
    Write-Host "⚠️  JDK path not found: $jdkPath" -ForegroundColor Yellow
    Write-Host "   Using system Java. Ensure Java 21 is installed." -ForegroundColor Yellow
}

# Minecraft Server Version Download Map
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

$LogDir = "logs"

# Function to find Fabric server JAR
function Find-FabricServerJar {
    $fabricJars = Get-ChildItem -Path "." -Filter "fabric-server*.jar" -ErrorAction SilentlyContinue
    
    if ($fabricJars.Count -eq 0) {
        Write-Host "❌ No Fabric server JAR found in current directory" -ForegroundColor Red
        Write-Host "Expected pattern: fabric-server*.jar" -ForegroundColor Yellow
        Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
        return $null
    }
    
    if ($fabricJars.Count -gt 1) {
        Write-Host "⚠️  Multiple Fabric server JARs found:" -ForegroundColor Yellow
        $fabricJars | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
        Write-Host "Using the first one: $($fabricJars[0].Name)" -ForegroundColor Yellow
    }
    
    $selectedJar = $fabricJars[0]
    Write-Host "✅ Found Fabric server JAR: $($selectedJar.Name)" -ForegroundColor Green
    return $selectedJar.Name
}

# Ensure logs folder exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
    Write-Host "📁 Created logs directory: $LogDir" -ForegroundColor Green
}

# Find the Fabric server JAR
$JarFile = Find-FabricServerJar
if (-not $JarFile) {
    Write-Host "`n💡 Make sure you have downloaded the Fabric server using ModManager.ps1" -ForegroundColor Cyan
    Write-Host "Example: .\ModManager.ps1 -AddMod -AddModName 'Fabric Server' -AddModType 'launcher' -AddModUrl '...'" -ForegroundColor Cyan
    exit 1
}

Write-Host "🚀 Starting Fabric server with JAR: $JarFile" -ForegroundColor Green
Write-Host "📊 Java options: $($JavaOpts.Count) options configured" -ForegroundColor Gray

while ($true) {
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $LogFile = "$LogDir/console-$Timestamp.log"
    $LaunchCmd = "java " + ($JavaOpts -join " ") + " -jar `"$JarFile`" nogui"

    # Write header to log file
    @"
=== Fabric Server Start: $Timestamp ===
=== JAR File: $JarFile ===
=== Launch Command: $LaunchCmd ===
=== Java Options: $($JavaOpts -join ' ') ===
=== Log File: $LogFile ===

"@ | Out-File -FilePath $LogFile -Encoding utf8

    Write-Host "`n🔄 Starting server... (Log: $LogFile)" -ForegroundColor Cyan
    
    # Set console encoding for proper character handling
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Run the server command and capture ALL output (stdout and stderr) to both console and log file
    $result = pwsh -NoProfile -Command @"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
& $LaunchCmd 2>&1 | Tee-Object -FilePath '$LogFile' -Append
"@
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 1) {
        # Read the log file to extract error information
        $logContent = Get-Content -Path $LogFile -Raw -ErrorAction SilentlyContinue
        
        # Look for the solution message
        $solutionPattern = "A potential solution has been determined, this may resolve your problem:(.*?)--- Server exited with code"
        $solutionMatch = [regex]::Match($logContent, $solutionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        $terminateMsg = "`n--- Server exited with code $exitCode. Terminating due to error exit code. ---`n"
        Write-Host $terminateMsg -ForegroundColor Red
        $terminateMsg | Out-File -FilePath $LogFile -Encoding utf8 -Append
        
        if ($solutionMatch.Success) {
            $solutionText = $solutionMatch.Groups[1].Value.Trim()
            Write-Host "❌ SERVER ERROR DETECTED:" -ForegroundColor Red
            Write-Host "🔍 Potential Solution:" -ForegroundColor Yellow
            Write-Host $solutionText -ForegroundColor White
            Write-Host ""
            Write-Host "💡 This typically indicates that server mods are not compatible with the current version." -ForegroundColor Cyan
            Write-Host "   Check your mod versions and ensure they support the target Minecraft version." -ForegroundColor Cyan
        } else {
            Write-Host "❌ Server terminated due to exit code 1. Check logs for details." -ForegroundColor Red
        }
        
        exit 1
    } else {
        $restartMsg = "`n--- Server exited with code $exitCode. Restarting in 10 seconds... ---`n"
        Write-Host $restartMsg -ForegroundColor Yellow
        $restartMsg | Out-File -FilePath $LogFile -Encoding utf8 -Append
        Start-Sleep -Seconds 10
    }
}
