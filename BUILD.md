# Build Documentation

This document explains how to build the Custom Portals mod, test it locally, and manage releases.

## Quick Start

### Prerequisites

- **Java 21** or higher
- **Gradle** (or use the included Gradle wrapper)
- **PowerShell** (for Windows build scripts)

### Basic Build Commands

**Windows (Recommended):**
```powershell
# Build the mod
.\build.ps1

# Build and start test server
.\build.ps1 -StartServer

# Build and start test server with specific Minecraft version
.\build.ps1 -StartServer -MinecraftVersion "1.21.8"
```

**Linux/Mac:**
```bash
# Build the mod
./gradlew build

# Clean and build
./gradlew clean build
```

### Build Output

Built JAR files are located in `build/libs/` with the naming format:
```
{jar_name}-{mod_version}.jar
```

Example: `custom-portals-1.1.0.jar`

## Build Configuration

### gradle.properties

All mod properties are centralized in `gradle.properties`:

- **Minecraft Version**: `minecraft_version=1.21.5`
- **Mod Version**: `mod_version=1.0.10`
- **Fabric Versions**: Loader, API, Loom versions
- **Mod Metadata**: Name, description, author, etc.

To build for a different Minecraft version, update `gradle.properties`:
```properties
minecraft_version=1.21.8
yarn_mappings=1.21.8+build.1
fabric_loader_version=0.17.3
fabric_version=0.134.0+1.21.8
```

### Supported Minecraft Versions

The `build.ps1` script supports testing with these Minecraft versions:
- **1.21.5** (default)
- **1.21.6**
- **1.21.7**
- **1.21.8**
- **1.21.9**
- **1.21.10**

The mod is built for the version specified in `gradle.properties`, but you can test it on any supported version using the `-MinecraftVersion` parameter.

## Build Scripts

### build.ps1 (Windows)

The `build.ps1` script provides a convenient way to build and test the mod locally.

**Features:**
- Builds the mod using Gradle
- Optionally starts a test server with the mod installed
- Automatically downloads required server files
- Sets up Java 21 environment
- Copies built mod to test server

**Usage:**
```powershell
# Build only
.\build.ps1

# Build and start test server (default: 1.21.5)
.\build.ps1 -StartServer

# Build and start test server with specific version
.\build.ps1 -StartServer -MinecraftVersion "1.21.8"
```

**What it does:**
1. Sets up Java 21 environment
2. Builds the mod using `./gradlew build`
3. If `-StartServer` is specified:
   - Creates `test-server` directory if needed
   - Downloads Minecraft server JAR for specified version
   - Downloads Fabric server launcher
   - Downloads Fabric API
   - Copies built mod to `test-server/mods/`
   - Starts the server

**Server Download Maps:**

The script includes download maps for:
- **Minecraft Server JARs**: All supported versions
- **Fabric Loader**: All supported versions
- **Fabric API**: All supported versions

These are defined in `build.ps1` and can be updated when new versions are released.

### scripts/start-server.ps1

Advanced server launcher script with features:
- Auto-detects Fabric server JAR
- Optimized JVM flags (8G-32G RAM)
- Automatic restart on crash
- Log monitoring

**Usage:**
```powershell
cd test-server
..\scripts\start-server.ps1
```

## Local Testing

### Testing the Mod

1. **Build the mod:**
   ```powershell
   .\build.ps1
   ```

2. **Start test server:**
   ```powershell
   .\build.ps1 -StartServer -MinecraftVersion "1.21.8"
   ```

3. **Check server logs:**
   ```powershell
   Get-Content test-server/logs/latest.log -Tail 50
   ```

4. **Verify mod loaded:**
   Look for these messages in the logs:
   ```
   [main/INFO]: Initializing Custom Portals mod!
   [main/INFO]: Custom Portals mod initialized!
   ```

### Testing Portal Functionality

To test the mod:

1. Start the test server
2. Connect with a Minecraft client
3. Create a portal frame using any block
4. Use a portal catalyst to activate the portal
5. Test portal linking and teleportation
6. Verify rune effects (haste, gate, enhancer, infinity)

