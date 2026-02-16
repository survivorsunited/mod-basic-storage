package com.khazoda.basicstorage.block;

import com.khazoda.basicstorage.Constants;
import com.khazoda.basicstorage.block.entity.CrateBlockEntity;
import com.khazoda.basicstorage.registry.BlockRegistry;
import com.khazoda.basicstorage.registry.DataComponentRegistry;
import com.khazoda.basicstorage.registry.ItemRegistry;
import com.khazoda.basicstorage.registry.SoundRegistry;
import com.khazoda.basicstorage.storage.CrateSlot;
import com.khazoda.basicstorage.structure.CrateSlotComponent;
import com.khazoda.basicstorage.util.BlockUtils;
import com.khazoda.basicstorage.util.NumberFormatter;
import com.mojang.serialization.MapCodec;
import net.fabricmc.fabric.api.event.player.AttackBlockCallback;
import net.fabricmc.fabric.api.event.player.UseBlockCallback;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.fabricmc.fabric.api.transfer.v1.item.PlayerInventoryStorage;
import net.fabricmc.fabric.api.transfer.v1.storage.StorageUtil;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.block.Block;
import net.minecraft.block.BlockEntityProvider;
import net.minecraft.block.BlockState;
import net.minecraft.block.MapColor;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.enums.NoteBlockInstrument;
import net.minecraft.block.piston.PistonBehavior;
import net.minecraft.entity.ItemEntity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.ai.pathing.NavigationType;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemPlacementContext;
import net.minecraft.item.ItemStack;
import net.minecraft.loot.context.LootWorldContext;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.BlockSoundGroup;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.stat.Stats;
import net.minecraft.state.StateManager;
import net.minecraft.state.property.EnumProperty;
import net.minecraft.state.property.Properties;
import net.minecraft.text.Text;
import net.minecraft.util.*;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.world.World;
import net.minecraft.world.event.GameEvent;
import org.jetbrains.annotations.Nullable;

import java.util.List;
import java.util.Random;

import static com.khazoda.basicstorage.storage.CrateStationHelper.notifyNearbyStations;
import static java.lang.Math.toIntExact;

/**
 * Right Click
 * > holding valid stack - Add one item
 * > holding invalid stack / nothing - Display exact crate contents
 * Shift Right Click - Add all items from inventory that match
 * Left Click - Remove one item
 * Shift Left Click - Remove one stack
 */
public class CrateBlock extends Block implements BlockEntityProvider {
  public static final MapCodec<CrateBlock> CODEC = CrateBlock.createCodec(CrateBlock::new);
  public static final EnumProperty<Direction> FACING = Properties.HORIZONTAL_FACING;
  public static final Settings defaultSettings = Settings.create().sounds(BlockSoundGroup.WOOD).strength(2.5f)
      .pistonBehavior(PistonBehavior.BLOCK).instrument(NoteBlockInstrument.BASS).mapColor(MapColor.OAK_TAN);

  private static Random random;

  public CrateBlock(Settings settings) {
    super(settings);
    random = new Random();
    setDefaultState(this.stateManager.getDefaultState().with(FACING, Direction.NORTH));
  }

  public CrateBlock() {
    this(defaultSettings);
  }

  @Override
  public void onPlaced(World world, BlockPos pos, BlockState state, @Nullable LivingEntity placer,
                       ItemStack itemStack) {
    super.onPlaced(world, pos, state, placer, itemStack);
    notifyNearbyStations(world, pos);
    world.emitGameEvent(placer, GameEvent.BLOCK_PLACE, pos);
  }

