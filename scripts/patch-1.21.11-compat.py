from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def rw(path, fn):
    p = ROOT / path
    text = p.read_text()
    new = fn(text)
    if new != text:
        p.write_text(new)
        print(f"patched {path}")
    else:
        print(f"unchanged {path}")


def patch_crate_block(text):
    text = text.replace("import net.minecraft.loot.context.LootContextParameterSet;\n", "")
    if "import net.minecraft.world.block.WireOrientation;" not in text:
        text = text.replace("import net.minecraft.world.World;\n", "import net.minecraft.world.World;\nimport net.minecraft.world.block.WireOrientation;\n")
    text = re.sub(r"world\.isClient(?!\s*\()", "world.isClient()", text)
    text = text.replace("ActionResult.CONSUME_PARTIAL", "ActionResult.CONSUME")

    text = re.sub(
        r"\n  @Override\n  protected List<ItemStack> getDroppedStacks\(BlockState state, LootContextParameterSet\.Builder\s+builder\) \{\n    return super\.getDroppedStacks\(state, builder\);\n  \}\n",
        "\n",
        text,
        flags=re.S,
    )
    text = re.sub(
        r"\n  @Override\n  protected List<ItemStack> getDroppedStacks\([^}]+\}\n",
        "\n",
        text,
        flags=re.S,
    )

    text = re.sub(
        r"\n  @Override\n  protected void onStateReplaced\(BlockState state, World world, BlockPos pos, BlockState newState,\s+boolean moved\) \{\n    if \(state\.isOf\(newState\.getBlock\(\)\)\) \{\n      return;\n    \}\n    BlockEntity blockEntity = world\.getBlockEntity\(pos\);\n    if \(blockEntity instanceof CrateBlockEntity\) \{\n      world\.updateComparators\(pos, state\.getBlock\(\)\);\n      notifyNearbyStations\(world, pos\);\n      world\.emitGameEvent\(null, GameEvent\.BLOCK_DESTROY, pos\);\n    \}\n    super\.onStateReplaced\(state, world, pos, newState, moved\);\n  \}\n",
        "\n  @Override\n  protected void onStateReplaced(BlockState state, ServerWorld world, BlockPos pos, boolean moved) {\n    BlockEntity blockEntity = world.getBlockEntity(pos);\n    if (blockEntity instanceof CrateBlockEntity) {\n      world.updateComparators(pos, state.getBlock());\n      notifyNearbyStations(world, pos);\n      world.emitGameEvent(null, GameEvent.BLOCK_DESTROY, pos);\n    }\n    super.onStateReplaced(state, world, pos, moved);\n  }\n",
        text,
        flags=re.S,
    )

    text = text.replace(
        "public void neighborUpdate(BlockState state, World world, BlockPos pos, Block sourceBlock, BlockPos sourcePos, boolean notify)",
        "protected void neighborUpdate(BlockState state, World world, BlockPos pos, Block sourceBlock, WireOrientation wireOrientation, boolean notify)",
    )
    text = text.replace(
        "super.neighborUpdate(state, world, pos, sourceBlock, sourcePos, notify);",
        "super.neighborUpdate(state, world, pos, sourceBlock, wireOrientation, notify);",
    )

    text = text.replace("\n  @Override\n  public boolean hasComparatorOutput", "\n  public boolean hasComparatorOutput")
    text = text.replace("\n  @Override\n  public int getComparatorOutput", "\n  public int getComparatorOutput")
    text = text.replace("\n  @Override\n  public void appendTooltip", "\n  public void appendTooltip")
    return text


def patch_crate_station_block(text):
    text = text.replace("SoundRegistry.HANDLE_LOADS", "SoundRegistry.INSERT_LOADS")
    text = text.replace("player.getInventory().main.size()", "player.getInventory().size()")
    text = text.replace("player.getInventory().main.get(i)", "player.getInventory().getStack(i)")
    return text


def patch_station_entity(text):
    return re.sub(r"world\.isClient(?!\s*\()", "world.isClient()", text)


def patch_block_entity(text):
    text = text.replace("      world.getWorldChunk(pos).setNeedsSaving(true);\n", "      markDirty();\n")

    text = re.sub(
        r"\n  /\*\*\n   \* NBT Operations\n   \*\*/\n  @Override\n  protected void writeNbt\(NbtCompound nbt, RegistryWrapper\.WrapperLookup registryLookup\) \{\n    var storageNbt = new NbtCompound\(\);\n    storage\.writeNbt\(storageNbt, registryLookup\);\n    nbt\.put\(\"crateStack\", storageNbt\);\n    nbt\.putBoolean\(\"locked\", locked\);\n  \}\n\n  @Override\n  protected void readNbt\(NbtCompound nbt, RegistryWrapper\.WrapperLookup registryLookup\) \{\n    super\.readNbt\(nbt, registryLookup\);\n    if \(nbt\.contains\(\"crateStack\", 10\)\) \{\n      storage\.readNbt\(nbt\.getCompound\(\"crateStack\"\), registryLookup\);\n    \}\n    if \(nbt\.contains\(\"locked\", 1\)\) \{\n      locked = nbt\.getBoolean\(\"locked\");\n    \}\n  \}\n",
        "\n",
        text,
        flags=re.S,
    )

    text = text.replace(
        "    writeNbt(nbt, registryLookup);",
        "    var storageNbt = new NbtCompound();\n    storage.writeNbt(storageNbt, registryLookup);\n    nbt.put(\"crateStack\", storageNbt);\n    nbt.putBoolean(\"locked\", locked);",
    )

    text = re.sub(
        r"\n  @Override\n  protected void readComponents\(BlockEntity\.ComponentsAccess components\) \{\n    CrateSlotComponent contents = components\.getOrDefault\(DataComponentRegistry\.CRATE_CONTENTS,\s+CrateSlotComponent\.DEFAULT\);\n    if \(contents == null \|\| contents\.count\(\) == 0\)\n      return;\n    try \(Transaction t = Transaction\.openOuter\(\)\) \{\n      if \(!this\.storage\.isBlank\(\)\)\n        return; // Prevents creative block pick from duping items\n      this\.storage\.insert\(contents\.item\(\), contents\.count\(\), t\);\n      t\.commit\(\);\n    \}\n    this\.refresh\(\);\n  \}\n",
        "\n",
        text,
        flags=re.S,
    )
    return text


