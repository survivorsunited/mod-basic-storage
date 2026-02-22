package com.khazoda.basicstorage.datagen;

import com.khazoda.basicstorage.registry.BlockRegistry;
import com.khazoda.basicstorage.registry.DataComponentRegistry;
import net.fabricmc.fabric.api.datagen.v1.FabricDataOutput;
import net.fabricmc.fabric.api.datagen.v1.provider.FabricBlockLootTableProvider;
import net.minecraft.block.Block;
import net.minecraft.loot.LootPool;
import net.minecraft.loot.LootTable;
import net.minecraft.loot.entry.ItemEntry;
import net.minecraft.loot.function.CopyComponentsLootFunction;
import net.minecraft.loot.provider.number.ConstantLootNumberProvider;
import net.minecraft.registry.RegistryWrapper;

import java.lang.reflect.Method;
import java.util.concurrent.CompletableFuture;

public class CrateLootTableProvider extends FabricBlockLootTableProvider {

  protected CrateLootTableProvider(FabricDataOutput dataOutput, CompletableFuture<RegistryWrapper.WrapperLookup> registryLookup) {
    super(dataOutput, registryLookup);
  }

  @Override
  public void generate() {
    addDrop(BlockRegistry.CRATE_BLOCK, this::drawerDrops);
    addDrop(BlockRegistry.CRATE_STATION_BLOCK);
  }

  /** 1.21.8: builder(Source.BLOCK_ENTITY). 1.21.9+: blockEntity(LootContextParameters.BLOCK_ENTITY). */
  @SuppressWarnings("unchecked")
  private static CopyComponentsLootFunction.Builder copyBlockEntityComponentsBuilder() {
    try {
      Method blockEntity = CopyComponentsLootFunction.class.getMethod("blockEntity", net.minecraft.util.context.ContextParameter.class);
      Object param = net.minecraft.loot.context.LootContextParameters.class.getField("BLOCK_ENTITY").get(null);
      return (CopyComponentsLootFunction.Builder) blockEntity.invoke(null, param);
    } catch (Exception e1) {
      try {
        Class<?> sourceClass = Class.forName("net.minecraft.loot.function.CopyComponentsLootFunction$Source");
        Object blockEntitySource = java.util.Arrays.stream(sourceClass.getEnumConstants())
            .filter(c -> "BLOCK_ENTITY".equals(((Enum<?>) c).name())).findFirst().orElseThrow();
        Method builder = CopyComponentsLootFunction.class.getMethod("builder", sourceClass);
        return (CopyComponentsLootFunction.Builder) builder.invoke(null, blockEntitySource);
      } catch (Exception e2) {
        throw new RuntimeException("CopyComponentsLootFunction builder compatibility", e2);
      }
    }
  }

  private LootTable.Builder drawerDrops(Block drop) {
    return LootTable.builder().pool(LootPool.builder()
            .rolls(ConstantLootNumberProvider.create(1.0f)).with(ItemEntry.builder(drop)
                    .apply(copyBlockEntityComponentsBuilder()
                            .include(DataComponentRegistry.CRATE_CONTENTS))));
  }
}
