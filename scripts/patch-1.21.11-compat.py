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


def find_method_bounds(text, signature):
    idx = text.find(signature)
    if idx < 0:
        return None

    start = text.rfind("\n", 0, idx) + 1

    # Include an immediately preceding @Override annotation.
    prev_start = text.rfind("\n", 0, max(0, start - 2)) + 1
    prev_line = text[prev_start:start].strip()
    if prev_line == "@Override":
        start = prev_start

    brace_start = text.find("{", idx)
    if brace_start < 0:
        return None

    depth = 0
    for pos in range(brace_start, len(text)):
        char = text[pos]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = pos + 1
                if end < len(text) and text[end:end + 1] == "\n":
                    end += 1
                return start, end
    return None


def remove_method(text, signature):
    bounds = find_method_bounds(text, signature)
    if not bounds:
        return text
    start, end = bounds
    return text[:start] + text[end:]


def replace_method(text, signature, replacement):
    bounds = find_method_bounds(text, signature)
    if not bounds:
        return text
    start, end = bounds
    return text[:start] + replacement + text[end:]


def patch_crate_block(text):
    text = text.replace("import net.minecraft.loot.context.LootContextParameterSet;\n", "")
    if "import net.minecraft.world.block.WireOrientation;" not in text:
        text = text.replace(
            "import net.minecraft.world.World;\n",
            "import net.minecraft.world.World;\nimport net.minecraft.world.block.WireOrientation;\n",
        )

    text = re.sub(r"world\.isClient(?!\s*\()", "world.isClient()", text)
    text = text.replace("ActionResult.CONSUME_PARTIAL", "ActionResult.CONSUME")
    text = remove_method(text, "protected List<ItemStack> getDroppedStacks")

    text = replace_method(
        text,
        "protected void onStateReplaced(BlockState state, World world, BlockPos pos, BlockState newState",
        "  @Override\n"
        "  protected void onStateReplaced(BlockState state, ServerWorld world, BlockPos pos, boolean moved) {\n"
        "    BlockEntity blockEntity = world.getBlockEntity(pos);\n"
        "    if (blockEntity instanceof CrateBlockEntity) {\n"
        "      world.updateComparators(pos, state.getBlock());\n"
        "      notifyNearbyStations(world, pos);\n"
        "      world.emitGameEvent(null, GameEvent.BLOCK_DESTROY, pos);\n"
        "    }\n"
        "    super.onStateReplaced(state, world, pos, moved);\n"
        "  }\n",
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
    text = remove_method(text, "protected void writeNbt(NbtCompound nbt")
    text = remove_method(text, "protected void readNbt(NbtCompound nbt")
    text = remove_method(text, "protected void readComponents(")

    text = text.replace(
        "    writeNbt(nbt, registryLookup);",
        "    var storageNbt = new NbtCompound();\n"
        "    storage.writeNbt(storageNbt, registryLookup);\n"
        "    nbt.put(\"crateStack\", storageNbt);\n"
        "    nbt.putBoolean(\"locked\", locked);",
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
    text = remove_method(text, "public static RegistryEntry<ArmorMaterial> register")
    return text


def patch_sound_registry(text):
    if "HANDLE_ONE" not in text:
        text = text.replace(
            "  public static final SoundEvent NO_MATCH = register(\"no_match\");\n",
            "  public static final SoundEvent NO_MATCH = register(\"no_match\");\n"
            "  public static final SoundEvent HANDLE_ONE = INSERT_ONE;\n"
            "  public static final SoundEvent HANDLE_MANY = INSERT_MANY;\n"
            "  public static final SoundEvent HANDLE_LOADS = INSERT_LOADS;\n",
        )
    return text


def patch_block_entity_registry(text):
    if "FabricBlockEntityTypeBuilder" not in text:
        text = text.replace(
            "import net.fabricmc.fabric.api.transfer.v1.item.ItemStorage;\n",
            "import net.fabricmc.fabric.api.object.builder.v1.block.entity.FabricBlockEntityTypeBuilder;\n"
            "import net.fabricmc.fabric.api.transfer.v1.item.ItemStorage;\n",
        )
    text = text.replace("BlockEntityType.Builder.create", "FabricBlockEntityTypeBuilder.create")
    return text


def patch_block_utils(text):
    return text.replace("player.getWorld().raycast", "player.getEntityWorld().raycast")


def patch_config_payload(text):
    return text.replace("PacketCodecs.BOOL", "PacketCodecs.BOOLEAN")


def patch_loot_provider(text):
    text = text.replace("import net.minecraft.loot.function.CopyComponentsLootFunction;\n", "")
    text = text.replace(
        ".apply(CopyComponentsLootFunction.builder(CopyComponentsLootFunction.Source.BLOCK_ENTITY)\n                .include(DataComponentRegistry.CRATE_CONTENTS))",
        "",
    )
    text = text.replace(
        ".apply(CopyComponentsLootFunction.builder(CopyComponentsLootFunction.Source.BLOCK_ENTITY)\n            .include(DataComponentRegistry.CRATE_CONTENTS))",
        "",
    )
    return text


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
