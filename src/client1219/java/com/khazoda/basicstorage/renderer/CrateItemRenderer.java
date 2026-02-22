package com.khazoda.basicstorage.renderer;

import com.khazoda.basicstorage.Constants;
import net.fabricmc.fabric.api.client.model.loading.v1.ModelLoadingPlugin;
import net.minecraft.util.Identifier;

/**
 * Model loading plugin for crate item (1.21.9+). Custom crate-in-hand rendering not implemented for this API.
 */
public class CrateItemRenderer implements ModelLoadingPlugin {
  public static final Identifier CRATE_ID = Identifier.of(Constants.BS_NAMESPACE, "block/crate");

  @Override
  public void initialize(Context pluginContext) {
  }
}
