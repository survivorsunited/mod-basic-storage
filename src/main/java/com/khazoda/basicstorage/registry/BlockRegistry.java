package com.khazoda.basicstorage.registry;

import com.khazoda.basicstorage.BasicStorage;
import com.khazoda.basicstorage.block.CrateBlock;
import com.khazoda.basicstorage.block.CrateStationBlock;
import com.khazoda.basicstorage.util.Reggie;
import net.minecraft.block.Block;
import net.minecraft.block.MapColor;
import net.minecraft.block.enums.NoteBlockInstrument;
import net.minecraft.block.piston.PistonBehavior;
import net.minecraft.item.Item;
import net.minecraft.registry.RegistryKey;
import net.minecraft.registry.RegistryKeys;
import net.minecraft.sound.BlockSoundGroup;
import net.minecraft.util.Identifier;

public class BlockRegistry {
  private static final Identifier CRATE_ID = Reggie.newID("crate");
  private static final Identifier STATION_ID = Reggie.newID("crate_station");

  public static final Block CRATE_BLOCK = Reggie.register(CRATE_ID, new CrateBlock(blockSettings(CRATE_ID, 1f)), itemSettings(CRATE_ID));
  public static final Block CRATE_STATION_BLOCK = Reggie.register(STATION_ID, new CrateStationBlock(blockSettings(STATION_ID, 3.5f)), itemSettings(STATION_ID));

  private static Block.Settings blockSettings(Identifier id, float strength) {
    return Block.Settings.create().sounds(BlockSoundGroup.WOOD).pistonBehavior(PistonBehavior.BLOCK).instrument(NoteBlockInstrument.BASS).mapColor(MapColor.OAK_TAN).strength(strength).registryKey(RegistryKey.of(RegistryKeys.BLOCK, id));
  }

  private static Item.Settings itemSettings(Identifier id) {
    return new Item.Settings().maxCount(64).registryKey(RegistryKey.of(RegistryKeys.ITEM, id));
  }

  public static void init() {
    BasicStorage.loadedRegistries += 1;
  }
}
