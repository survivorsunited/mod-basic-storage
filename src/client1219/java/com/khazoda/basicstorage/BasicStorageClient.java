package com.khazoda.basicstorage;

import com.khazoda.basicstorage.registry.BlockEntityRegistry;
import com.khazoda.basicstorage.renderer.CrateBlockEntityRenderer;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandManager;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandRegistrationCallback;
import net.minecraft.client.render.block.entity.BlockEntityRendererFactories;
import net.minecraft.text.ClickEvent;
import net.minecraft.text.Style;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Identifier;

import java.net.URI;

public class BasicStorageClient implements ClientModInitializer {
  public static final Identifier HAS_ITEMS_ID = Identifier.of(Constants.BS_NAMESPACE, "has_items");

  @Override
  public void onInitializeClient() {
    BlockEntityRendererFactories.register(BlockEntityRegistry.CRATE_BLOCK_ENTITY, CrateBlockEntityRenderer::new);

    ClientCommandRegistrationCallback.EVENT.register((dispatcher, registryAccess) ->
        dispatcher.register(ClientCommandManager.literal("basicstorage")
            .executes(context -> {
              context.getSource().sendFeedback(Text.translatable("command.basicstorage.root").append(Text.literal(Constants.BS_VERSION).withColor(0x00FFFF)));
              return 1;
            })
            .then(ClientCommandManager.literal("wiki")
                .executes(context -> {
                  context.getSource().sendFeedback(Text.translatable("command.basicstorage.wiki").setStyle(Style.EMPTY.withColor(Formatting.BLUE).withUnderline(true).withClickEvent(new ClickEvent.OpenUrl(URI.create("https://modded.wiki/w/Mod:Basic_Storage")))));
                  return 1;
                })
            )
        )
    );
  }
}
