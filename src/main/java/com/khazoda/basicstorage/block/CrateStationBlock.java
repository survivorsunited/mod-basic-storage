package com.khazoda.basicstorage.block;

import com.khazoda.basicstorage.block.entity.CrateBlockEntity;
import com.khazoda.basicstorage.block.entity.CrateStationBlockEntity;
import com.khazoda.basicstorage.registry.BlockEntityRegistry;
import com.khazoda.basicstorage.registry.BlockRegistry;
import com.khazoda.basicstorage.registry.SoundRegistry;
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
import java.util.Map;

/**
 * Right Click
 * > holding stack - Search for nearest crate containing stack item type and
 * deposit stack into it
 * > no valid crate found? - notify user
 * > holding nothing - Display number of connected crates
 * Shift Right Click - Add all items from inventory to crates that match the
 * items
 * > no valid crate found? - notify user
 * Left Click - Nothing
 * Shift Left Click - Nothing
 */
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

  /**
   * Event hook instead of onUse() method in order to capture interactions while
   * sneaking
   */
  public static void initOnUseMethod() {
    UseBlockCallback.EVENT.register((PlayerEntity player, World world, Hand hand, BlockHitResult hit) -> {
      if (!world.getBlockState(hit.getBlockPos()).isOf(BlockRegistry.CRATE_STATION_BLOCK))
        return ActionResult.PASS;
      if (!player.canModifyBlocks() || player.isSpectator())
        return ActionResult.PASS;

      BlockPos pos = hit.getBlockPos();
      BlockState state = world.getBlockState(pos);
      BlockEntity be = world.getBlockEntity(pos);

      if (be == null)
        return ActionResult.PASS;

      CrateStationBlockEntity cdbe = (CrateStationBlockEntity) be;
      ItemStack playerStack = player.getMainHandStack();
      int connectedCrateCount = cdbe.getConnectedCrates().size();
      int inserted = 0;

      if (player.isSneaking()) {
        if (playerStack.isEmpty()) {
          // Consolidate items when sneaking with empty hand
          boolean consolidated = consolidateItems(cdbe);
          if (!world.isClient()) {
            if (consolidated) {
              player.sendMessage(
                  Text.translatable("message.basicstorage.station.items_consolidated").withColor(0x99FF99),
                  true);
              world.playSound(null, pos, SoundRegistry.HANDLE_MANY, SoundCategory.BLOCKS, 1f, 1.05f);
              state.updateNeighbors(world, pos, 1);
              cdbe.markDirty();
              world.emitGameEvent(player, GameEvent.BLOCK_CHANGE, pos);
            } else {
              player.sendMessage(
                  Text.translatable("message.basicstorage.station.no_items_to_consolidate").withColor(0xFF9999),
                  true);
            }
          }
          return consolidated ? ActionResult.SUCCESS : ActionResult.PASS;
        } else {
          inserted = depositInventory(player, cdbe);
        }
      } else if (!player.isSneaking()) {
        if (playerStack.isEmpty()) {
          if (!world.isClient())
            player.sendMessage(
                Text.translatable("message.basicstorage.station.connected_crate_count", connectedCrateCount)
                    .withColor(0xDDFF99),
                true);
          return ActionResult.PASS;
        }
        inserted = depositStack(player.getStackInHand(hand), cdbe);
      }

      if (!world.isClient()) {
        if (inserted <= 0) {
          player.sendMessage(Text.translatable("message.basicstorage.station.no_matching_crates").withColor(0xFF9999),
              true);
          world.playSound(null, pos, SoundRegistry.NO_MATCH, SoundCategory.BLOCKS, 1.1f, 1f);
          return ActionResult.CONSUME;
        }

        if (inserted == 1) {
          world.playSound(null, pos, SoundRegistry.HANDLE_ONE, SoundCategory.BLOCKS, 1f, 1.05f);
        } else if (inserted <= 64) {
          world.playSound(null, pos, SoundRegistry.HANDLE_MANY, SoundCategory.BLOCKS, 1f, 1.05f);
        } else {
          world.playSound(null, pos, SoundRegistry.HANDLE_LOADS, SoundCategory.BLOCKS, 1f, 1.05f);
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
        return 0; // todo: if something goes wrong, remove this and see if things work lol
      BlockEntity be = world.getBlockEntity(cratePos);
      if (!(be instanceof CrateBlockEntity crate)) {
        // compatibleCrates.remove(cratePos); //TODO: Maybe Remove?
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

  private static int depositInventory(PlayerEntity player, CrateStationBlockEntity cdbe) {
    int inserted = 0;
    PlayerInventoryStorage invStorage = PlayerInventoryStorage.of(player);
    World world = cdbe.getWorld();

    for (int i = 0; i < player.getInventory().getMainStacks().size(); i++) {
      ItemStack stack = player.getInventory().getMainStacks().get(i);
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

  /**
   * Consolidates items of the same type across all connected crates.
   * Items are moved to the crate with the most items of that type.
   * 
   * @param cdbe The crate station block entity
   * @return true if any consolidation occurred, false otherwise
   */
  private static boolean consolidateItems(CrateStationBlockEntity cdbe) {
    World world = cdbe.getWorld();
    if (world == null || world.isClient)
      return false;

    Map<ItemVariant, List<BlockPos>> crateRegistry = cdbe.getCrateRegistry();
    if (crateRegistry.isEmpty())
      return false;

    boolean consolidated = false;

    // Process each item variant type
    for (Map.Entry<ItemVariant, List<BlockPos>> entry : crateRegistry.entrySet()) {
      ItemVariant variant = entry.getKey();
      List<BlockPos> cratePositions = new ArrayList<>(entry.getValue());

      if (cratePositions.size() <= 1)
        continue; // Only one crate with this item type, nothing to consolidate

      // Find the crate with the most items (target crate)
      BlockPos targetCratePos = null;
      long maxAmount = 0;

      for (BlockPos pos : cratePositions) {
        BlockEntity be = world.getBlockEntity(pos);
        if (!(be instanceof CrateBlockEntity crate))
          continue;

        long amount = crate.storage.getAmount();
        if (amount > maxAmount) {
          maxAmount = amount;
          targetCratePos = pos;
        }
      }

      if (targetCratePos == null)
        continue;

      BlockEntity targetBE = world.getBlockEntity(targetCratePos);
      if (!(targetBE instanceof CrateBlockEntity targetCrate))
        continue;

      // Transfer items from all other crates to the target crate
      for (BlockPos sourcePos : cratePositions) {
        if (sourcePos.equals(targetCratePos))
          continue; // Skip the target crate itself

        BlockEntity sourceBE = world.getBlockEntity(sourcePos);
        if (!(sourceBE instanceof CrateBlockEntity sourceCrate))
          continue;

        if (sourceCrate.storage.isBlank())
          continue;

        // Transfer all items from source to target
        try (Transaction transaction = Transaction.openOuter()) {
          long availableSpace = targetCrate.storage.getCapacity() - targetCrate.storage.getAmount();
          if (availableSpace <= 0)
            break; // Target crate is full

          long amountToTransfer = Math.min(sourceCrate.storage.getAmount(), availableSpace);
          if (amountToTransfer <= 0)
            continue;

          long extracted = sourceCrate.storage.extract(variant, amountToTransfer, transaction);
          if (extracted > 0) {
            long inserted = targetCrate.storage.insert(variant, extracted, transaction);
            if (inserted == extracted) {
              transaction.commit();
              sourceCrate.refresh();
              targetCrate.refresh();
              consolidated = true;
            } else {
              transaction.abort();
            }
          }
        }
      }
    }

    // Force cache update after consolidation
    if (consolidated) {
      cdbe.markCacheForUpdate();
    }

    return consolidated;
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