  /**
   * Event hook for left-click (attack) to handle pulling items from crates
   */
  public static void initOnAttackMethod() {
    AttackBlockCallback.EVENT.register((PlayerEntity player, World world, Hand hand, BlockPos pos, Direction direction) -> {
      if (!world.getBlockState(pos).isOf(BlockRegistry.CRATE_BLOCK))
        return ActionResult.PASS;
      if (!player.canModifyBlocks() || player.isSpectator())
        return ActionResult.PASS;

      BlockState state = world.getBlockState(pos);
      BlockEntity be = world.getBlockEntity(pos);
      Direction facing = state.get(Properties.HORIZONTAL_FACING);

      if (be == null)
        return ActionResult.PASS;
      if (facing != direction)
        return ActionResult.PASS;

      CrateBlockEntity cbe = (CrateBlockEntity) be;
      ItemStack playerStack = player.getMainHandStack();
      if (playerStack.isOf(ItemRegistry.CRATE_HAMMER_ITEM))
        return ActionResult.PASS;

      // Manual crate transfer: Pull items (Shift+Sneak+Left Click)
      if (player.isSneaking() && playerStack.isOf(BlockRegistry.CRATE_BLOCK.asItem())) {
        // Split so only one crate gets filled. If no room in inventory, grab one, fill it, drop it.
        // Must insert rest into slots OTHER than selected, or insertStack merges back into hand and whole stack gets filled (dupe).
        int stackCount = playerStack.getCount();
        ItemStack singleCrateStack = playerStack.copy();
        singleCrateStack.setCount(1);
        boolean fillOneAndDrop = false;
        if (stackCount > 1) {
          ItemStack restOfStack = playerStack.copy();
          restOfStack.setCount(stackCount - 1);
          player.setStackInHand(hand, singleCrateStack);
          if (!insertStackExcludingSelectedSlot(player, restOfStack)) {
            fillOneAndDrop = true;
            player.setStackInHand(hand, restOfStack);
          }
        } else {
          singleCrateStack = player.getStackInHand(hand);
        }
        
        BlockHitResult hit = new BlockHitResult(
            net.minecraft.util.math.Vec3d.ofCenter(pos), direction, pos, false);
        ActionResult transferResult = handleManualCrateTransfer(player, singleCrateStack, cbe, false, world, pos, state);
        
        if (transferResult == ActionResult.SUCCESS) {
          if (fillOneAndDrop) {
            ItemEntity itemEntity = new ItemEntity(
                world, player.getX(), player.getY(), player.getZ(), singleCrateStack);
            itemEntity.setPickupDelay(40);
            world.spawnEntity(itemEntity);
          }
          return ActionResult.SUCCESS; // Prevent block breaking
        }
        if (fillOneAndDrop) {
          // Transfer failed; put the one crate back (inventory or drop)
          if (!player.getInventory().insertStack(singleCrateStack)) {
            ItemEntity itemEntity = new ItemEntity(
                world, player.getX(), player.getY(), player.getZ(), singleCrateStack);
            itemEntity.setPickupDelay(40);
            world.spawnEntity(itemEntity);
          }
        }
        if (transferResult != ActionResult.PASS) {
          return ActionResult.SUCCESS; // Prevent block breaking
        }
      }

      return ActionResult.PASS;
    });
  }

