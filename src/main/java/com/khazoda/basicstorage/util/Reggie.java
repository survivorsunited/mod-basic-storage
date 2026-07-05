package com.khazoda.basicstorage.util;

import com.khazoda.basicstorage.Constants;
import com.khazoda.basicstorage.block.CrateBlock;
import com.khazoda.basicstorage.item.CrateBlockItem;
import net.minecraft.block.Block;
import net.minecraft.item.BlockItem;
import net.minecraft.item.Item;
import net.minecraft.item.ItemGroup;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.util.Identifier;

public class Reggie {
  public static Identifier newID(String name) {
    return Identifier.of(Constants.BS_NAMESPACE, name);
  }

  public static <B extends Block> B register(String name, B block, Item.Settings itemSettings) {
    return register(newID(name), block, itemSettings);
  }

  public static <B extends Block> B register(Identifier name, B block, Item.Settings itemSettings) {
    BlockItem item = block instanceof CrateBlock
        ? new CrateBlockItem(block, itemSettings)
        : new BlockItem(block, itemSettings);
    item.appendBlocks(Item.BLOCK_ITEMS, item);

    Registry.register(Registries.BLOCK, name, block);
    Registry.register(Registries.ITEM, name, item);
    return block;
  }

  public static <B extends Block> B register(String name, B block) {
    return register(newID(name), block);
  }

  public static <B extends Block> B register(Identifier name, B block) {
    Registry.register(Registries.BLOCK, name, block);
    return block;
  }

  public static <I extends BlockItem> I register(String name, I blockItem) {
    return register(newID(name), blockItem);
  }

  public static <I extends BlockItem> I register(Identifier name, I blockItem) {
    Registry.register(Registries.ITEM, name, blockItem);
    return blockItem;
  }

  public static <I extends ItemGroup> I register(I itemGroup) {
    Registry.register(Registries.ITEM_GROUP, Identifier.of("basicstorage"), itemGroup);
    return itemGroup;
  }

  public static <I extends Item> I register(String name, I item) {
    return Registry.register(Registries.ITEM, newID(name), item);
  }
}
