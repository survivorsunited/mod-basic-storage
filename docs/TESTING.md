# Basic Storage Mod - Testing Guide

## Main Features Overview

The Basic Storage mod provides vanilla-friendly mass item storage through crates and crate stations. Here are the main features and how to test them:

## Core Features

### 1. **Crates** - Mass Item Storage
- **What it does**: Stores up to 1 billion items of a single type in a compact block
- **How to test**:
  1. Craft a crate (recipe: planks + sticks)
  2. Place the crate
  3. Right-click the front face while holding items
  4. Items are inserted one at a time
  5. Shift + Right-click to insert all matching items from inventory
  6. Left-click to extract one item
  7. Shift + Left-click to extract one stack

### 2. **Crate Stations** - Storage Management Interface
- **What it does**: Manages multiple crates within 16 blocks, provides GUI for item transfer
- **How to test**:
  1. Craft a crate station (recipe: planks + redstone + ender eye + hopper + sticks)
  2. Place the crate station
  3. Place crates within 16 blocks of the station
  4. Right-click the station to open GUI
  5. Transfer items between inventory and connected crates
  6. Shift + Right-click to deposit all matching items from inventory

### 3. **Crate Hammer** - Safe Crate Breaking
- **What it does**: Breaks crates without losing stored items (items stay in the crate item)
- **How to test**:
  1. Craft a crate hammer (recipe: copper ingots + stick)
  2. Fill a crate with items
  3. Use the hammer to break the crate
  4. Pick up the crate item - it should contain all the stored items
  5. Place the crate again - items should still be there

## Advanced Features

### 4. **Item Consolidation** ⭐
- **What it does**: Automatically organizes items across all connected crates, consolidating same-type items into the largest crate
- **How to test**:
  1. Set up a crate station with multiple crates nearby (within 16 blocks)
  2. Fill different crates with the same item type (e.g., iron ingots in 3 different crates)
  3. Stand near the crate station
  4. **Hold nothing** in your main hand
  5. **Sneak** (hold Shift)
  6. **Right-click** on the crate station
  7. You should see: "• Items Consolidated •"
  8. All items of the same type should now be in the crate with the most items
- **Documentation**: See [item-consolidation.md](item-consolidation.md)

### 5. **Crate Locking** ⭐
- **What it does**: Protects crates from being completely emptied - always keeps at least 1 item
- **How to test**:
  1. Fill a crate with items (e.g., 100 diamonds)
  2. **Hold nothing** in your main hand
  3. **Sneak** (hold Shift)
  4. **Right-click on the BACK of the crate** (opposite side from the front face)
  5. You should see: "• Crate Locked •"
  6. Try to extract all items - it should stop at 1 item remaining
  7. To unlock: Repeat steps 2-4
- **Documentation**: See [crate-locking.md](crate-locking.md)

### 6. **Manual Crate Transfer** ⭐
- **What it does**: Directly transfer items between crates by holding one crate and clicking another
- **How to test**:
  - **Test 1 - Empty crate → Filled crate**:
    1. Hold an empty crate
    2. Right-click a placed crate with items
    3. All items transfer to your held crate
  - **Test 2 - Filled crate → Empty crate**:
    1. Hold a crate with items
    2. Right-click an empty placed crate
    3. All items transfer to the placed crate
  - **Test 3 - Same item type**:
    1. Hold a crate with iron ingots
    2. Right-click a placed crate with iron ingots
    3. Items combine successfully
  - **Test 4 - Different item types** (should fail):
    1. Hold a crate with diamonds
    2. Right-click a placed crate with gold
    3. Error sound plays, no transfer occurs
- **Documentation**: See [manual-crate-transfer.md](manual-crate-transfer.md)

### 7. **Shift-Click Placement** ⭐
- **What it does**: Place crates as blocks near crate stations without them being inserted into the network
- **How to test**:
  1. Place a crate station
  2. Hold a crate item
  3. **Sneak** (hold Shift)
  4. **Right-click** on a block next to the station
  5. Crate should place as a block (not be inserted into station)
  6. The placed crate will still connect to the station automatically (within 16 blocks)
- **Documentation**: See [shift-click-placement.md](shift-click-placement.md)

## Quick Testing Checklist