## CI/CD Pipeline

### GitHub Actions Workflow

The `.github/workflows/build.yml` workflow provides comprehensive CI/CD automation:

#### Workflow Triggers

- **Pull Requests**: Builds and tests on every PR
- **Push to main**: Builds all versions and runs tests
- **Tag Creation**: Triggers full release process with multi-version builds

#### Jobs Overview

1. **`build-matrix`**: Parallel builds for all supported Minecraft versions
   - Runs 6 parallel jobs (one per Minecraft version: 1.21.5-1.21.10)
   - Each job builds, tests, and uploads a versioned JAR artifact
   - Includes server startup tests to verify mod loads correctly
   - JARs are renamed with Minecraft version: `{mod_name}-{mod_version}-{mc_version}.jar`

2. **`build`**: Standard build job for PRs and pushes
   - Builds the mod for the version in `gradle.properties`
   - Runs tests and validates build

3. **`release-manual`**: Full release process (triggered by tag creation)
   - Builds all 6 Minecraft versions sequentially
   - Collects all versioned JARs
   - Creates GitHub Release with all artifacts
   - Publishes to Modrinth

4. **`docs`**: Documentation generation and deployment
   - Builds project documentation
   - Deploys to GitHub Pages (if configured)

#### Multi-Version Build Process

The `release-manual` job builds the mod for all supported Minecraft versions:

1. **Version Configuration**: Reads `versions.json` for each Minecraft version's dependencies
2. **Sequential Builds**: For each version (1.21.5-1.21.10):
   - Updates Gradle wrapper to version-specific Gradle version
   - Updates `gradle.properties` with version-specific settings
   - Cleans build directory (preserving previously built JARs)
   - Builds the mod with `./gradlew build`
   - Copies built JAR to `build/libs-all/` with version suffix
3. **JAR Collection**: After all builds complete:
   - Moves all versioned JARs from `build/libs-all/` to `build/libs/`
   - Validates all 6 JARs are present
4. **Release Creation**: Creates GitHub Release with all 6 artifacts
5. **Modrinth Publishing**: Uploads all 6 JARs to Modrinth

#### Version Configuration

The `versions.json` file defines dependencies for each Minecraft version:

```json
{
  "1.21.5": {
    "yarn_mappings": "1.21.5+build.1",
    "loader_version": "0.16.14",
    "fabric_version": "0.126.0+1.21.5",
    "loom_version": "1.10-SNAPSHOT",
    "gradle_version": "8.14",
    "java_version": 21
  },
  ...
}
```

This allows the pipeline to automatically use the correct versions for each Minecraft release.

### Release Process

#### Automated Release (Recommended)

The release process is fully automated using the `release.ps1` script:

```powershell
# Create a new release (updates version, commits, creates tag, triggers pipeline)
.\release.ps1 -Version "1.0.33"
```

**What `release.ps1` does:**

1. **Checks branch**: Ensures you're on `main` branch
2. **Pulls latest**: Updates local repository
3. **Updates version**: Sets `mod_version` in `gradle.properties`
4. **Commits version**: Creates commit with message "Bump version to {version}"
5. **Pushes commit**: Pushes version bump to `main` branch
6. **Cleans tags**: Removes existing tag if present (local and remote)
7. **Creates tag**: Creates annotated tag with version (e.g., `1.0.33`)
8. **Pushes tag**: Pushes tag to trigger `release-manual` workflow

**After tag push:**
- GitHub Actions detects the tag creation event
- `release-manual` job starts automatically
- Builds all 6 Minecraft versions (takes ~5-10 minutes)
- Creates GitHub Release with all artifacts
- Publishes to Modrinth

#### Manual Release (Alternative)

If you need to create a release manually without the script:

```powershell
# 1. Update version in gradle.properties
# Edit gradle.properties and set: mod_version=1.0.33

# 2. Commit the version change
git add gradle.properties
git commit -m "Bump version to 1.0.33"
git push origin main

# 3. Create and push tag (without "v" prefix)
git tag -a "1.0.33" -m "Release 1.0.33"
git push origin "1.0.33"
```

