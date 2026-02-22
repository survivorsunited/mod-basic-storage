package com.khazoda.basicstorage.renderer;

import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.minecraft.client.render.block.entity.state.BlockEntityRenderState;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;

/**
 * Render state for crate block entity (1.21.9+ submit/render API).
 */
public class CrateBlockEntityRenderState extends BlockEntityRenderState {
  public ItemVariant itemVariant = ItemVariant.blank();
  public long amount;
  public Direction facing = Direction.NORTH;
}
