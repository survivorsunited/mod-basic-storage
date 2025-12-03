# Shift-Click Crate Placement

The shift-click placement fix ensures that when you're holding a crate item and shift-clicking near a crate station, the crate will be placed as a block instead of being inserted into the station's network.

## The Problem (Before Fix)

Previously, when holding a crate item and shift-clicking near a crate station:

- The crate would be treated as an item to insert into the station network
- This prevented normal block placement
- You couldn't easily place crates next to stations

## The Solution

Now, when you shift-click with a crate item near a crate station:

- **Normal block placement occurs** - The crate is placed as a block
- **No network insertion** - The crate is not inserted into the station's item network
- **Standard Minecraft behavior** - Works like placing any other block

## How to Use

### Placing a Crate Near a Station

1. **Hold a crate item** in your main hand
2. **Sneak** (hold Shift)
3. **Right-click** on a block next to a crate station
4. The crate will be placed as a block normally

### What Happens

- The crate block is placed at the target location
- The crate station does not attempt to insert the crate into its network
- You can now easily build crate storage systems around stations

## Use Cases

### Building Storage Systems

When setting up a storage area with crate stations:

1. Place crate stations where you want them
2. Shift-click to place crates around the stations
3. Crates will automatically connect to nearby stations (within 16 blocks)
4. No need to worry about the station trying to "eat" your crate items

### Organizing Crates

When organizing your storage layout:

- Place crates in specific positions around stations
- Use shift-click to ensure proper placement
- Crates will connect to stations automatically based on proximity

## Technical Details

- The fix checks if you're holding a crate item and sneaking
- If both conditions are true, the interaction returns `PASS`
- This allows Minecraft's default block placement to handle the interaction
- The crate station's normal item insertion only happens when you're not trying to place a block

## Notes

- This only affects shift-clicking with crate items
- Normal item insertion into stations still works when not shift-clicking
- The fix applies to both empty crates and crates with items
- Once placed, crates will automatically connect to nearby stations if within range

## Tips

- Use shift-click when building storage systems to ensure proper crate placement
- This makes it easier to organize crates in specific patterns around stations
- Remember that placed crates will automatically connect to stations within 16 blocks
- Use this feature to create organized storage layouts without interference from the station