**Important**: Tags should NOT have a "v" prefix (use `1.0.33` not `v1.0.33`).

#### Release Artifacts

Each release includes 6 JAR files, one for each supported Minecraft version:

- `su-compostables-{mod_version}-1.21.5.jar`
- `su-compostables-{mod_version}-1.21.6.jar`
- `su-compostables-{mod_version}-1.21.7.jar`
- `su-compostables-{mod_version}-1.21.8.jar`
- `su-compostables-{mod_version}-1.21.9.jar`
- `su-compostables-{mod_version}-1.21.10.jar`

All artifacts are:
- Attached to the GitHub Release
- Published to Modrinth
- Properly versioned for their respective Minecraft versions

### Checking Release Status

#### Using Check Scripts

Two PowerShell scripts are available for checking release status:

**`scripts/check-release.ps1`**: Check release and pipeline status
```powershell
# Check latest release
.\scripts\check-release.ps1

# Check specific release
.\scripts\check-release.ps1 -Tag "1.0.33"
```

**`scripts/check-pipeline-logs.ps1`**: Check detailed pipeline logs
```powershell
# Check latest failed run
.\scripts\check-pipeline-logs.ps1

# Check specific run
.\scripts\check-pipeline-logs.ps1 -RunId "19810743080"
```

#### Using GitHub CLI

You can also check releases directly:

```powershell
# List recent releases
gh release list

# View specific release
gh release view "1.0.33"

# Check workflow runs
gh run list --workflow=build.yml

# View workflow run details
gh run view {run-id}
```

#### Expected Release Timeline

1. **Tag Creation**: Immediate (when `release.ps1` completes)
2. **Workflow Start**: ~30 seconds after tag push
3. **Build Phase**: ~5-10 minutes (builds 6 versions sequentially)
4. **Release Creation**: ~1 minute after builds complete
5. **Modrinth Publishing**: ~1 minute after release creation

**Total time**: ~7-12 minutes from tag push to complete release

### Pipeline Testing

#### Server Startup Tests

Each `build-matrix` job includes a server startup test:

1. Downloads Minecraft server for the matrix version
2. Downloads Fabric Loader and API
3. Installs the built mod
4. Starts the server
5. Waits up to 60 seconds for server to start
6. Checks for "Done" in server logs (indicates successful startup)
7. Verifies mod loaded (checks for "compostables" in logs)

This ensures the mod works correctly on each Minecraft version before release.

#### Build Validation

The pipeline validates:
- ✅ All 6 Minecraft versions build successfully
- ✅ JARs are properly named with version suffixes
- ✅ Server starts correctly with the mod installed
- ✅ Mod initializes without errors
- ✅ All artifacts are collected for release

### Pipeline Monitoring Scripts

**scripts/check-pipeline.ps1**: Quick status check
```powershell
.\scripts\check-pipeline.ps1
```

**scripts/get-pipeline-errors.ps1**: Get detailed error information
```powershell
.\scripts\get-pipeline-errors.ps1
```

**scripts/watch-pipeline.ps1**: Monitor pipeline until completion
```powershell
.\scripts\watch-pipeline.ps1
```

## Troubleshooting

### Build Fails with Java Version Error

**Error**: `Minecraft 1.21.5 requires Java 21 but Gradle is using 17`

**Solution:**
- Ensure Java 21 is installed
- Set `JAVA_HOME` to Java 21 path
- Use `build.ps1` which automatically sets Java 21

### Server Won't Start

**Error**: Server fails to start or crashes

**Solution:**
- Check `test-server/logs/latest.log` for errors
- Verify mod JAR is in `test-server/mods/`
- Ensure Fabric API is present
- Check that Minecraft version matches mod build version
- Verify Java 21 is being used (check server startup logs)

### Mixin Errors

**Error**: Mixin application failed

**Solution:**
- Check mixin configuration in `compostables.mixins.json`
- Verify mixin class signatures match target methods
- Check server logs for specific mixin errors
- Ensure Fabric Loader version is compatible

