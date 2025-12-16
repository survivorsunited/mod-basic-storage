# Test Documentation

## Test Scripts

### 001-start-server.ps1
**Purpose**: Tests server startup and world loading for Minecraft 1.21.8  
**Validates**: 
- Server starts successfully
- Mod loads without errors
- No "Block id not set" errors
- Mod initialization completes

**Usage**:
```powershell
pwsh -File tests/001-start-server.ps1 -MinecraftVersion "1.21.8"
```

**Expected Results**:
- ✅ Server starts
- ✅ "[Basic Storage] Filling crates..." appears in logs
- ✅ "registry crates filled" appears in logs
- ✅ No "Block id not set" errors
- ✅ No "Failed to start" errors

**Failure Indicators**:
- ❌ "Block id not set" error
- ❌ "Failed to start the minecraft server"
- ❌ "ExceptionInInitializerError"
- ❌ "NullPointerException.*Block id"

## Version Comparison: 1.21.5 vs 1.21.8

### Working Version (1.21.5) - Built for Minecraft 1.21.5
**Minecraft Version**: 1.21.5  
**Loom Version**: 1.10-SNAPSHOT  
**Status**: ✅ Works (can run on 1.21.8 server due to backward compatibility)
**Block Registration Pattern**:
```java
// Uses default constructor with defaultSettings (no registry key)
public static final Settings defaultSettings = Settings.create()
    .sounds(BlockSoundGroup.WOOD)
    .strength(2.5f)
    .pistonBehavior(PistonBehavior.BLOCK)
    .instrument(NoteBlockInstrument.BASS)
    .mapColor(MapColor.OAK_TAN);

public CrateBlock() {
    this(defaultSettings);
}

// Registration uses default constructor
CRATE_BLOCK = register("crate", CrateBlock::new, CrateBlock.defaultSettings, crateItemSettings);
```

**Key Points**:
- ✅ No registry key set in Settings
- ✅ Uses default constructor
- ✅ Settings created without `.registryKey()` call
- ✅ Works on Minecraft 1.21.8 server (backward compatible)

### Current Version (1.21.8 - NOT WORKING) - Built for Minecraft 1.21.8
**Minecraft Version**: 1.21.8  
**Loom Version**: 1.12.0-alpha.25  
**Status**: ❌ Fails with "Block id not set" error
**Block Registration Pattern**:
```java
// Tries to set registry key in Settings
private static AbstractBlock.Settings createBlockSettings(Identifier id) {
    RegistryKey<Block> blockKey = RegistryKey.of(RegistryKeys.BLOCK, id);
    return AbstractBlock.Settings.create()
        .registryKey(blockKey)  // ❌ This triggers validation
        .sounds(BlockSoundGroup.WOOD)
        // ...
}

public CrateBlock(Identifier id) {
    this(createBlockSettings(id));
}

// Registration uses Identifier constructor
CRATE_BLOCK = Reggie.register(CRATE_ID, new CrateBlock(CRATE_ID), crateItemSettings);
```

**Key Points**:
- ❌ Sets registry key in Settings (triggers validation)
- ❌ Uses Identifier constructor
- ❌ Validation fails: "Block id not set"
- ❌ Blocks must be created before registration, but validation requires registration

### The Problem
Minecraft 1.21.8 added validation in `AbstractBlock.Settings` constructor that requires a registry key to be set. However:
1. Blocks must be created before they can be registered
2. Registry keys are only valid after registration
3. This creates a circular dependency

### The Solution (From 1.21.5)
**Don't set registry key in Settings** - use default constructor with defaultSettings:
- Settings created without `.registryKey()` call
- Registry key is set automatically during `Registry.register()`
- Validation is bypassed because no registry key is set during construction

### Why It Still Fails
Even though we're using the 1.21.5 pattern (default constructor, no registry key), the validation in Minecraft 1.21.8's API still triggers. This suggests:
- The validation was added/enhanced in Minecraft 1.21.8
- Building FOR 1.21.8 uses the 1.21.8 API which has stricter validation
- The 1.21.5 JAR works on 1.21.8 server because it was built against 1.21.5 API (backward compatible)

### Possible Solutions
1. **Build for 1.21.7** (if it doesn't have the validation) and run on 1.21.8 server
2. **Find a way to bypass the validation** in 1.21.8 API (mixin, reflection, or API workaround)
3. **Wait for Fabric/Mojang fix** if this is a known issue
4. **Use a different block registration pattern** if available in Fabric API

## Test Results

### Current Status (1.21.8)
- **Build**: ✅ Successful
- **Server Startup**: ❌ FAILED
- **Error**: `NullPointerException: Block id not set`
- **Location**: `CrateBlock.<init>` line 81 (`super(settings)`)

### Expected Status (After Fix)
- **Build**: ✅ Successful  
- **Server Startup**: ✅ Should pass
- **Mod Initialization**: ✅ Should complete
- **No Errors**: ✅ Should have no "Block id not set" errors

## Log Files

Test logs are stored in `tests/results/`:
- Format: `{test-name}-{version}-{timestamp}.log`
- Server logs: `{test-name}-{version}-{timestamp}-server.log`

## Troubleshooting

### "Block id not set" Error
- **Cause**: Registry key validation in Settings constructor
- **Solution**: Use default constructor with defaultSettings (no registry key)
- **Reference**: See 1.21.5 working pattern above

### Server Fails to Start
- Check `tests/results/` for detailed logs
- Review server log for specific error messages
- Verify Minecraft version compatibility

### Build Succeeds but Server Fails
- This indicates a runtime API compatibility issue
- Check if validation was added in the target Minecraft version
- Compare with working version patterns

