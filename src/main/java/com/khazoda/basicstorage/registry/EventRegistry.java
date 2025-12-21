package com.khazoda.basicstorage.registry;

import com.khazoda.basicstorage.BasicStorage;
import com.khazoda.basicstorage.block.CrateBlock;
import com.khazoda.basicstorage.block.CrateStationBlock;


public class EventRegistry {
  public static void init() {
    CrateBlock.initOnUseMethod();
    CrateBlock.initOnAttackMethod();
    CrateStationBlock.initOnUseMethod();

    BasicStorage.loadedRegistries += 1;
  }
}
