# Crate Locking

The crate locking feature allows you to protect crates from being completely emptied. When a crate is locked, it will always retain at least one item, preventing accidental complete extraction.

## How It Works

When a crate is locked:

- **Minimum item protection**: The crate will always keep at least 1 item, even if you try to extract all items
- **Extraction limit**: You can extract items up to (total - 1), but never the last item
- **Insertion works normally**: You can still add items to locked crates without restrictions
- **Persistent**: The lock state is saved with the crate and persists across world saves
- **Visual feedback**: You'll receive a message when locking or unlocking

## How to Use

### Locking a Crate

1. **Hold nothing** in your main hand (empty hand)
2. **Sneak** (hold Shift)
3. **Right-click on the back of the crate** (the side opposite the front face)

You'll see the message: "• Crate Locked •" and hear a confirmation sound.

### Unlocking a Crate

1. **Hold nothing** in your main hand (empty hand)
2. **Sneak** (hold Shift)
3. **Right-click on the back of the crate** (the side opposite the front face)

You'll see the message: "• Crate Unlocked •" and hear a confirmation sound.

## Example Scenarios

### Scenario 1: Protecting Important Items

You have a crate with 1,000 diamonds. You want to use them but don't want to accidentally empty the crate:

1. Lock the crate
2. Extract items as needed (up to 999)
3. The crate will always keep at least 1 diamond
4. When you're done, unlock it if you want full access

### Scenario 2: Preventing Accidental Emptying

You're sorting items and accidentally try to extract all items from a locked crate:

- **Without lock**: Crate becomes empty, you might lose track of what was stored
- **With lock**: Crate keeps 1 item, you can see what type was stored and refill it

## Technical Details

- Lock state is stored in the crate's block entity NBT data
- Locked crates are respected by:
  - Manual extraction (left-click)
  - Shift-click extraction
  - Item consolidation (items won't be extracted from locked crates if it would violate the lock)
  - Crate station operations
- The lock only prevents the last item from being extracted
- You can still add items to locked crates normally

## Notes

- Locking works on both empty and filled crates
- The lock state persists when the crate is broken and placed again (if using crate hammer)
- Locked empty crates will prevent items from being inserted until unlocked (if the extraction logic would leave 0 items)
- Use locking to protect valuable or important item storage

## Tips

- Lock crates containing rare or valuable items
- Use locking when you want to ensure a crate always shows what type of item it stores
- Lock multiple crates to create a "template" storage system
- Remember to unlock crates when you need full access

