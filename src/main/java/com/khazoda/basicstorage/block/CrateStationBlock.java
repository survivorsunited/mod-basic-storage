package com.khazoda.basicstorage.block;

import com.khazoda.basicstorage.block.entity.CrateBlockEntity;
import com.khazoda.basicstorage.block.entity.CrateStationBlockEntity;
import com.khazoda.basicstorage.registry.BlockEntityRegistry;
import com.khazoda.basicstorage.registry.BlockRegistry;
import com.khazoda.basicstorage.registry.DataComponentRegistry;
import com.khazoda.basicstorage.registry.SoundRegistry;
import com.khazoda.basicstorage.structure.CrateSlotComponent;
import com.mojang.serialization.MapCodec;
import net.fabricmc.fabric.api.event.player.UseBlockCallback;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.fabricmc.fabric.api.transfer.v1.item.PlayerInventoryStorage;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.block.*;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.entity.BlockEntityTicker;
import net.minecraft.block.entity.BlockEntityType;
import net.minecraft.block.enums.NoteBlockInstrument;
import net.minecraft.block.piston.PistonBehavior;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemPlacementContext;
import net.minecraft.item.ItemStack;
import net.minecraft.sound.BlockSoundGroup;
import net.minecraft.sound.SoundCategory;
import net.minecraft.stat.Stats;
import net.minecraft.text.Text;
import net.minecraft.util.ActionResult;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraft.world.event.GameEvent;
import org.jetbrains.annotations.Nullable;

import java.util.ArrayList;
import java.util.List;

public class CrateStationBlock extends BlockWithEntity implements BlockEntityProvider {
  public static final MapCodec<CrateStationBlock> CODEC = CrateStationBlock.createCodec(CrateStationBlock::new);
  public static final Settings defaultSettings = Settings.create().sounds(BlockSoundGroup.WOOD).strength(3.5f)
      .pistonBehavior(PistonBehavior.BLOCK).instrument(NoteBlockInstrument.BASS).mapColor(MapColor.OAK_TAN);

  public CrateStationBlock(Settings settings) {
    super(settings);
  }

  public CrateStationBlock() {
    this(defaultSettings);
  }

  public static void initOnUseMethod() {
    UseBlockCallback.EVENT.register((PlayerEntity player, World world, Hand hand, BlockHitResult hit) -> {
      if (!world.getBlockState(hit.getBlockPos()).isOf(BlockRegistry.CRATE_STATION_BLOCK))
        return ActionResult.PASS;
      if (!player.canModifyBlocks() || player.isSpectator())
        return ActionResult.PASS;
      if(player.getStackInHand(hand).isOf(BlockRegistry.CRATE_BLOCK.asItem()) && player.isSneaking()) {
        return ActionResult.PASS;
      }

      BlockPos pos = hit.getBlockPos();
      BlockState state = world.getBlockState(pos);
      BlockEntity be = world.getBlockEntity(pos);

      if (be == null)
        return ActionResult.PASS;

      CrateStationBlockEntity cdbe = (CrateStationBlockEntity) be;
      ItemStack playerStack = player.getStackInHand(hand);
      int connectedCrateCount = cdbe.getConnectedCrates().size();
      int inserted = 0;

      if (player.isSneaking() && playerStack.isOf(BlockRegistry.CRATE_BLOCK.asItem())) {
        return ActionResult.PASS;
      }

      if (playerStack.isEmpty() && player.isSneaking()) {
        if (!world.isClient()) {
          cdbe.consolidateItems();
          player.sendMessage(Text.translatable("message.basicstorage.station.consolidated").withColor(0xDDFF99), true);
          world.playSound(null, pos, SoundRegistry.INSERT_LOADS, SoundCategory.BLOCKS, 1f, 1f);
        }
        return ActionResult.SUCCESS;
      }

      if (player.isSneaking()) {
        inserted = depositInventory(player, cdbe);
      } else if (!player.isSneaking()) {
        if (playerStack.isEmpty()) {
          if (!world.isClient())
            player.sendMessage(
                Text.translatable("message.basicstorage.station.connected_crate_count", connectedCrateCount)
                    .withColor(0xDDFF99),
                true);
          return ActionResult.PASS;
        }
        if (playerStack.isOf(BlockRegistry.CRATE_BLOCK.asItem())) {
          inserted = depositCrateContents(playerStack, cdbe);
        } else {
          inserted = depositStack(playerStack, cdbe);
        }
      }

      if (!world.isClient()) {
        if (inserted <= 0) {
          player.sendMessage(Text.translatable("message.basicstorage.station.no_matching_crates").withColor(0xFF9999),
              true);
          world.playSound(null, pos, SoundRegistry.NO_MATCH, SoundCategory.BLOCKS, 1.1f, 1f);
          return ActionResult.CONSUME;
        }

        if (inserted == 1) {
          world.playSound(null, pos, SoundRegistry.INSERT_ONE, SoundCategory.BLOCKS, 1f, 1.05f);
        } else if (inserted <= 64) {
          world.playSound(null, pos, SoundRegistry.INSERT_MANY, SoundCategory.BLOCKS, 1f, 1.05f);
        } else {
          world.playSound(null, pos, SoundRegistry.INSERT_LOADS, SoundCategory.BLOCKS, 1f, 1.05f);
        }

        state.updateNeighbors(world, pos, 1);
        cdbe.markDirty();
        player.incrementStat(Stats.USED.getOrCreateStat(playerStack.getItem()));
        world.emitGameEvent(player, GameEvent.BLOCK_CHANGE, pos);
      }

      return ActionResult.SUCCESS;
    });
  }

