package com.khazoda.basicstorage.block.entity;

import com.khazoda.basicstorage.registry.BlockEntityRegistry;
import com.khazoda.basicstorage.registry.DataComponentRegistry;
import com.khazoda.basicstorage.storage.CrateSlot;
import com.khazoda.basicstorage.structure.CrateSlotComponent;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.block.Block;
import net.minecraft.block.BlockState;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.component.ComponentMap;
import net.minecraft.component.ComponentsAccess;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.network.packet.s2c.play.BlockEntityUpdateS2CPacket;
import net.minecraft.registry.RegistryWrapper;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.storage.ReadView;
import net.minecraft.storage.WriteView;
import net.minecraft.util.math.BlockPos;

public class CrateBlockEntity extends BlockEntity {
  public final CrateSlot storage = new CrateSlot(this);
  private boolean locked = false;

  /**
   * Constructor
   **/
  public CrateBlockEntity(BlockPos pos, BlockState state) {
    super(BlockEntityRegistry.CRATE_BLOCK_ENTITY, pos, state);
  }

  /**
   * modified markDirty() method
   */
  public void refresh() {
    if (world instanceof ServerWorld) {
      markDirty();
      var state = getCachedState();
      world.updateListeners(pos, state, state, Block.NOTIFY_LISTENERS);
      world.updateComparators(pos, state.getBlock());
    }
  }

  /**
   * Persist block entity data in Minecraft 1.21.11's data view format.
   **/
  @Override
  protected void writeData(WriteView view) {
    super.writeData(view);
    view.put("crateStack", CrateSlotComponent.CODEC, storage.toComponent());
    view.putBoolean("locked", locked);
  }

  @Override
  protected void readData(ReadView view) {
    super.readData(view);
    view.read("crateStack", CrateSlotComponent.CODEC).ifPresent(storage::readComponent);
    locked = view.getBoolean("locked", false);
  }

  /**
   * Block Entity Boilerplate
   */
  @Override
  public NbtCompound toInitialChunkDataNbt(RegistryWrapper.WrapperLookup registryLookup) {
    return createNbt(registryLookup);
  }

  @Override
  public BlockEntityUpdateS2CPacket toUpdatePacket() {
    return BlockEntityUpdateS2CPacket.create(this);
  }

  /**
   * Data to save and read from ItemStack versions of crate
   */
  @Override
  protected void addComponents(ComponentMap.Builder componentMapBuilder) {
    if (this.storage.isBlank())
      return;
    componentMapBuilder
        .add(DataComponentRegistry.CRATE_CONTENTS,
            new CrateSlotComponent(
                this.storage.getResource(),
                (int) this.storage.getAmount()));
  }

  @Override
  protected void readComponents(ComponentsAccess components) {
    CrateSlotComponent contents = components.getOrDefault(DataComponentRegistry.CRATE_CONTENTS,
        CrateSlotComponent.DEFAULT);
    if (contents == null || contents.count() == 0)
      return;
    try (Transaction t = Transaction.openOuter()) {
      if (!this.storage.isBlank())
        return; // Prevents creative block pick from duping items
      this.storage.insert(contents.item(), contents.count(), t);
      t.commit();
    }
    this.refresh();
  }

  public boolean isLocked() {
    return locked;
  }

  public void setLocked(boolean locked) {
    this.locked = locked;
    this.refresh();
    markDirty();
  }
}
