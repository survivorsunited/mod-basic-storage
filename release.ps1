Param(
  [Parameter(Mandatory=$true)]
  [string]$Version
)

# Ensure we're on main branch
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    Write-Host "⚠️  Not on main branch. Current branch: $currentBranch" -ForegroundColor Yellow
    Write-Host "Switching to main branch..." -ForegroundColor Cyan
    git checkout main
}
git pull

# Update gradle.properties with the new version
Write-Host "📝 Updating gradle.properties with version $Version" -ForegroundColor Cyan
$gradleProps = Get-Content gradle.properties -Raw
# Handle spaces around equals sign: "mod_version = " or "mod_version="
$gradleProps = $gradleProps -replace "mod_version\s*=\s*[^\r\n]*", "mod_version = $Version"
Set-Content gradle.properties -Value $gradleProps -NoNewline

# Check if version changed
$hasChanges = git diff --quiet gradle.properties
if ($LASTEXITCODE -ne 0) {
    Write-Host "📝 Version updated in gradle.properties" -ForegroundColor Green
    
    # Commit the version change
    git add gradle.properties
    git commit -m "Bump version to $Version"
    git push origin main
    
    Write-Host "✅ Committed version bump to main" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Version already set to $Version in gradle.properties" -ForegroundColor Gray
}

# Check if tag already exists and clean it up if needed
# Note: Workflow expects tags WITHOUT "v" prefix (e.g., "1.0.14" not "v1.0.14")
$tagName = $Version
$tagExists = git tag -l $tagName

if ($tagExists) {
    Write-Host "Tag $tagName already exists. Cleaning up..." -ForegroundColor Yellow
    
    # Delete local tag
    git tag -d $tagName
    
    # Delete remote tag
    git push origin ":refs/tags/$tagName" 2>&1 | Out-Null
    
    Write-Host "✅ Removed existing tag $tagName" -ForegroundColor Green
}

# Create and push tag (this will trigger release workflow)
Write-Host "Creating release tag: $tagName" -ForegroundColor Cyan
git tag -a $tagName -m "Release $tagName"
git push origin $tagName

Write-Host "✅ Tag $tagName pushed successfully" -ForegroundColor Green
Write-Host "The release workflow will automatically create the GitHub Release with all Minecraft versions" -ForegroundColor Yellow
