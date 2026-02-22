package com.khazoda.basicstorage.renderer;

import com.khazoda.basicstorage.Constants;
import net.minecraft.util.Identifier;

/**
 * Crate item constants (1.21.9+). ModelLoadingPlugin not used for 1.21.11 (Fabric API package change).
 */
public class CrateItemRenderer {
  public static final Identifier CRATE_ID = Identifier.of(Constants.BS_NAMESPACE, "block/crate");
}