  /**
   * Event hook instead of onUse() method in order to capture interactions while
   * sneaking
   */
  public static void initOnUseMethod() {
    /*
     * Method is fired on every block right click, so immediate check for crate
     * block class is needed
     */
    UseBlockCallback.EVENT.register((PlayerEntity player, World world, Hand hand, BlockHitResult hit) -> {
      if (!world.getBlockState(hit.getBlockPos()).isOf(BlockRegistry.CRATE_BLOCK))
        return ActionResult.PASS;
      if (!player.canModifyBlocks() || player.isSpectator())
        return ActionResult.PASS;

      BlockPos pos = hit.getBlockPos();
      BlockState state = world.getBlockState(pos);
      BlockEntity be = world.getBlockEntity(pos);
      Direction facing = state.get(Properties.HORIZONTAL_FACING);

      if (be == null)
        return ActionResult.PASS;
      if (facing != hit.getSide())
        return ActionResult.PASS;

      CrateBlockEntity cbe = (CrateBlockEntity) be;
      ItemStack playerStack = player.getMainHandStack();
      if (playerStack.isOf(ItemRegistry.CRATE_HAMMER_ITEM))
        return ActionResult.PASS;
      CrateSlot slot = cbe.storage;

      // Todo: Enable for debugging
      // if (playerStack.isOf(net.minecraft.item.Items.DEBUG_STICK)) return debugInitOnUseMethod(player, slot);

      // Manual crate transfer: Push items (Shift+Sneak+Right Click) — only when held crates have contents
      // If holding empty crates, fall through so they are inserted into the block as items
      boolean isCrateWithContents = playerStack.isOf(BlockRegistry.CRATE_BLOCK.asItem()) && hasCrateContents(playerStack);
      if (player.isSneaking() && playerStack.isOf(BlockRegistry.CRATE_BLOCK.asItem()) && isCrateWithContents) {
        // Shift+Sneak+Right Click: Transfer from held crate(s) to clicked crate
        // Process each crate in the stack one by one
        int stackCount = playerStack.getCount();
        boolean anyTransfer = false;
        
        for (int i = 0; i < stackCount; i++) {
          // Get current stack state (may have been modified by previous iterations)
          ItemStack currentCrateStack = player.getStackInHand(hand);
          if (currentCrateStack.isEmpty() || !currentCrateStack.isOf(BlockRegistry.CRATE_BLOCK.asItem())) {
            break; // No more crates to process
          }
          
          // Check if clicked crate is full before processing
          if (cbe.storage.getAmount() >= cbe.storage.getCapacity()) {
            break; // Clicked crate is full, stop processing
          }
          
          // Create a single crate stack for processing (copy the first crate's data)
          ItemStack singleCrateStack = currentCrateStack.copy();
          singleCrateStack.setCount(1);
          
          // Check if this crate has items to transfer
          var originalContents = singleCrateStack.get(DataComponentRegistry.CRATE_CONTENTS);
          boolean wasEmpty = (originalContents == null || originalContents.item().isBlank() || originalContents.count() == 0);
          
          if (wasEmpty) {
            // Skip empty crates - remove one from stack and continue
            currentCrateStack.decrement(1);
            if (currentCrateStack.isEmpty()) {
              player.setStackInHand(hand, ItemStack.EMPTY);
              break;
            } else {
              player.setStackInHand(hand, currentCrateStack);
            }
            continue;
          }
          
          // Try to push items from this crate
          ActionResult transferResult = handleManualCrateTransfer(player, singleCrateStack, cbe, true, world, pos, state);
          
          // SUCCESS = transfer succeeded; apply updated crate back to player hand to avoid duping
          if (transferResult == ActionResult.SUCCESS || transferResult == ActionResult.CONSUME) {
            // Transfer happened
            anyTransfer = true;
            
            // Check if this crate is now empty
            var newContents = singleCrateStack.get(DataComponentRegistry.CRATE_CONTENTS);
            boolean isEmpty = (newContents == null || newContents.item().isBlank() || newContents.count() == 0);
            
            if (isEmpty) {
              // Crate is now empty
              if (currentCrateStack.getCount() == 1) {
                // Single crate: keep the empty crate in hand
                player.setStackInHand(hand, singleCrateStack);
                break;
              }
              currentCrateStack.decrement(1);
              if (currentCrateStack.isEmpty()) {
                player.setStackInHand(hand, ItemStack.EMPTY);
                break; // Stack is empty, stop processing
              } else {
                player.setStackInHand(hand, currentCrateStack);
              }
            } else {
              // Crate still has items - need to update it
              if (currentCrateStack.getCount() == 1) {
                // Only one crate, update it directly
                player.setStackInHand(hand, singleCrateStack);
                break; // Done processing
              } else {
                // Multiple crates: remove one from stack, then add updated crate back to inventory
                currentCrateStack.decrement(1);
                player.setStackInHand(hand, currentCrateStack);
                
                // Try to add the updated crate back to inventory or drop it
                if (!player.getInventory().insertStack(singleCrateStack)) {
                  // Inventory full, drop the updated crate
                  ItemEntity itemEntity = new ItemEntity(
                      world, player.getX(), player.getY(), player.getZ(), singleCrateStack);
                  itemEntity.setPickupDelay(40);
                  world.spawnEntity(itemEntity);
                }
                // Continue processing next crate in the stack
              }
            }
          } else if (transferResult == ActionResult.FAIL) {
            // Incompatible items or other failure - stop processing this stack
            break;
          }
        }
        
        if (anyTransfer) {
          return ActionResult.CONSUME;
        }
        // If no transfer happened, fall through to normal behavior
      }

      try (var t = Transaction.openOuter()) {
        int inserted = 0;
        if (player.isSneaking()) {
          if (!canInsert(playerStack, slot, true))
            return listExactContents(player, slot);
          inserted = insertMaximum(player, playerStack, slot, t);
        } else if (!player.isSneaking()) {
          if (!canInsert(playerStack, slot, false))
            return listExactContents(player, slot);
          inserted = insertOne(playerStack, slot, t);
        }

        if (inserted == 0) {
          t.abort();
          return ActionResult.CONSUME;
        }

        t.commit();
        if (inserted == 1)
          world.playSound(null, pos, SoundRegistry.HANDLE_ONE, SoundCategory.BLOCKS, 1f, 1f + ((-0.5f + random.nextFloat() * (1 + 0.5f)) / 10));
        if (inserted > 1)
          world.playSound(null, pos, SoundRegistry.HANDLE_MANY, SoundCategory.BLOCKS, 1f, 1f);
        state.updateNeighbors(world, pos, 1);
        cbe.refresh();
        world.updateComparators(pos, state.getBlock());
        player.incrementStat(Stats.USED.getOrCreateStat(playerStack.getItem()));
        world.emitGameEvent(player, GameEvent.BLOCK_CHANGE, pos);
        return ActionResult.SUCCESS;
      }
    });
  }

