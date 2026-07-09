package com.khazoda.basicstorage;

import com.khazoda.basicstorage.config.ConfigSyncPayload;
import com.khazoda.basicstorage.registry.BlockEntityRegistry;
import com.khazoda.basicstorage.renderer.CrateBlockEntityRenderer;
import com.khazoda.basicstorage.renderer.CrateItemSpecialRenderer;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.minecraft.client.render.block.entity.BlockEntityRendererFactories;
import net.minecraft.client.render.item.model.special.SpecialModelTypes;
import net.minecraft.util.Identifier;

public class BasicStorageClient implements ClientModInitializer {
  @Override
  public void onInitializeClient() {
    SpecialModelTypes.ID_MAPPER.put(Identifier.of(Constants.BS_NAMESPACE, "crate_renderer"), CrateItemSpecialRenderer.Unbaked.CODEC);

    ClientPlayNetworking.registerGlobalReceiver(ConfigSyncPayload.ID, (payload, context) -> {
      context.client().execute(() -> {
        BasicStorageConfig.getInstance().setBreakWithAxeOnly(payload.breakWithAxeOnly());
      });
    });

    ClientPlayConnectionEvents.DISCONNECT.register((handler, client) -> {
      BasicStorageConfig.getInstance().load();
    });

    BlockEntityRendererFactories.register(BlockEntityRegistry.CRATE_BLOCK_ENTITY, CrateBlockEntityRenderer::new);
  }
}
