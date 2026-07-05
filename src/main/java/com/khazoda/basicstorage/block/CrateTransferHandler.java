package com.khazoda.basicstorage.block;

import com.khazoda.basicstorage.block.entity.CrateBlockEntity;
import com.khazoda.basicstorage.registry.BlockRegistry;
import com.khazoda.basicstorage.registry.DataComponentRegistry;
import com.khazoda.basicstorage.registry.SoundRegistry;
import com.khazoda.basicstorage.storage.CrateSlot;
import com.khazoda.basicstorage.structure.CrateSlotComponent;
import net.fabricmc.fabric.api.event.player.UseBlockCallback;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.block.BlockState;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.enums.Orientation;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.sound.SoundCategory;
import net.minecraft.util.ActionResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.world.World;
import net.minecraft.world.event.GameEvent;

public class CrateTransferHandler {
  public static void init() {
    UseBlockCallback.EVENT.register((PlayerEntity player, World world, net.minecraft.util.Hand hand, net.minecraft.util.hit.BlockHitResult hit) -> {
      BlockPos pos = hit.getBlockPos();
      BlockState state = world.getBlockState(pos);
      if (!state.isOf(BlockRegistry.CRATE_BLOCK)) {
        return ActionResult.PASS;
      }
      if (!player.canModifyBlocks() || player.isSpectator()) {
        return ActionResult.PASS;
      }

      ItemStack heldCrateStack = player.getStackInHand(hand);
      if (!heldCrateStack.isOf(BlockRegistry.CRATE_BLOCK.asItem())) {
        return ActionResult.PASS;
      }

      Direction facing = resolveFront(state);
      if (facing != hit.getSide()) {
        return ActionResult.PASS;
      }

      if (world.isClient()) {
        return ActionResult.SUCCESS;
      }

      BlockEntity be = world.getBlockEntity(pos);
      if (!(be instanceof CrateBlockEntity targetCbe)) {
        return ActionResult.PASS;
      }

      return transferCrateContents(player, world, pos, state, targetCbe, heldCrateStack);
    });
  }

  private static Direction resolveFront(BlockState state) {
    Orientation orientation = state.get(CrateBlock.ORIENTATION);
    Direction legacyFacing = state.get(CrateBlock.HORIZONTAL_FACING);

    if (orientation == Orientation.NORTH_UP && legacyFacing != Direction.NORTH) {
      return legacyFacing;
    }

    return orientation.getFacing();
  }

  private static ActionResult transferCrateContents(PlayerEntity player, World world, BlockPos targetPos, BlockState state,
      CrateBlockEntity targetCbe, ItemStack heldCrateStack) {
    CrateSlotComponent heldCrateComponent = heldCrateStack.get(DataComponentRegistry.CRATE_CONTENTS);
    ItemVariant heldItem = heldCrateComponent == null ? null : heldCrateComponent.item();
    int heldCount = heldCrateComponent == null ? 0 : heldCrateComponent.count();
    CrateSlot targetSlot = targetCbe.storage;

    boolean heldCrateIsEmpty = heldCrateComponent == null || heldCount <= 0 || heldItem == null || heldItem.isBlank();

    if (heldCrateIsEmpty) {
      if (targetSlot.isBlank()) {
        return ActionResult.PASS;
      }

      ItemVariant targetItem = targetSlot.getResource();
      long targetCount = targetSlot.getAmount();

      try (var transaction = Transaction.openOuter()) {
        long extracted = targetSlot.extract(targetItem, targetCount, transaction);
        if (extracted <= 0) {
          transaction.abort();
          return ActionResult.PASS;
        }

        CrateSlotComponent newComponent = new CrateSlotComponent(targetItem, (int) extracted);
        if (heldCrateStack.getCount() == 1) {
          heldCrateStack.set(DataComponentRegistry.CRATE_CONTENTS, newComponent);
        } else {
          heldCrateStack.decrement(1);
          ItemStack filledCrate = new ItemStack(BlockRegistry.CRATE_BLOCK.asItem());
          filledCrate.set(DataComponentRegistry.CRATE_CONTENTS, newComponent);
          player.getInventory().offerOrDrop(filledCrate);
        }

        transaction.commit();
        finishTransfer(world, targetPos, state, targetCbe);
        return ActionResult.SUCCESS;
      }
    }

    if (targetSlot.isBlank() || targetSlot.getResource().equals(heldItem)) {
      try (var transaction = Transaction.openOuter()) {
        long inserted = targetSlot.insert(heldItem, heldCount, transaction);
        if (inserted <= 0) {
          transaction.abort();
          return ActionResult.PASS;
        }

        int remaining = (int) (heldCount - inserted);
        if (remaining > 0) {
          heldCrateStack.set(DataComponentRegistry.CRATE_CONTENTS, new CrateSlotComponent(heldItem, remaining));
        } else {
          heldCrateStack.remove(DataComponentRegistry.CRATE_CONTENTS);
        }

        transaction.commit();
        finishTransfer(world, targetPos, state, targetCbe);
        return ActionResult.SUCCESS;
      }
    }

    world.playSound(null, targetPos, SoundRegistry.NO_MATCH, SoundCategory.BLOCKS, 1.1f, 1f);
    return ActionResult.CONSUME;
  }

  private static void finishTransfer(World world, BlockPos targetPos, BlockState state, CrateBlockEntity targetCbe) {
    world.playSound(null, targetPos, SoundRegistry.INSERT_MANY, SoundCategory.BLOCKS, 1f, 1f);
    targetCbe.refresh();
    state.updateNeighbors(world, targetPos, 1);
    world.updateComparators(targetPos, state.getBlock());
    world.emitGameEvent(null, GameEvent.BLOCK_CHANGE, targetPos);
  }
}
