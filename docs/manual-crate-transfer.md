# Manual Crate Transfer

The manual crate transfer feature allows you to directly transfer items between crates by holding one crate and clicking on another. This provides a quick way to move items without using a crate station.

## How It Works

When you hold a crate item and right-click on a placed crate block:

- **Empty crate in hand**: Transfers all items from the clicked crate into the crate you're holding
- **Crate with items in hand**: Dumps all items from the held crate into the clicked crate (if compatible)

The system automatically handles item type matching and provides audio feedback for successful or failed transfers.

## How to Use

### Transferring Items FROM a Crate (Empty Crate in Hand)

1. **Hold an empty crate** in your main hand
2. **Right-click** on a placed crate that contains items
3. All items from the clicked crate will be transferred to the crate in your hand

**Result**: The clicked crate becomes empty, and your held crate now contains all the items.

### Transferring Items TO a Crate (Crate with Items in Hand)

1. **Hold a crate with items** in your main hand
2. **Right-click** on a placed crate that is either:
   - Empty, OR
   - Contains the same item type
3. All items from your held crate will be transferred to the clicked crate

**Result**: Your held crate becomes empty (or reduced), and the clicked crate receives the items.

## Transfer Rules

### Successful Transfers

- **Empty crate → Crate with items**: Always works
- **Crate with items → Empty crate**: Always works
- **Crate with items → Crate with same item type**: Works, items are combined

### Failed Transfers

- **Crate with items → Crate with different item type**: Fails with error sound
- The error sound (`no_match`) plays to indicate the transfer cannot complete
- No items are moved when a transfer fails

## Example Scenarios

### Scenario 1: Moving Items to Inventory

You want to take items from a placed crate:

1. Hold an empty crate
2. Right-click the placed crate
3. The items are now in your held crate
4. You can place the crate elsewhere or break it to get the items

### Scenario 2: Combining Items

You have two crates with iron ingots and want to combine them:

1. Hold one crate with iron ingots
2. Right-click the other crate with iron ingots
3. All items are combined into the clicked crate
4. Your held crate becomes empty

### Scenario 3: Type Mismatch

You try to transfer diamonds into a crate with gold:

1. Hold a crate with diamonds
2. Right-click a crate with gold ingots
3. Error sound plays (`no_match`)
4. No items are moved
5. Both crates remain unchanged

## Audio Feedback

- **Successful transfer**: `handle_many` sound plays
- **Failed transfer**: `no_match` sound plays (different item types)

## Notes

- Manual transfers work independently of crate stations
- Transfers respect crate locking (see [Crate Locking](crate-locking.md))
- The transfer happens immediately in a single transaction
- If a transfer would exceed the crate's capacity, only what fits will be transferred
- This feature is useful for quick item organization without using a crate station

## Tips

- Use manual transfers for quick item movement between nearby crates
- Combine items from multiple crates before consolidating at a station
- Keep empty crates in your inventory for quick item pickup
- Use the error sound as feedback when item types don't match