  /**
   * Inserts stack into player inventory without using the selected hotbar slot.
   * Used when we have 1 crate in hand and need to put the rest elsewhere so insertStack doesn't merge them back (dupe).
   * @return true if the entire stack was inserted, false if some or all could not fit
   */
  private static boolean insertStackExcludingSelectedSlot(PlayerEntity player, ItemStack stack) {
    if (stack.isEmpty())
      return true;
    var inv = player.getInventory();
    int selected = inv.getSelectedSlot();
    int maxStack = stack.getMaxCount();
    for (int i = 0; i < 36 && !stack.isEmpty(); i++) {
      if (i == selected)
        continue;
      ItemStack inSlot = inv.getStack(i);
      if (inSlot.isEmpty()) {
        int move = Math.min(stack.getCount(), maxStack);
        ItemStack toPut = stack.copy();
        toPut.setCount(move);
        inv.setStack(i, toPut);
        stack.decrement(move);
      } else if (ItemStack.areItemsAndComponentsEqual(stack, inSlot) && inSlot.getCount() < maxStack) {
        int move = Math.min(stack.getCount(), maxStack - inSlot.getCount());
        inSlot.increment(move);
        stack.decrement(move);
      }
    }
    return stack.isEmpty();
  }

  /**
   * UseBlockCallback helper method
   **/
  private static int insertOne(ItemStack playerStack, CrateSlot slot, Transaction t) {
    /* Insert one item into crate, if matching player's active held stack */
    if (playerStack.isEmpty())
      return 0;
    int inserted = (int) slot.insert(ItemVariant.of(playerStack), 1, t);
    playerStack.decrement(inserted);
    return inserted;
  }

  /**
   * UseBlockCallback helper method
   **/
  private static int insertMaximum(PlayerEntity player, ItemStack playerStack, CrateSlot slot,
                                   Transaction transaction) {
    /*
     * Insert as many items as possible from player's inventory if slot is empty, or
     * matches held stack
     */
    if (slot.isBlank() && playerStack.isEmpty()) {
      return 0;
    } else if (slot.isBlank() && !playerStack.isEmpty()) {
      /* Insert into empty crate */
      int i = (int) slot.insert(ItemVariant.of(playerStack), playerStack.getCount(), transaction);
      playerStack.decrement(i);
      return i;
    } else {
      /* Insert into crate with items */
      return (int) StorageUtil.move(PlayerInventoryStorage.of(player), slot, itemVariant -> true, Integer.MAX_VALUE,
          transaction);
    }
  }

  /**
   * UseBlockCallback helper method
   **/
  private static ActionResult listExactContents(PlayerEntity player, CrateSlot slot) {
    /* Show exact contents of crate to play via message */
    Text message;
    if (slot.isBlank()) {
      message = Text.translatable("message.basicstorage.crate.empty").withColor(0xFFDD99);
    } else {
      message = Text.literal(NumberFormatter.toFormattedNumber(slot.getAmount()) + " "
          + slot.getResource().getItem().getName().getString()).withColor(0xFFDD99);
    }
    player.sendMessage(message, true);
    return ActionResult.CONSUME;
  }

