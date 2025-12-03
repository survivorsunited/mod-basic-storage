# Generate Web Icons from Minecraft Mod Icon
# Automatically handles all dependencies and runs the appropriate converter

param(
    [string]$SourceIcon = "src/main/resources/assets/icon.png",
    [string]$OutputDir = "docs/static/img",
    [switch]$Force,
    [switch]$UseImageMagick,
    [switch]$Help
)

# Show help
if ($Help) {
    Write-Host @"
Generate Web Icons from Minecraft Mod Icon

Usage: .\scripts\generate-web-icons.ps1 [options]

Options:
  -Force           Overwrite existing icons
  -UseImageMagick  Force use of ImageMagick instead of Node.js
  -Help            Show this help message

By default, uses Node.js with sharp for better cross-platform compatibility.
Will automatically install dependencies as needed.

Source: $SourceIcon
Output: $OutputDir
"@
    exit 0
}

# Function to check if command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Function to install Node.js via winget
function Install-NodeJS {
    Write-Host "📦 Node.js not found. Installing via winget..." -ForegroundColor Yellow
    
    # Check if winget is available
    if (-not (Test-CommandExists "winget")) {
        Write-Host "❌ winget not found. Please install Node.js manually from https://nodejs.org" -ForegroundColor Red
        return $false
    }
    
    try {
        winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Test-CommandExists "node") {
            Write-Host "✅ Node.js installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Node.js installation failed. Please install manually from https://nodejs.org" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Failed to install Node.js: $_" -ForegroundColor Red
        return $false
    }
}

# Function to install ImageMagick via winget
function Install-ImageMagick {
    Write-Host "📦 ImageMagick not found. Installing via winget..." -ForegroundColor Yellow
    
    if (-not (Test-CommandExists "winget")) {
        Write-Host "❌ winget not found. Please install ImageMagick manually from https://imagemagick.org" -ForegroundColor Red
        return $false
    }
    
    try {
        winget install ImageMagick.ImageMagick --silent --accept-package-agreements --accept-source-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Test-CommandExists "magick") {
            Write-Host "✅ ImageMagick installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ ImageMagick installation failed. Please install manually from https://imagemagick.org" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Failed to install ImageMagick: $_" -ForegroundColor Red
        return $false
    }
}

# Function to run Node.js version
function Invoke-NodeIconGenerator {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $nodeScript = Join-Path $scriptDir "generate-web-icons.js"
    
    # Check if Node.js is installed
    if (-not (Test-CommandExists "node")) {
        if (-not (Install-NodeJS)) {
            return $false
        }
    }
    
    # Check if npm dependencies are installed
    $packageJson = Join-Path $scriptDir "package.json"
    $nodeModules = Join-Path $scriptDir "node_modules"
    
    if (-not (Test-Path $nodeModules)) {
        Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow
        Push-Location $scriptDir
        try {
            npm install --silent
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ Failed to install npm dependencies" -ForegroundColor Red
                return $false
            }
            Write-Host "✅ Dependencies installed" -ForegroundColor Green
        } finally {
            Pop-Location
        }
    }
    
    # Run the Node.js script
    Write-Host "🚀 Running Node.js icon generator..." -ForegroundColor Cyan
    $args = @()
    if ($Force) { $args += "--force" }
    
    & node $nodeScript $args
    return $LASTEXITCODE -eq 0
}

