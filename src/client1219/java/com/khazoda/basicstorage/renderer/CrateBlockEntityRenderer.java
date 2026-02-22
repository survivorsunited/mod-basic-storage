package com.khazoda.basicstorage.renderer;

import com.khazoda.basicstorage.block.CrateBlock;
import com.khazoda.basicstorage.block.entity.CrateBlockEntity;
import com.khazoda.basicstorage.util.NumberFormatter;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.minecraft.block.Block;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.font.TextRenderer;
import net.minecraft.client.render.block.entity.BlockEntityRenderer;
import net.minecraft.client.render.block.entity.BlockEntityRendererFactory;
import net.minecraft.client.render.block.entity.state.BlockEntityRenderState;
import net.minecraft.client.render.command.ModelCommandRenderer;
import net.minecraft.client.render.command.OrderedRenderCommandQueue;
import net.minecraft.client.render.item.ItemRenderState;
import net.minecraft.client.render.state.CameraRenderState;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.item.ItemDisplayContext;
import net.minecraft.item.ItemStack;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.RotationAxis;
import net.minecraft.text.Text;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;

/**
 * Block entity renderer for crate (1.21.9+ state/queue API).
 */
public class CrateBlockEntityRenderer implements BlockEntityRenderer<CrateBlockEntity, CrateBlockEntityRenderState> {

  private final net.minecraft.client.render.item.ItemRenderer itemRenderer;
  private final TextRenderer textRenderer;
  private final net.minecraft.client.item.ItemModelManager itemModelManager;
  private final ItemRenderState itemRenderState = new ItemRenderState();

  public CrateBlockEntityRenderer(BlockEntityRendererFactory.Context context) {
    this.itemRenderer = context.itemRenderer();
    this.textRenderer = context.textRenderer();
    this.itemModelManager = context.itemModelManager();
  }

  @Override
  public CrateBlockEntityRenderState createRenderState() {
    return new CrateBlockEntityRenderState();
  }

  @Override
  public void updateRenderState(CrateBlockEntity be, CrateBlockEntityRenderState state, float tickProgress, Vec3d cameraPos, @Nullable ModelCommandRenderer.CrumblingOverlayCommand crumblingOverlay) {
    BlockEntityRenderState.updateBlockEntityRenderState(be, state, crumblingOverlay);
    state.itemVariant = be.storage.getResource();
    state.amount = be.storage.getAmount();
    state.facing = CrateBlock.getFront(be.getCachedState());
  }

  @Override
  public void render(CrateBlockEntityRenderState state, MatrixStack matrices, OrderedRenderCommandQueue queue, CameraRenderState cameraState) {
    if (state.amount <= 0 || state.itemVariant.isBlank()) return;
    World world = MinecraftClient.getInstance().world;
    if (world == null) return;
    BlockPos pos = state.pos;
    if (!shouldRender(state, state.facing, world, pos)) return;

    matrices.push();
    alignMatrices(matrices, state.facing);

    int light = state.lightmapCoordinates;
    String amountStr = NumberFormatter.format((int) state.amount);

    var player = MinecraftClient.getInstance().player;
    Vec3d playerPos = player != null ? new Vec3d(player.getX(), player.getY(), player.getZ()) : Vec3d.ofCenter(pos);
    int distance = (player != null && player.isUsingSpyglass()) ? 100 : 40;
    if (pos.isWithinDistance(playerPos, distance)) {
      matrices.push();
      matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(180));
      matrices.translate(0f, 0.21f, -0.01f);
      matrices.scale(0.02f, 0.02f, 0.02f);
      float w = textRenderer.getWidth(amountStr) / 2f;
      queue.submitText(matrices, -w, 0, Text.literal(amountStr).asOrderedText(), false, TextRenderer.TextLayerType.NORMAL, light, 0xFFFFDD99, 0, 0);
      matrices.pop();
      renderItem(state.itemVariant, light, matrices, queue);
    }
    matrices.pop();
  }

  private void renderItem(ItemVariant itemVariant, int light, MatrixStack matrices, OrderedRenderCommandQueue queue) {
    if (itemVariant.isBlank()) return;
    ItemStack stack = itemVariant.toStack();
    matrices.push();
    matrices.translate(0f, 0.125f, 0f);
    matrices.scale(0.5f, 0.5f, 0.5f);
    matrices.scale(0.75f, 0.75f, 1f);
    itemModelManager.clearAndUpdate(itemRenderState, stack, ItemDisplayContext.GUI, null, null, (int) System.currentTimeMillis());
    if (!itemRenderState.isEmpty()) {
      itemRenderState.render(matrices, queue, light, net.minecraft.client.render.OverlayTexture.DEFAULT_UV, 0);
    }
    matrices.pop();
  }

  private void alignMatrices(MatrixStack matrices, Direction dir) {
    var pos = dir.getUnitVector();
    matrices.translate(pos.x / 2 + 0.5, pos.y / 2 + 0.5, pos.z / 2 + 0.5);
    matrices.multiply(dir.getRotationQuaternion());
    matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(-90));
    matrices.translate(0, 0, 0.01);
  }

  private boolean shouldRender(CrateBlockEntityRenderState state, Direction facing, World world, BlockPos pos) {
    return Block.shouldDrawSide(state.blockState, world.getBlockState(pos.offset(facing)), facing);
  }
}