def patch_crate_slot(text):
    text = text.replace(
        '    item = ItemVariant.CODEC.parse(RegistryOps.of(NbtOps.INSTANCE, registryLookup), nbt.getCompound("item"))\n        .getOrThrow();\n    count = (int) nbt.getLong("count");',
        '    item = nbt.getCompound("item")\n        .map(itemNbt -> ItemVariant.CODEC.parse(RegistryOps.of(NbtOps.INSTANCE, registryLookup), itemNbt).getOrThrow())\n        .orElse(ItemVariant.blank());\n    count = nbt.getLong("count").map(Long::intValue).orElse(0);'
    )
    return text


def patch_reggie(text):
    text = text.replace("import net.minecraft.item.ArmorMaterial;\n", "")
    text = text.replace("import net.minecraft.registry.entry.RegistryEntry;\n", "")
    text = re.sub(
        r"\n  // Register Armor Material\n  public static RegistryEntry<ArmorMaterial> register\(String name, ArmorMaterial material\) \{\n    return Registry\.registerReference\(Registries\.ARMOR_MATERIAL, newID\(name\), material\);\n  \}\n",
        "\n",
        text,
        flags=re.S,
    )
    return text


def patch_sound_registry(text):
    if "HANDLE_ONE" not in text:
        text = text.replace(
            "  public static final SoundEvent NO_MATCH = register(\"no_match\");\n",
            "  public static final SoundEvent NO_MATCH = register(\"no_match\");\n  public static final SoundEvent HANDLE_ONE = INSERT_ONE;\n  public static final SoundEvent HANDLE_MANY = INSERT_MANY;\n  public static final SoundEvent HANDLE_LOADS = INSERT_LOADS;\n",
        )
    return text


def patch_block_entity_registry(text):
    if "FabricBlockEntityTypeBuilder" not in text:
        text = text.replace("import net.fabricmc.fabric.api.transfer.v1.item.ItemStorage;\n", "import net.fabricmc.fabric.api.object.builder.v1.block.entity.FabricBlockEntityTypeBuilder;\nimport net.fabricmc.fabric.api.transfer.v1.item.ItemStorage;\n")
    text = text.replace("BlockEntityType.Builder.create", "FabricBlockEntityTypeBuilder.create")
    return text


def patch_block_utils(text):
    text = text.replace("player.getWorld().raycast", "player.getEntityWorld().raycast")
    return text


def patch_config_payload(text):
    text = text.replace("PacketCodecs.BOOL", "PacketCodecs.BOOLEAN")
    return text


def patch_loot_provider(text):
    text = re.sub(
        r"\.apply\(CopyComponentsLootFunction\.builder\(CopyComponentsLootFunction\.Source\.BLOCK_ENTITY\)\s+\.include\(DataComponentRegistry\.CRATE_CONTENTS\)\)",
        "",
        text,
        flags=re.S,
    )
    return text.replace("import net.minecraft.loot.function.CopyComponentsLootFunction;\n", "")


rw("src/main/java/com/khazoda/basicstorage/block/CrateBlock.java", patch_crate_block)
rw("src/main/java/com/khazoda/basicstorage/block/CrateStationBlock.java", patch_crate_station_block)
rw("src/main/java/com/khazoda/basicstorage/block/entity/CrateStationBlockEntity.java", patch_station_entity)
rw("src/main/java/com/khazoda/basicstorage/block/entity/CrateBlockEntity.java", patch_block_entity)
rw("src/main/java/com/khazoda/basicstorage/storage/CrateSlot.java", patch_crate_slot)
rw("src/main/java/com/khazoda/basicstorage/util/Reggie.java", patch_reggie)
rw("src/main/java/com/khazoda/basicstorage/registry/SoundRegistry.java", patch_sound_registry)
rw("src/main/java/com/khazoda/basicstorage/registry/BlockEntityRegistry.java", patch_block_entity_registry)
rw("src/main/java/com/khazoda/basicstorage/util/BlockUtils.java", patch_block_utils)
rw("src/main/java/com/khazoda/basicstorage/config/ConfigSyncPayload.java", patch_config_payload)
rw("src/main/java/com/khazoda/basicstorage/datagen/CrateLootTableProvider.java", patch_loot_provider)
