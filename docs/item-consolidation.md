# Item Consolidation

The item consolidation feature allows you to automatically organize items across all crates connected to a crate station. This feature scans all connected crates, identifies items of the same type, and consolidates them into the crate that contains the most items of that type.

## How It Works

When you trigger consolidation on a crate station, the system:

1. **Scans all connected crates** within the station's network (16 block radius)
2. **Groups items by type** - Identifies all crates containing the same item type
3. **Finds the largest crate** - For each item type, determines which crate has the most items
4. **Moves items** - Transfers all items of the same type from smaller crates into the largest crate
5. **Preserves locked crates** - Locked crates are respected during consolidation (items won't be extracted from locked crates if it would violate the lock)

## How to Use

### Triggering Consolidation

1. **Stand near a crate station** that has connected crates
2. **Hold nothing** in your main hand (empty hand)
3. **Sneak** (hold Shift)
4. **Right-click** on the crate station

### Result

- You'll see a message: "• Items Consolidated •"
- A sound will play indicating the consolidation is complete
- All items of the same type will now be in the crate with the largest amount

## Example

**Before Consolidation:**
- Crate A: 500 Iron Ingots
- Crate B: 1,200 Iron Ingots
- Crate C: 300 Iron Ingots
- Crate D: 50 Gold Ingots

**After Consolidation:**
- Crate A: Empty
- Crate B: 2,000 Iron Ingots (all iron consolidated here)
- Crate C: Empty
- Crate D: 50 Gold Ingots (unchanged, only one crate with gold)

## Notes

- Consolidation only affects crates within 16 blocks of the crate station
- Items are moved in transactions, so if a transfer fails, it won't partially complete
- The crate station cache is automatically updated after consolidation
- This feature works with all item types stored in crates
- Consolidation respects crate locking (see [Crate Locking](crate-locking.md))

## Tips

- Use consolidation regularly to keep your storage organized
- Consolidate before large storage operations to maximize available space
- Multiple item types are consolidated in a single operation
- The process is safe and won't lose items if something goes wrong