  /**
   * Handles manual crate transfer when holding a crate item and clicking another crate.
   * Shift+Sneak+Left Click: Transfer from clicked crate to held crate (pull)
   * Shift+Sneak+Right Click: Transfer from held crate to clicked crate (push)
   * 
   * @param player The player performing the transfer
   * @param heldCrateStack The crate item stack being held
   * @param clickedCrate The crate block entity being clicked
   * @param isPush True for push (right-click), false for pull (left-click)
   * @param world The world
   * @param pos The position of the clicked crate
   * @param state The block state
   * @return ActionResult indicating success or failure
   */
  private static ActionResult handleManualCrateTransfer(PlayerEntity player, ItemStack heldCrateStack, 
                                                         CrateBlockEntity clickedCrate, boolean isPush,
                                                         World world, BlockPos pos, BlockState state) {
    if (world.isClient())
      return ActionResult.PASS;
    
    // Get contents of held crate
    var heldContents = heldCrateStack.get(DataComponentRegistry.CRATE_CONTENTS);
    if (heldContents == null) {
      heldContents = CrateSlotComponent.DEFAULT;
    }

    ItemVariant heldItem = heldContents.item();
    long heldAmount = heldContents.count();
    boolean heldEmpty = heldItem.isBlank() || heldAmount == 0;

    // Get contents of clicked crate
    ItemVariant clickedItem = clickedCrate.storage.getResource();
    long clickedAmount = clickedCrate.storage.getAmount();
    boolean clickedEmpty = clickedCrate.storage.isBlank();

    // Validate compatibility: same item type or one side is empty
    if (!heldEmpty && !clickedEmpty && !heldItem.equals(clickedItem)) {
      // Different item types and neither is empty - cannot transfer
      if (!world.isClient()) {
        player.sendMessage(
            Text.translatable("message.basicstorage.crate.transfer_incompatible").withColor(0xFF9999),
            true);
        world.playSound(null, pos, SoundRegistry.NO_MATCH, SoundCategory.BLOCKS, 1.1f, 1f);
      }
      return ActionResult.CONSUME;
    }

    // Determine which item type to use
    ItemVariant transferItem = heldEmpty ? clickedItem : heldItem;
    if (transferItem.isBlank()) {
      // Both crates are empty
      return ActionResult.PASS;
    }

    long transferred = 0;

    if (isPush) {
      // Shift+Sneak+Right Click: Transfer from held crate to clicked crate
      if (heldEmpty) {
        return ActionResult.PASS; // Nothing to transfer
      }

      try (Transaction transaction = Transaction.openOuter()) {
        long availableSpace = clickedCrate.storage.getCapacity() - clickedCrate.storage.getAmount();
        long amountToTransfer = Math.min(heldAmount, availableSpace);
        
        if (amountToTransfer > 0) {
          long inserted = clickedCrate.storage.insert(heldItem, amountToTransfer, transaction);
          if (inserted > 0) {
            transaction.commit();
            transferred = inserted;
            
            // Update held crate item
            long newHeldAmount = heldAmount - transferred;
            if (newHeldAmount > 0) {
              heldCrateStack.set(DataComponentRegistry.CRATE_CONTENTS, 
                  new CrateSlotComponent(heldItem, (int) newHeldAmount));
            } else {
              heldCrateStack.remove(DataComponentRegistry.CRATE_CONTENTS);
            }
            
            clickedCrate.refresh();
          } else {
            transaction.abort();
          }
        }
      }
    } else {
      // Shift+Sneak+Left Click: Transfer from clicked crate to held crate
      if (clickedEmpty) {
        return ActionResult.PASS; // Nothing to transfer
      }

      // Calculate available space in held crate
      // Note: Stack splitting happens BEFORE this function is called, so heldCrateStack should be count 1
      long heldCapacity = Constants.CRATE_MAX_COUNT;
      long heldCurrentAmount = heldEmpty ? 0 : heldAmount;
      long availableSpace = heldCapacity - heldCurrentAmount;

      if (availableSpace <= 0) {
        // Held crate is full
        if (!world.isClient()) {
          player.sendMessage(
              Text.translatable("message.basicstorage.crate.transfer_full").withColor(0xFF9999),
              true);
          world.playSound(null, pos, SoundRegistry.NO_MATCH, SoundCategory.BLOCKS, 1.1f, 1f);
        }
        return ActionResult.CONSUME;
      }

      try (Transaction transaction = Transaction.openOuter()) {
        long amountToTransfer = Math.min(clickedAmount, availableSpace);
        long extracted = clickedCrate.storage.extract(clickedItem, amountToTransfer, transaction);
        
        if (extracted > 0) {
          transaction.commit();
          transferred = extracted;
          
          // Update held crate item
          long newHeldAmount = heldCurrentAmount + transferred;
          heldCrateStack.set(DataComponentRegistry.CRATE_CONTENTS, 
              new CrateSlotComponent(clickedItem, (int) newHeldAmount));
          
          clickedCrate.refresh();
        } else {
          // Transfer failed
          transaction.abort();
        }
      }
    }

    if (transferred > 0) {
      // Success feedback
      if (!world.isClient()) {
        if (transferred == 1) {
          world.playSound(null, pos, SoundRegistry.HANDLE_ONE, SoundCategory.BLOCKS, 1f, 1.05f);
        } else if (transferred <= 64) {
          world.playSound(null, pos, SoundRegistry.HANDLE_MANY, SoundCategory.BLOCKS, 1f, 1.05f);
        } else {
          world.playSound(null, pos, SoundRegistry.HANDLE_LOADS, SoundCategory.BLOCKS, 1f, 1.05f);
        }
        state.updateNeighbors(world, pos, 1);
        world.updateComparators(pos, state.getBlock());
        world.emitGameEvent(player, GameEvent.BLOCK_CHANGE, pos);
      }
      return ActionResult.SUCCESS;
    }

    return ActionResult.PASS;
  }

