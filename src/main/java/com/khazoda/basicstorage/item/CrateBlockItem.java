package com.khazoda.basicstorage.item;

import com.khazoda.basicstorage.registry.DataComponentRegistry;
import com.khazoda.basicstorage.structure.CrateSlotComponent;
import com.khazoda.basicstorage.util.NumberFormatter;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.minecraft.block.Block;
import net.minecraft.component.type.TooltipDisplayComponent;
import net.minecraft.item.BlockItem;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.item.tooltip.TooltipType;
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;

import java.util.function.Consumer;

public class CrateBlockItem extends BlockItem {
  public CrateBlockItem(Block block, Item.Settings settings) {
    super(block, settings);
  }

  @Override
  public void appendTooltip(ItemStack stack, Item.TooltipContext context, TooltipDisplayComponent displayComponent, Consumer<Text> textConsumer, TooltipType type) {
    CrateSlotComponent contents = stack.get(DataComponentRegistry.CRATE_CONTENTS);
    if (contents == null || contents.count() <= 0 || contents.item().isBlank()) {
      return;
    }

    ItemVariant item = contents.item();
    MutableText countLine = Text.literal("x" + NumberFormatter.toFormattedNumber(contents.count())).withColor(0xFFDD99);
    MutableText itemLine = Text.literal(item.getItem().getName().getString()).withColor(0xCCAA77);

    textConsumer.accept(countLine);
    textConsumer.accept(itemLine);
  }
}
