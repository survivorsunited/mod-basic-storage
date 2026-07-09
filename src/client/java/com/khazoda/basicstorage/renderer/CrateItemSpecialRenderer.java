package com.khazoda.basicstorage.renderer;

import com.khazoda.basicstorage.registry.BlockRegistry;
import com.khazoda.basicstorage.registry.DataComponentRegistry;
import com.khazoda.basicstorage.structure.CrateSlotComponent;
import com.khazoda.basicstorage.util.NumberFormatter;
import com.mojang.serialization.MapCodec;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.font.TextRenderer;
import net.minecraft.client.item.ItemModelManager;
import net.minecraft.client.render.command.OrderedRenderCommandQueue;
import net.minecraft.client.render.item.ItemRenderState;
import net.minecraft.client.render.item.model.special.SpecialModelRenderer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.item.ItemDisplayContext;
import net.minecraft.item.ItemStack;
import net.minecraft.text.Text;
import net.minecraft.util.math.RotationAxis;
import org.joml.Matrix4f;
import org.joml.Vector3f;
import org.joml.Vector3fc;

import java.util.function.Consumer;

public class CrateItemSpecialRenderer implements SpecialModelRenderer<CrateSlotComponent> {
  @Override
  public CrateSlotComponent getData(ItemStack stack) {
    return stack.get(DataComponentRegistry.CRATE_CONTENTS);
  }

  @Override
  public void render(CrateSlotComponent contents, ItemDisplayContext displayContext, MatrixStack matrices,
      OrderedRenderCommandQueue queue, int light, int overlay, boolean glint, int seed) {
    matrices.push();
    rotateFrontFaceUp(displayContext, matrices);

    queue.submitBlock(matrices, BlockRegistry.CRATE_BLOCK.getDefaultState(), light, overlay, 0);

    if (contents != null && contents.count() > 0 && !contents.item().isBlank()) {
      matrices.push();
      alignOverlayToFrontFace(matrices);
      renderStoredItem(contents, displayContext, matrices, queue, light, overlay, seed);
      renderStoredCount(contents, matrices, queue, light);
      matrices.pop();
    }

    matrices.pop();
  }

  private void rotateFrontFaceUp(ItemDisplayContext displayContext, MatrixStack matrices) {
    matrices.translate(0.5, 0.5, 0.5);
    matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(90));

    if (displayContext == ItemDisplayContext.FIRST_PERSON_RIGHT_HAND || displayContext == ItemDisplayContext.FIRST_PERSON_LEFT_HAND) {
      matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(-20));
    } else if (displayContext == ItemDisplayContext.THIRD_PERSON_RIGHT_HAND || displayContext == ItemDisplayContext.THIRD_PERSON_LEFT_HAND) {
      matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(-15));
    }

    matrices.translate(-0.5, -0.5, -0.5);
  }

  private void alignOverlayToFrontFace(MatrixStack matrices) {
    matrices.translate(0.5, 0.5, -0.0125);
    matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(180));
  }

  private void renderStoredItem(CrateSlotComponent contents, ItemDisplayContext displayContext, MatrixStack matrices,
      OrderedRenderCommandQueue queue, int light, int overlay, int seed) {
    MinecraftClient client = MinecraftClient.getInstance();
    ItemModelManager itemModelManager = client.getItemModelManager();
    ItemStack stack = contents.item().toStack();
    ItemRenderState itemRenderState = new ItemRenderState();

    itemModelManager.clearAndUpdate(itemRenderState, stack, ItemDisplayContext.GUI, client.world, null, seed);

    matrices.push();
    matrices.translate(0f, 0.13f, 0f);
    matrices.scale(0.5f, 0.5f, 0.5f);
    matrices.scale(0.75f, 0.75f, 1f);
    matrices.peek().getPositionMatrix().mul(new Matrix4f().scale(1, 1, 0.01f));
    itemRenderState.render(matrices, queue, light, overlay, seed);
    matrices.pop();
  }

  private void renderStoredCount(CrateSlotComponent contents, MatrixStack matrices, OrderedRenderCommandQueue queue, int light) {
    MinecraftClient client = MinecraftClient.getInstance();
    TextRenderer textRenderer = client.textRenderer;
    String count = NumberFormatter.format(contents.count());

    matrices.push();
    matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(180));
    matrices.translate(0f, 0.22f, -0.015f);
    matrices.scale(0.018f, 0.018f, 0.018f);

    queue.submitText(
        matrices,
        -textRenderer.getWidth(count) / 2f,
        0,
        Text.literal(count).asOrderedText(),
        false,
        TextRenderer.TextLayerType.POLYGON_OFFSET,
        light,
        0xFFFFDD99,
        0x00000000,
        0);

    matrices.pop();
  }

  @Override
  public void collectVertices(Consumer<Vector3fc> consumer) {
    consumer.accept(new Vector3f(0.0f, 0.0f, 0.0f));
    consumer.accept(new Vector3f(1.0f, 1.0f, 1.0f));
  }

  public record Unbaked() implements SpecialModelRenderer.Unbaked {
    public static final CrateItemSpecialRenderer.Unbaked INSTANCE = new CrateItemSpecialRenderer.Unbaked();
    public static final MapCodec<CrateItemSpecialRenderer.Unbaked> CODEC = MapCodec.unit(INSTANCE);

    @Override
    public SpecialModelRenderer<?> bake(SpecialModelRenderer.BakeContext context) {
      return new CrateItemSpecialRenderer();
    }

    @Override
    public MapCodec<CrateItemSpecialRenderer.Unbaked> getCodec() {
      return CODEC;
    }
  }
}