### Basic Functionality
- [ ] Craft a crate
- [ ] Place a crate
- [ ] Insert items into crate (right-click)
- [ ] Extract items from crate (left-click)
- [ ] Shift + Right-click to insert all matching items
- [ ] Shift + Left-click to extract one stack

### Crate Station
- [ ] Craft a crate station
- [ ] Place crate station
- [ ] Place crates within 16 blocks
- [ ] Right-click station to open GUI
- [ ] Transfer items via GUI
- [ ] Shift + Right-click to deposit all matching items

### Crate Hammer
- [ ] Craft a crate hammer
- [ ] Fill a crate with items
- [ ] Break crate with hammer
- [ ] Verify items are preserved in crate item
- [ ] Place crate again - verify items still there

### Advanced Features
- [ ] **Item Consolidation**: Sneak + Empty Hand + Right-click station
- [ ] **Crate Locking**: Sneak + Empty Hand + Right-click crate back
- [ ] **Manual Transfer**: Hold crate + Right-click another crate
- [ ] **Shift-Click Placement**: Shift + Right-click with crate item near station

## Testing in Creative Mode

### Quick Setup
1. Start a test server: `.\build.ps1 -StartServer -MinecraftVersion "1.21.8"`
2. Connect with a client
3. Switch to creative mode
4. Get items from creative inventory:
   - Crate
   - Crate Station
   - Crate Hammer
   - Various items to test storage

### Test Scenarios

#### Scenario 1: Basic Storage
1. Place 3 crates
2. Fill each with different items (iron, gold, diamonds)
3. Verify each crate stores items correctly
4. Test extraction

#### Scenario 2: Crate Station Network
1. Place 1 crate station
2. Place 5 crates around it (within 16 blocks)
3. Fill crates with various items
4. Test GUI functionality
5. Test item consolidation

#### Scenario 3: Crate Locking
1. Fill a crate with 1000 items
2. Lock the crate
3. Try to extract all items - should stop at 1
4. Unlock the crate
5. Verify you can now extract all items

#### Scenario 4: Manual Transfer
1. Place 2 crates
2. Fill one with items
3. Hold empty crate, right-click filled crate
4. Verify transfer works
5. Test with mismatched item types (should fail)

## Expected Behaviors

### Crate Interactions
- **Right-click (front face)**: Insert one item
- **Shift + Right-click (front face)**: Insert all matching items from inventory
- **Left-click (front face)**: Extract one item
- **Shift + Left-click (front face)**: Extract one stack
- **Right-click (back face, empty hand, sneak)**: Toggle lock
- **Right-click (holding crate)**: Manual transfer

### Crate Station Interactions
- **Right-click**: Open GUI
- **Shift + Right-click (with items)**: Deposit all matching items
- **Shift + Right-click (empty hand, sneak)**: Consolidate items
- **Shift + Right-click (holding crate, sneak)**: Place crate as block

### Audio Feedback
- **Item insertion**: `handle_one` or `handle_many` sounds
- **Crate lock/unlock**: `handle_one` sound (pitch varies)
- **Consolidation**: `handle_loads` sound
- **Transfer failure**: `no_match` sound

## Troubleshooting

### Crate won't accept items
- Check if crate is locked and empty (may prevent insertion)
- Verify item type matches existing items in crate
- Check crate capacity (max 1 billion items)

### Crate station not finding crates
- Verify crates are within 16 blocks
- Check that crates are placed (not just items)
- Wait a moment for cache to update

### Consolidation not working
- Ensure crates are within 16 blocks of station
- Check that you're using: Sneak + Empty Hand + Right-click
- Verify crates contain items of the same type

## Documentation Files

- **[README.md](README.md)** - Feature overview
- **[item-consolidation.md](item-consolidation.md)** - Detailed consolidation guide
- **[crate-locking.md](crate-locking.md)** - Detailed locking guide
- **[manual-crate-transfer.md](manual-crate-transfer.md)** - Detailed transfer guide
- **[shift-click-placement.md](shift-click-placement.md)** - Detailed placement guide

## Server Testing

To test the mod on a server:
```powershell
.\build.ps1 -StartServer -MinecraftVersion "1.21.8"
```

The server will start and you can connect with a client to test all features.



