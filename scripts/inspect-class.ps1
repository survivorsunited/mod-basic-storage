param(
    [string[]]$Classes,
    [string]$ListPattern,
    [string]$JarPath,
    [string]$MinecraftVersion,
    [string[]]$JavapArgs,
    [switch]$Tail
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $Classes -and -not $ListPattern) {
    Write-Host "Specify -Classes or -ListPattern." -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logsDir = Join-Path $repoRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}
$logFile = Join-Path $logsDir ("inspect-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

function Resolve-JarPath {
    param(
        [string]$JarPath,
        [string]$MinecraftVersion,
        [string]$RepoRoot
    )

    if ($JarPath) {
        if (Test-Path $JarPath) {
            return (Resolve-Path $JarPath).Path
        }
        throw "Jar path $JarPath not found."
    }

    if (-not $MinecraftVersion) {
        $propLine = Select-String -Path (Join-Path $RepoRoot "gradle.properties") -Pattern "^\s*minecraft_version\s*=\s*(.+)$"
        if ($propLine) {
            $MinecraftVersion = $propLine.Matches[0].Groups[1].Value.Trim()
        }
    }

    if (-not $MinecraftVersion) {
        throw "Unable to determine Minecraft version."
    }

    $cacheDir = Join-Path $RepoRoot ".gradle-$MinecraftVersion\caches\fabric-loom\$MinecraftVersion"
    if (Test-Path $cacheDir) {
        $namedJar = Get-ChildItem -Path $cacheDir -Filter "*named*.jar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($namedJar) {
            return $namedJar.FullName
        }
    }

    $clientJar = Join-Path $cacheDir "minecraft-client.jar"
    if (Test-Path $clientJar) {
        return (Resolve-Path $clientJar).Path
    }

    $serverJar = Join-Path $cacheDir "minecraft-server.jar"
    if (Test-Path $serverJar) {
        return (Resolve-Path $serverJar).Path
    }

    throw "No Minecraft jar found for $MinecraftVersion."
}

function Get-ToolPath {
    param(
        [string]$Executable
    )

    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME "bin\$Executable.exe"
        if (Test-Path $candidate) {
            return $candidate
        }
        $candidate = Join-Path $env:JAVA_HOME "bin\$Executable"
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $cmd = Get-Command $Executable -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    throw "$Executable not found in PATH or JAVA_HOME."
}

$resolvedJar = Resolve-JarPath -JarPath $JarPath -MinecraftVersion $MinecraftVersion -RepoRoot $repoRoot

"[$(Get-Date -Format o)] Inspecting jar: $resolvedJar" | Tee-Object -FilePath $logFile

if ($Classes) {
    $javap = Get-ToolPath -Executable "javap"
    foreach ($cls in $Classes) {
        "[$(Get-Date -Format o)] javap $cls" | Tee-Object -FilePath $logFile -Append
        try {
            $args = @("-classpath", $resolvedJar)
            if ($JavapArgs) {
                $args += $JavapArgs
            }
            $args += $cls
            & $javap @args 2>&1 | Tee-Object -FilePath $logFile -Append
        } catch {
            $errText = $_ | Out-String
            "Error inspecting ${cls}: $errText" | Tee-Object -FilePath $logFile -Append
        }
    }
}

if ($ListPattern) {
    $jarTool = Get-ToolPath -Executable "jar"
    "[$(Get-Date -Format o)] Listing entries matching $ListPattern" | Tee-Object -FilePath $logFile -Append
    try {
        & $jarTool "tf" $resolvedJar 2>&1 | Select-String -SimpleMatch $ListPattern | Tee-Object -FilePath $logFile -Append
    } catch {
        $errText = $_ | Out-String
        "Error listing entries: $errText" | Tee-Object -FilePath $logFile -Append
    }
}

Write-Host "Log written to $logFile" -ForegroundColor Green

if ($Tail) {
    Get-Content $logFile -Wait
}