### Mod Not Loading

**Error**: Mod doesn't appear in loaded mods list

**Solution:**
- Verify mod JAR is in `test-server/mods/`
- Check mod ID matches in `fabric.mod.json`
- Ensure Fabric API is installed
- Check server logs for initialization errors

## Advanced Usage

### Building Without Test Server

```powershell
# Just build
.\build.ps1
```

### Using Gradle Directly

```bash
# Build
./gradlew build

# Clean build
./gradlew clean build

# Build without tests
./gradlew build -x test
```

### Custom Build Properties

You can override properties:
```bash
./gradlew build -Pmod_version=1.1.0
```

### Building for Different Versions

To build for a different Minecraft version:

1. Update `gradle.properties`:
   ```properties
   minecraft_version=1.21.8
   yarn_mappings=1.21.8+build.1
   fabric_loader_version=0.17.3
   fabric_version=0.134.0+1.21.8
   ```

2. Build:
   ```powershell
   .\build.ps1
   ```

3. Test:
   ```powershell
   .\build.ps1 -StartServer -MinecraftVersion "1.21.8"
   ```

## Project Structure

```
mod-CustomPortals/
├── src/main/java/          # Java source code
│   └── dev/custom/portals/
│       ├── CustomPortals.java           # Main mod class
│       ├── blocks/                      # Portal and rune blocks
│       ├── config/                      # Configuration system
│       ├── data/                        # Portal data storage
│       ├── items/                       # Portal catalyst items
│       ├── mixin/                       # Mixins for client/server
│       ├── registry/                    # Block, item, particle registries
│       └── util/                        # Utility functions
├── src/main/resources/     # Resources (mixins, fabric.mod.json)
├── build/libs/            # Built JAR files
├── test-server/           # Local test server (created by build.ps1)
├── scripts/               # PowerShell build and deployment scripts
├── build.ps1              # Windows build script
├── release.ps1            # Release creation script
├── gradle.properties      # Build configuration
├── versions.json         # Version configuration for each MC version
└── build.gradle           # Gradle build script
```

## Related Files

### Build Files
- **gradle.properties**: Build configuration and mod metadata
- **build.gradle**: Gradle build script
- **versions.json**: Version configuration for each Minecraft version
- **build.ps1**: Windows build and test server script

### Scripts
- **release.ps1**: Automated release creation script
- **scripts/start-server.ps1**: Advanced server launcher
- **scripts/check-release.ps1**: Check release and pipeline status
- **scripts/check-pipeline-logs.ps1**: Check detailed pipeline logs
- **scripts/check-pipeline.ps1**: Quick pipeline status checker
- **scripts/get-pipeline-errors.ps1**: Get detailed pipeline error information
- **scripts/watch-pipeline.ps1**: Monitor pipeline until completion

### CI/CD Files
- **.github/workflows/build.yml**: Complete CI/CD pipeline configuration
- **src/main/resources/compostables.mixins.json**: Mixin configuration

## Version Management

### Current Version

The mod version is defined in `gradle.properties`:
```properties
mod_version=1.0.33
```

### Version Bumping

**Recommended**: Use `release.ps1` to bump versions:
```powershell
.\release.ps1 -Version "1.0.34"
```

This automatically:
- Updates `gradle.properties`
- Commits the change
- Creates and pushes a tag
- Triggers the release pipeline

**Manual Version Bump**:
1. Edit `gradle.properties` and update `mod_version`
2. Commit the change
3. Create a tag and push it

### Version Naming

- **Format**: `{major}.{minor}.{patch}` (e.g., `1.0.33`)
- **Tags**: Use version without "v" prefix (`1.0.33` not `v1.0.33`)
- **JARs**: Include Minecraft version suffix (`su-compostables-1.0.33-1.21.8.jar`)

### Version History

Version changes are tracked in:
- **Git tags**: Semantic version tags (e.g., `1.0.33`)
- **GitHub Releases**: Full release notes and artifacts
- **gradle.properties**: Version history in commit log
- **Modrinth**: Published versions with changelogs
