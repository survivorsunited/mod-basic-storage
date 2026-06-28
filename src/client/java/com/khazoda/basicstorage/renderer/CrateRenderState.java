package com.khazoda.basicstorage.renderer;

import net.minecraft.block.enums.Orientation;
import net.minecraft.client.render.block.entity.state.BlockEntityRenderState;
import net.minecraft.client.render.item.ItemRenderState;
import net.minecraft.text.OrderedText;

public class CrateRenderState extends BlockEntityRenderState {
  public ItemRenderState itemRenderState;
  public int itemCount;
  public OrderedText cachedOrderedText;
  public String cachedFormattedCount;
  public int lightCoords;
  public Orientation orientation;
}