  /** True if the stack is a crate item with non-empty contents (used to decide push vs insert). */
  private static boolean hasCrateContents(ItemStack stack) {
    var contents = stack.get(DataComponentRegistry.CRATE_CONTENTS);
    return contents != null && !contents.item().isBlank() && contents.count() > 0;
  }

  /**
   * UseBlockCallback helper method
   **/
  /* Add blacklisted items to this method */
  /* Stop them being inserted into crates */
  public static boolean canInsert(ItemStack stack, CrateSlot slot, boolean insertingMultiple) {
    if (insertingMultiple) {
      return !slot.isBlank() || canInsert(stack, slot, false); // Prevents stacked undesirables from being insertable
      // when sneaking
      // This is ok as another check is done when actually inserting the items in
      // CrateSlot#insert
    } else {
      if (stack.isEmpty())
        return false;
      if (stack.isDamaged())
        return false;
      // Block only filled crates; empty crates can be stored in the block
      if (stack.isOf(BlockRegistry.CRATE_BLOCK.asItem()) && hasCrateContents(stack))
        return false;
      if (!ItemVariant.of(stack).equals(slot.getResource()) && !slot.isBlank())
        return false;
      return slot.isBlank() || stack.isOf(slot.getResource().getItem());
    }
  }

  /**
   * Method for removing either 1 item or a whole stack of items from a crate
   */
  @Override
  protected void onBlockBreakStart(BlockState state, World world, BlockPos pos, PlayerEntity player) {
    if (!player.canModifyBlocks())
      return;

    // Skip normal extraction if player is doing manual crate transfer
    ItemStack playerStack = player.getMainHandStack();
    if (player.isSneaking() && playerStack.isOf(BlockRegistry.CRATE_BLOCK.asItem())) {
      return; // Manual transfer is handled by AttackBlockCallback
    }

    CrateBlockEntity cbe = (CrateBlockEntity) world.getBlockEntity(pos);
    if (cbe == null)
      return;
    if (cbe.storage.isBlank())
      return;

    var hit = BlockUtils.getHitResult(player, pos);
    if (hit.getType() == HitResult.Type.MISS)
      return;

    Direction facing = state.get(Properties.HORIZONTAL_FACING);
    if (facing != hit.getSide())
      return;

    try (var t = Transaction.openOuter()) {
      var item = cbe.storage.getResource();
      var extracted = (int) cbe.storage.extract(item, player.isSneaking() ? item.getItem().getMaxCount() : 1, t);
      if (extracted == 0) {
        t.abort();
        return;
      }
      player.getInventory().offerOrDrop(item.toStack(extracted));
      t.commit();

      if (extracted == 1)
        world.playSound(null, pos, SoundRegistry.HANDLE_ONE, SoundCategory.BLOCKS, 0.6f,
            1.2f + ((-1 + random.nextFloat() * (1 + 1)) / 10));
      if (extracted > 1)
        world.playSound(null, pos, SoundRegistry.HANDLE_ONE, SoundCategory.BLOCKS, 0.75f, 1f);
      world.playSound(null, pos, SoundEvents.ENTITY_ITEM_PICKUP, SoundCategory.BLOCKS, 0.35f, 1f);

    }
    cbe.refresh();
    state.updateNeighbors(world, pos, 1);
    world.updateComparators(pos, state.getBlock());
    world.emitGameEvent(player, GameEvent.BLOCK_CHANGE, pos);
  }