# Function to run ImageMagick version
function Invoke-ImageMagickGenerator {
    # Check if ImageMagick is installed
    if (-not (Test-CommandExists "magick")) {
        if (-not (Install-ImageMagick)) {
            return $false
        }
    }
    
    # Check if source icon exists
    if (-not (Test-Path $SourceIcon)) {
        Write-Host "❌ Source icon not found: $SourceIcon" -ForegroundColor Red
        return $false
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Host "📁 Created output directory: $OutputDir" -ForegroundColor Green
    }
    
    Write-Host "🚀 Running ImageMagick icon generator..." -ForegroundColor Cyan
    
    # Define icon sizes
    $iconSizes = @(
        @{ Size = 16; Name = "favicon-16x16.png" }
        @{ Size = 32; Name = "favicon-32x32.png" }
        @{ Size = 48; Name = "favicon-48x48.png" }
        @{ Size = 64; Name = "favicon-64x64.png" }
        @{ Size = 180; Name = "apple-touch-icon.png" }
        @{ Size = 192; Name = "android-chrome-192x192.png" }
        @{ Size = 512; Name = "android-chrome-512x512.png" }
        @{ Size = 1200; Name = "og-image.png" }
    )
    
    # Generate each icon
    foreach ($icon in $iconSizes) {
        $outputPath = Join-Path $OutputDir $icon.Name
        
        if ((Test-Path $outputPath) -and -not $Force) {
            Write-Host "⏭️  Skipping $($icon.Name) - already exists" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "📐 Creating $($icon.Name) ($($icon.Size)x$($icon.Size))" -ForegroundColor Gray
        
        & magick "$SourceIcon" -resize "$($icon.Size)x$($icon.Size)" -background none -gravity center -extent "$($icon.Size)x$($icon.Size)" "$outputPath" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Created $($icon.Name)" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create $($icon.Name)" -ForegroundColor Red
        }
    }
    
    # Generate ICO file
    $icoPath = Join-Path $OutputDir "favicon.ico"
    if ((Test-Path $icoPath) -and -not $Force) {
        Write-Host "⏭️  Skipping favicon.ico - already exists" -ForegroundColor Yellow
    } else {
        Write-Host "🔧 Creating favicon.ico" -ForegroundColor Gray
        $icoSizes = @(16, 24, 32, 48, 64, 128, 256)
        $tempFiles = @()
        
        foreach ($size in $icoSizes) {
            $tempFile = Join-Path $env:TEMP "favicon_${size}.png"
            $tempFiles += $tempFile
            & magick "$SourceIcon" -resize "${size}x${size}" -background none -gravity center -extent "${size}x${size}" "$tempFile" 2>$null
        }
        
        & magick $tempFiles "$icoPath" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Created favicon.ico" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create favicon.ico" -ForegroundColor Red
        }
        
        # Clean up temp files
        $tempFiles | ForEach-Object { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
    }
    
    # Copy main icon
    $mainIconPath = Join-Path $OutputDir "icon.png"
    if ((Test-Path $mainIconPath) -and -not $Force) {
        Write-Host "⏭️  Skipping icon.png - already exists" -ForegroundColor Yellow
    } else {
        Copy-Item $SourceIcon $mainIconPath -Force
        Write-Host "✅ Copied original icon.png" -ForegroundColor Green
    }
    
    # Generate site.webmanifest
    $manifestPath = Join-Path (Split-Path $OutputDir) "site.webmanifest"
    $manifest = @{
        name = "Compostables Mod Documentation"
        short_name = "Compostables"
        icons = @(
            @{
                src = "/img/android-chrome-192x192.png"
                sizes = "192x192"
                type = "image/png"
            },
            @{
                src = "/img/android-chrome-512x512.png"
                sizes = "512x512"
                type = "image/png"
            }
        )
        theme_color = "#4a7c59"
        background_color = "#ffffff"
        display = "standalone"
    } | ConvertTo-Json -Depth 10
    
    $manifest | Out-File -FilePath $manifestPath -Encoding utf8
    Write-Host "✅ Created site.webmanifest" -ForegroundColor Green
    
    return $true
}

# Main execution
Write-Host "🎨 Web Icon Generator for Compostables Mod" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Decide which method to use
if ($UseImageMagick) {
    Write-Host "Using ImageMagick (forced by -UseImageMagick flag)" -ForegroundColor Yellow
    $success = Invoke-ImageMagickGenerator
} else {
    Write-Host "Using Node.js with sharp (recommended)" -ForegroundColor Green
    $success = Invoke-NodeIconGenerator
    
    # Fallback to ImageMagick if Node.js fails
    if (-not $success) {
        Write-Host "`n⚠️  Node.js method failed, trying ImageMagick..." -ForegroundColor Yellow
        $success = Invoke-ImageMagickGenerator
    }
}

if ($success) {
    Write-Host "`n✅ Icon generation completed successfully!" -ForegroundColor Green
    Write-Host "Generated icons in: $OutputDir" -ForegroundColor Gray
} else {
    Write-Host "`n❌ Icon generation failed!" -ForegroundColor Red
    exit 1
}