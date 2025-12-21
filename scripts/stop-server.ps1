# Stop Minecraft Server
# This script finds and stops ONLY the Minecraft server process started by gradlew runServer

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

Write-Host "Stopping Minecraft server..." -ForegroundColor Yellow

# First, try graceful shutdown via Gradle
Write-Host "Attempting graceful shutdown via Gradle..." -ForegroundColor Cyan
try {
    Push-Location $projectRoot
    .\gradlew.bat --stop 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Pop-Location
    Write-Host "Gradle stop command executed" -ForegroundColor Green
} catch {
    Pop-Location
    Write-Host "Gradle stop command failed (may not be needed)" -ForegroundColor Yellow
}

# Find Java processes and check their command lines to identify the server
$serverProcesses = @()

try {
    $javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
    
    foreach ($proc in $javaProcesses) {
        try {
            # Get command line arguments for this process
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue | 
                       Select-Object -ExpandProperty CommandLine)
            
            if ($cmdLine) {
                # Check if this is our Minecraft server process
                $isServer = ($cmdLine -like "*runServer*") -or 
                           ($cmdLine -like "*minecraft*server*") -or
                           ($cmdLine -like "*gradle*runServer*") -or
                           (($cmdLine -like "*gradle*") -and ($cmdLine -like "*server*"))
                
                # Also check working directory if available
                $procPath = $proc.Path
                if ($procPath -and $isServer) {
                    $serverProcesses += $proc
                    Write-Host "Found server process: PID $($proc.Id) - $($cmdLine.Substring(0, [Math]::Min(80, $cmdLine.Length)))..." -ForegroundColor Cyan
                }
            }
        } catch {
            # Skip processes we can't inspect
            continue
        }
    }
} catch {
    Write-Host "Error finding processes: $_" -ForegroundColor Red
}

if ($serverProcesses.Count -eq 0) {
    Write-Host "No Minecraft server process found (may already be stopped)" -ForegroundColor Green
    Write-Host "Done!" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($serverProcesses.Count) server process(es) to stop" -ForegroundColor Yellow

# Ask for confirmation if multiple processes found
if ($serverProcesses.Count -gt 1) {
    Write-Host "WARNING: Multiple processes found. Proceed? (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Stop each server process
foreach ($proc in $serverProcesses) {
    Write-Host "Stopping process ID $($proc.Id)..." -ForegroundColor Yellow
    try {
        # Try graceful shutdown first (sends close signal)
        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
            $proc.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 2
        }
        
        # If still running, force kill
        if (-not $proc.HasExited) {
            Write-Host "Force stopping process..." -ForegroundColor Red
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Start-Sleep -Milliseconds 500
        }
        
        Write-Host "Process $($proc.Id) stopped" -ForegroundColor Green
    } catch {
        Write-Host "Error stopping process $($proc.Id): $_" -ForegroundColor Red
    }
}

Write-Host "Done!" -ForegroundColor Green