  private static int depositStack(ItemStack stack, CrateStationBlockEntity cdbe) {
    int inserted = 0;
    if (stack.isEmpty())
      return 0;

    ItemVariant variant = ItemVariant.of(stack);
    List<BlockPos> compatibleCrates = cdbe.getCrateRegistry().get(variant);
    if (compatibleCrates == null)
      return 0;
    World world = cdbe.getWorld();

    for (BlockPos cratePos : new ArrayList<>(compatibleCrates)) {
      if (world == null)
        return 0;
      BlockEntity be = world.getBlockEntity(cratePos);
      if (!(be instanceof CrateBlockEntity crate)) {
        continue;
      }

      try (Transaction transaction = Transaction.openOuter()) {
        inserted = (int) crate.storage.insert(variant, stack.getCount(), transaction);
        if (inserted > 0) {
          stack.decrement(inserted);
          transaction.commit();
          return inserted;
        }
      }
    }
    return inserted;
  }

  private static int depositCrateContents(ItemStack crateStack, CrateStationBlockEntity cdbe) {
    CrateSlotComponent contents = crateStack.get(DataComponentRegistry.CRATE_CONTENTS);
    if (contents == null || contents.count() <= 0 || contents.item().isBlank()) {
      return 0;
    }

    ItemVariant variant = contents.item();
    int remaining = contents.count();
    int inserted = 0;
    List<BlockPos> compatibleCrates = cdbe.getCrateRegistry().get(variant);
    if (compatibleCrates == null) {
      return 0;
    }
    World world = cdbe.getWorld();

    for (BlockPos cratePos : new ArrayList<>(compatibleCrates)) {
      if (world == null || remaining <= 0) {
        break;
      }
      BlockEntity be = world.getBlockEntity(cratePos);
      if (!(be instanceof CrateBlockEntity crate)) {
        continue;
      }

      try (Transaction transaction = Transaction.openOuter()) {
        int moved = (int) crate.storage.insert(variant, remaining, transaction);
        if (moved > 0) {
          inserted += moved;
          remaining -= moved;
          transaction.commit();
        }
      }
    }

    if (inserted > 0) {
      if (remaining > 0) {
        crateStack.set(DataComponentRegistry.CRATE_CONTENTS, new CrateSlotComponent(variant, remaining));
      } else {
        crateStack.remove(DataComponentRegistry.CRATE_CONTENTS);
      }
    }

    return inserted;
  }

  private static int depositInventory(PlayerEntity player, CrateStationBlockEntity cdbe) {
    int inserted = 0;
    PlayerInventoryStorage invStorage = PlayerInventoryStorage.of(player);
    World world = cdbe.getWorld();

    for (int i = 0; i < player.getInventory().size(); i++) {
      ItemStack stack = player.getInventory().getStack(i);
      if (!stack.isEmpty()) {
        ItemVariant variant = ItemVariant.of(stack);
        List<BlockPos> compatibleCrates = cdbe.getCrateRegistry().get(variant);

        if (compatibleCrates != null) {
          for (BlockPos cratePos : compatibleCrates) {
            if (world == null)
              return 0;
            BlockEntity be = world.getBlockEntity(cratePos);
            if (!(be instanceof CrateBlockEntity crate))
              continue;

            try (Transaction transaction = Transaction.openOuter()) {
              inserted += (int) crate.storage.insert(variant, stack.getCount(), transaction);
              if (inserted > 0) {
                stack.decrement(inserted);
                transaction.commit();
                break;
              }
            }
          }
        }
      }
    }
    return inserted;
  }

  @Nullable
  @Override
  public <T extends BlockEntity> BlockEntityTicker<T> getTicker(World world, BlockState state,
                                                                BlockEntityType<T> type) {
    return validateTicker(type, BlockEntityRegistry.CRATE_STATION_BLOCK_ENTITY, CrateStationBlockEntity::tick);
  }

  @Nullable
  @Override
  public BlockEntity createBlockEntity(BlockPos pos, BlockState state) {
    return new CrateStationBlockEntity(pos, state);
  }

  @Override
  public BlockState getPlacementState(ItemPlacementContext ctx) {
    return this.getDefaultState();
  }

  @Override
  protected BlockRenderType getRenderType(BlockState state) {
    return BlockRenderType.MODEL;
  }

  @Override
  public MapCodec<CrateStationBlock> getCodec() {
    return CODEC;
  }
}