  /**
   * Handles breaking in creative mode
   */
  @Override
  public BlockState onBreak(World world, BlockPos pos, BlockState state, PlayerEntity player) {
    BlockEntity be = world.getBlockEntity(pos);
    if (!(be == null)) {
      CrateBlockEntity cbe = (CrateBlockEntity) be;
      if (!world.isClient() && player.isCreative() && !cbe.storage.getResource().toStack().isEmpty()) {
        getDroppedStacks(state, (ServerWorld) world, pos, cbe, player, player.getStackInHand(Hand.MAIN_HAND))
            .forEach(stack -> ItemScatterer.spawn(world, pos.getX(), pos.getY(), pos.getZ(), stack));
      }
    }
    return super.onBreak(world, pos, state, player);
  }

  @Override
  protected List<ItemStack> getDroppedStacks(BlockState state, LootWorldContext.Builder builder) {
    return super.getDroppedStacks(state, builder);
  }

  public static Direction getFront(BlockState state) {
    return state.get(FACING);
  }

  @Override
  protected void appendProperties(StateManager.Builder<Block, BlockState> builder) {
    builder.add(FACING);
  }

  @Override
  protected boolean canPathfindThrough(BlockState state, NavigationType type) {
    return false;
  }

  @Nullable
  @Override
  public BlockEntity createBlockEntity(BlockPos pos, BlockState state) {
    return new CrateBlockEntity(pos, state);
  }

  @Nullable
  @Override
  public BlockState getPlacementState(ItemPlacementContext ctx) {
    return this.getDefaultState().with(Properties.HORIZONTAL_FACING, ctx.getHorizontalPlayerFacing().getOpposite());
  }

  @Override
  protected void onStateReplaced(BlockState state, ServerWorld world, BlockPos pos, boolean moved) {
    BlockEntity blockEntity = world.getBlockEntity(pos);
    if (blockEntity instanceof CrateBlockEntity) {
      world.updateComparators(pos, state.getBlock());
      notifyNearbyStations(world, pos);
      world.emitGameEvent(null, GameEvent.BLOCK_DESTROY, pos);
    }
    super.onStateReplaced(state, world, pos, moved);
  }

  @Override
  protected BlockState rotate(BlockState state, BlockRotation rotation) {
    return state.with(FACING, rotation.rotate(state.get(FACING)));
  }

  @Override
  protected BlockState mirror(BlockState state, BlockMirror mirror) {
    return state.rotate(mirror.getRotation(state.get(FACING)));
  }

  @Override
  public boolean hasComparatorOutput(BlockState state) {
    return true;
  }

  /**
   * Comparator Logic
   * 1-16 items = signal strength, loops to 1 billion
   */
  @Override
  public int getComparatorOutput(BlockState state, World world, BlockPos pos) {
    BlockEntity be = world.getBlockEntity(pos);
    if (be instanceof CrateBlockEntity cbe) {
      return BlockUtils.getComparatorOutputStrength(toIntExact(cbe.storage.getAmount()));
    } else {
      return 0;
    }
  }

  @Override
  public MapCodec<CrateBlock> getCodec() {
    return CODEC;
  }

  /**
   * Debugging Methods, not for survival gameplay use
   */

  private static ActionResult debugInitOnUseMethod(PlayerEntity player, CrateSlot slot) {
    try (Transaction t = Transaction.openOuter()) {
      if (slot.isBlank())
        return ActionResult.PASS;
      if (player.isSneaking())
        slot.extract(slot.getResource(), 10000, t);
      if (!player.isSneaking())
        slot.insert(slot.getResource(), 100000, t);
      t.commit();
    }
    slot.update();
    return ActionResult.SUCCESS;
  }
}