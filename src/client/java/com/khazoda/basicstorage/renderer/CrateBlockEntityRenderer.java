package com.khazoda.basicstorage.renderer;

import com.khazoda.basicstorage.block.CrateBlock;
import com.khazoda.basicstorage.block.entity.CrateBlockEntity;
import com.khazoda.basicstorage.util.NumberFormatter;
import net.minecraft.block.Block;
import net.minecraft.block.BlockState;
import net.minecraft.block.enums.Orientation;
import net.minecraft.client.font.TextRenderer;
import net.minecraft.client.item.ItemModelManager;
import net.minecraft.client.render.OverlayTexture;
import net.minecraft.client.render.WorldRenderer;
import net.minecraft.client.render.block.entity.BlockEntityRenderer;
import net.minecraft.client.render.block.entity.BlockEntityRendererFactory;
import net.minecraft.client.render.command.ModelCommandRenderer;
import net.minecraft.client.render.command.OrderedRenderCommandQueue;
import net.minecraft.client.render.item.ItemRenderState;
import net.minecraft.client.render.state.CameraRenderState;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.item.ItemDisplayContext;
import net.minecraft.item.ItemStack;
import net.minecraft.text.Text;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.RotationAxis;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;
import org.joml.Matrix4f;
import org.joml.Quaternionf;

public class CrateBlockEntityRenderer implements BlockEntityRenderer<CrateBlockEntity, CrateRenderState> {
  private static final Quaternionf ITEM_LIGHT_ROTATION_3D = RotationAxis.POSITIVE_X.rotationDegrees(-15).mul(RotationAxis.POSITIVE_Y.rotationDegrees(15));

  private final ItemModelManager itemModelManager;
  private final TextRenderer textRenderer;

  public CrateBlockEntityRenderer(BlockEntityRendererFactory.Context context) {
    this.itemModelManager = context.itemModelManager();
    this.textRenderer = context.textRenderer();
  }

  @Override
  public CrateRenderState createRenderState() {
    return new CrateRenderState();
  }

  @Override
  public void updateRenderState(CrateBlockEntity be, CrateRenderState crateState, float tickProgress, Vec3d cameraPos, @Nullable ModelCommandRenderer.CrumblingOverlayCommand crumblingOverlay) {
    BlockEntityRenderer.super.updateRenderState(be, crateState, tickProgress, cameraPos, crumblingOverlay);

    BlockState state = be.getCachedState();
    Orientation orientation = state.get(CrateBlock.ORIENTATION);
    Direction facing = orientation.getFacing().getOpposite();
    BlockPos pos = be.getPos();
    World world = be.getWorld();

    crateState.orientation = orientation;
    crateState.itemRenderState = null;
    crateState.itemCount = 0;
    crateState.cachedFormattedCount = null;
    crateState.cachedOrderedText = null;

    if (world != null) {
      BlockPos facePos = pos.offset(facing);
      BlockState faceState = world.getBlockState(facePos);
      if (!Block.shouldDrawSide(state, faceState, facing)) {
        return;
      }
      crateState.lightCoords = WorldRenderer.getLightmapCoordinates(world, facePos);
    }

    if (be.storage.isResourceBlank()) {
      return;
    }

    ItemStack stack = be.storage.getResource().toStack();
    ItemRenderState itemState = new ItemRenderState();
    this.itemModelManager.clearAndUpdate(itemState, stack, ItemDisplayContext.GUI, world, null, (int) pos.asLong());
    crateState.itemRenderState = itemState;

    crateState.itemCount = (int) be.storage.getAmount();
    crateState.cachedFormattedCount = NumberFormatter.format(crateState.itemCount);
    crateState.cachedOrderedText = Text.literal(crateState.cachedFormattedCount).asOrderedText();
  }

  @Override
  public void render(CrateRenderState state, MatrixStack matrices, OrderedRenderCommandQueue queue, CameraRenderState cameraState) {
    if (state.orientation == null) return;

    matrices.push();
    alignMatricesToOrientation(matrices, state.orientation);

    if (state.itemRenderState != null && !state.itemRenderState.isEmpty()) {
      renderItem(state, matrices, queue);
    }

    renderText(state, matrices, queue);
    matrices.pop();
  }

  private void renderItem(CrateRenderState state, MatrixStack matrices, OrderedRenderCommandQueue queue) {
    matrices.push();
    matrices.translate(0f, 0.125f, 0f);
    matrices.scale(0.5f, 0.5f, 0.5f);
    matrices.scale(0.75f, 0.75f, 1f);
    matrices.peek().getPositionMatrix().mul(new Matrix4f().scale(1, 1, 0.01f));
    matrices.peek().getNormalMatrix().rotate(ITEM_LIGHT_ROTATION_3D);
    state.itemRenderState.render(matrices, queue, state.lightCoords, OverlayTexture.DEFAULT_UV, 0);
    matrices.pop();
  }

  private void renderText(CrateRenderState state, MatrixStack matrices, OrderedRenderCommandQueue queue) {
    if (state.cachedOrderedText == null || state.cachedFormattedCount == null) return;

    matrices.push();
    matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(180));
    matrices.translate(0f, 0.21f, -0.01f);
    matrices.scale(0.02f, 0.02f, 0.02f);

    queue.submitText(
        matrices,
        -textRenderer.getWidth(state.cachedFormattedCount) / 2f,
        0,
        state.cachedOrderedText,
        false,
        TextRenderer.TextLayerType.POLYGON_OFFSET,
        state.lightCoords,
        0xFFFFDD99,
        0x00000000,
        0);

    matrices.pop();
  }

  protected void alignMatricesToOrientation(MatrixStack matrices, Orientation orientation) {
    matrices.translate(0.5, 0.5, 0.5);
    switch (orientation) {
      case NORTH_UP -> matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(180));
      case SOUTH_UP -> {
      }
      case EAST_UP -> matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(90));
      case WEST_UP -> matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(270));
      case UP_NORTH -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(0));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(270));
      }
      case UP_EAST -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(270));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(270));
      }
      case UP_SOUTH -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(180));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(270));
      }
      case UP_WEST -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(90));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(270));
      }
      case DOWN_NORTH -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(180));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(90));
      }
      case DOWN_EAST -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(90));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(90));
      }
      case DOWN_SOUTH -> matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(90));
      case DOWN_WEST -> {
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(270));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(90));
      }
    }

    matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(180));
    matrices.translate(0, 0, 0.51);
  }
}
