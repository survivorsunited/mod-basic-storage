# Scripts Reference

All scripts are located in the `scripts/` folder and include proper exit codes.

## Git Scripts

### git-status.ps1
Check git status
```powershell
.\scripts\git-status.ps1
```

### git-add.ps1
Stage files for commit
```powershell
.\scripts\git-add.ps1                    # Stage all files
.\scripts\git-add.ps1 -Files "file1","file2"  # Stage specific files
```

### git-commit.ps1
Commit staged changes
```powershell
.\scripts\git-commit.ps1 -Message "Commit message"
```

### git-push.ps1
Push to remote
```powershell
.\scripts\git-push.ps1                    # Push main to origin
.\scripts\git-push.ps1 -Branch "feature"  # Push specific branch
```

### git-commit-push.ps1
Commit and push in one command
```powershell
.\scripts\git-commit-push.ps1 -Message "Commit message"
.\scripts\git-commit-push.ps1 -Message "Msg" -Files "file1","file2"
```

## Pipeline Scripts

### check-pipeline-status.ps1
Check recent pipeline runs
```powershell
.\scripts\check-pipeline-status.ps1
.\scripts\check-pipeline-status.ps1 -Limit 5
```

### check-pipeline.ps1
Quick pipeline status with error summary
```powershell
.\scripts\check-pipeline.ps1
```

### get-pipeline-errors.ps1
Get detailed error information from latest failed run
```powershell
.\scripts\get-pipeline-errors.ps1
```

### get-latest-run-id.ps1
Get the latest pipeline run ID
```powershell
$runId = .\scripts\get-latest-run-id.ps1
```

### watch-pipeline.ps1
Monitor pipeline until completion
```powershell
.\scripts\watch-pipeline.ps1
.\scripts\watch-pipeline.ps1 -MaxWait 300 -CheckInterval 10
```

## Build Scripts

### build.ps1 (root)
Build the mod and optionally start test server
```powershell
.\build.ps1
.\build.ps1 -StartServer
.\build.ps1 -StartServer -MinecraftVersion "1.21.10"
```

### release.ps1 (root)
Create a new release
```powershell
.\release.ps1 -Version "1.1.0"
```

## Other Scripts

### start-server.ps1
Advanced server launcher with auto-restart
```powershell
cd test-server
..\scripts\start-server.ps1
```

### check-release.ps1
Check release and pipeline status
```powershell
.\scripts\check-release.ps1
.\scripts\check-release.ps1 -Tag "1.1.0"
```

### check-pipeline-logs.ps1
Check detailed pipeline logs
```powershell
.\scripts\check-pipeline-logs.ps1
```

### update-modrinth.ps1
Update Modrinth project description
```powershell
.\scripts\update-modrinth.ps1
```

## Notes

- All scripts include proper exit codes (`exit $LASTEXITCODE` or `exit 0`)
- Scripts check for errors and exit early if commands fail
- Use scripts instead of direct commands to avoid hanging

