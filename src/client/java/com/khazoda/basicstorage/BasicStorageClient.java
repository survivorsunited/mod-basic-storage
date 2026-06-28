package com.khazoda.basicstorage;

import com.khazoda.basicstorage.config.ConfigSyncPayload;
import com.khazoda.basicstorage.registry.BlockEntityRegistry;
import com.khazoda.basicstorage.renderer.CrateBlockEntityRenderer;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.minecraft.client.render.block.entity.BlockEntityRendererFactories;

public class BasicStorageClient implements ClientModInitializer {
  @Override
  public void onInitializeClient() {
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
