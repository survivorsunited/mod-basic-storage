package com.khazoda.basicstorage.registry;
import com.khazoda.basicstorage.BasicStorage;
import com.khazoda.basicstorage.block.CrateBlock;
import com.khazoda.basicstorage.block.CrateStationBlock;
import com.khazoda.basicstorage.block.CrateTransferHandler;
public class EventRegistry {
  public static void init() {
    CrateTransferHandler.init();
    CrateBlock.initOnUseMethod();
    CrateStationBlock.initOnUseMethod();
    BasicStorage.loadedRegistries += 1;
  }
}
