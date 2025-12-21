# Test Steps for Latest Features - Stack Handling

This document provides detailed test steps for the latest manual crate transfer features with stack handling.

## Feature Overview

The latest updates improve manual crate transfer to properly handle stacks of crates:

1. **Pull (Shift+Sneak+Left-Click)**: Automatically splits stack before transfer, drops filled crate if inventory was full
2. **Push (Shift+Sneak+Right-Click)**: Processes each crate in stack one by one, pushing items from each

---

## Test 1: Pull with Stack - Normal Case (Inventory Has Space)

**Purpose**: Verify that pulling items with a stack of crates correctly splits the stack and keeps the filled crate in hand when inventory has space.

### Setup
1. Start server: `.\build.ps1 -StartServer -MinecraftVersion "1.21.8"`
2. Connect with client
3. Get items:
   - 5+ empty crates (stack them together)
   - 1 placed crate filled with items (e.g., 1000 iron ingots)
   - Ensure your inventory has at least 1 empty slot

### Steps
1. **Hold a stack of 5 empty crates** in your main hand
2. **Stand in front of the placed crate** (front face with opening)
3. **Hold Shift** (sneak)
4. **Left-Click** on the placed crate
5. **Observe**:
   - Stack should split: 1 crate stays in hand, 4 crates go to inventory
   - Items transfer from placed crate to held crate
   - Filled crate should remain in your hand
   - Inventory should contain 4 empty crates

### Expected Results
- ✅ Stack splits correctly (1 in hand, 4 in inventory)
- ✅ Items transfer successfully
- ✅ Filled crate stays in hand (because inventory had space)
- ✅ No items duplicated
- ✅ No items lost

---

## Test 2: Pull with Stack - Inventory Full Case

**Purpose**: Verify that pulling items with a stack of crates correctly drops the filled crate when inventory is full.

### Setup
1. Fill your inventory completely (all 36 slots + hotbar)
2. Have 5+ empty crates stacked together
3. Have 1 placed crate filled with items (e.g., 1000 iron ingots)

### Steps
1. **Hold a stack of 5 empty crates** in your main hand
2. **Stand in front of the placed crate** (front face)
3. **Hold Shift** (sneak)
4. **Left-Click** on the placed crate
5. **Observe**:
   - Stack should split: 1 crate stays in hand, 4 crates drop on floor (inventory full)
   - Items transfer from placed crate to held crate
   - Filled crate should **drop on the floor** (because inventory was full)
   - Your hand should be empty

### Expected Results
- ✅ Stack splits correctly (1 in hand, 4 drop on floor)
- ✅ Items transfer successfully
- ✅ Filled crate drops on floor (because inventory was full)
- ✅ No items duplicated
- ✅ No items lost

---

## Test 3: Pull with Single Crate

**Purpose**: Verify that pulling with a single crate works normally (no splitting needed).

### Setup
1. Have 1 empty crate
2. Have 1 placed crate filled with items

### Steps
1. **Hold 1 empty crate** in your main hand
2. **Stand in front of the placed crate**
3. **Hold Shift** (sneak)
4. **Left-Click** on the placed crate
5. **Observe**: Items transfer, filled crate stays in hand

### Expected Results
- ✅ No splitting occurs (only 1 crate)
- ✅ Items transfer successfully
- ✅ Filled crate stays in hand

---

## Test 4: Push with Stack - Multiple Crates with Items

**Purpose**: Verify that pushing items from a stack of crates processes each crate one by one.

### Setup
1. Create 3 crates, each filled with the same item type (e.g., 500 iron ingots each)
2. Stack them together (3 crates in one stack)
3. Have 1 empty placed crate (or crate with same item type)

### Steps
1. **Hold the stack of 3 filled crates** in your main hand
2. **Stand in front of the placed crate** (front face)
3. **Hold Shift** (sneak)
4. **Right-Click** on the placed crate
5. **Observe**:
   - First crate pushes its items
   - If clicked crate has space, second crate pushes its items
   - Third crate pushes its items
   - Empty crates are removed from stack
   - Partially emptied crates go back to inventory (or drop if full)

### Expected Results
- ✅ Each crate in stack processes one by one
- ✅ Items transfer from each crate sequentially
- ✅ Empty crates are removed from stack
- ✅ Partially emptied crates handled correctly
- ✅ Processing stops when clicked crate is full
- ✅ No items duplicated

---

## Test 5: Push with Stack - Mixed Empty and Filled Crates

**Purpose**: Verify that pushing with a mixed stack (some empty, some filled) handles empty crates correctly.

### Setup
1. Create 2 filled crates (same item type)
2. Create 2 empty crates
3. Stack them together: [filled, filled, empty, empty]

### Steps
1. **Hold the mixed stack** in your main hand
2. **Stand in front of a placed crate** (can be empty or same item type)
3. **Hold Shift** (sneak)
4. **Right-Click** on the placed crate
5. **Observe**:
   - Empty crates should be skipped
   - Filled crates should push their items
   - Empty crates should be removed from stack

### Expected Results
- ✅ Empty crates are skipped
- ✅ Filled crates push their items
- ✅ Empty crates removed from stack
- ✅ No errors or crashes

---

## Test 6: Push with Stack - Clicked Crate Becomes Full

**Purpose**: Verify that pushing stops when the clicked crate becomes full.

### Setup
1. Create 5 crates, each with 1000 items (same type)
2. Stack them together
3. Have 1 placed crate with 9000 items (almost full, capacity is 1 billion but we'll use smaller numbers for testing)

### Steps
1. **Hold the stack of 5 filled crates**
2. **Stand in front of the almost-full placed crate**
3. **Hold Shift** (sneak)
4. **Right-Click** on the placed crate
5. **Observe**:
   - First crate pushes items until clicked crate is full
   - Processing stops when clicked crate reaches capacity
   - Remaining crates in stack are not processed

### Expected Results
- ✅ Processing stops when clicked crate is full
- ✅ No overflow or errors
- ✅ Remaining crates in stack are preserved

---

## Test 7: Pull with Stack - Incompatible Items

**Purpose**: Verify that pulling stops when item types don't match.

### Setup
1. Have 5 empty crates stacked
2. Have 1 placed crate with iron ingots
3. Have 1 placed crate with gold ingots

### Steps
1. **Fill one crate in your stack** with diamonds (different item type)
2. **Hold the stack** (should have 1 filled with diamonds, 4 empty)
3. **Stand in front of placed crate with iron ingots**
4. **Hold Shift** (sneak)
5. **Left-Click** on the placed crate
6. **Observe**: Should fail with "Incompatible Item Types" message

### Expected Results
- ✅ Transfer fails with error message
- ✅ No items transferred
- ✅ Stack remains unchanged
- ✅ Error sound plays

---

## Test 8: Push with Stack - Incompatible Items

**Purpose**: Verify that pushing stops when item types don't match.

### Setup
1. Create 3 crates filled with diamonds
2. Stack them together
3. Have 1 placed crate with iron ingots

### Steps
1. **Hold the stack of 3 diamond-filled crates**
2. **Stand in front of placed crate with iron ingots**
3. **Hold Shift** (sneak)
4. **Right-Click** on the placed crate
5. **Observe**: Should fail with "Incompatible Item Types" message

### Expected Results
- ✅ Transfer fails with error message
- ✅ No items transferred
- ✅ Stack remains unchanged
- ✅ Error sound plays

---

## Test 9: Pull with Stack - Clicked Crate Empty

**Purpose**: Verify that pulling from an empty crate works correctly.

### Setup
1. Have 5 empty crates stacked
2. Have 1 empty placed crate

### Steps
1. **Hold the stack of 5 empty crates**
2. **Stand in front of empty placed crate**
3. **Hold Shift** (sneak)
4. **Left-Click** on the placed crate
5. **Observe**: Nothing should happen (no transfer, no error)

### Expected Results
- ✅ No transfer occurs (both crates empty)
- ✅ Stack splits correctly
- ✅ No errors

---

## Test 10: Push with Stack - Held Crate Empty

**Purpose**: Verify that pushing with empty crates in stack skips them correctly.

### Setup
1. Have 3 empty crates stacked
2. Have 1 placed crate with items

### Steps
1. **Hold the stack of 3 empty crates**
2. **Stand in front of placed crate with items**
3. **Hold Shift** (sneak)
4. **Right-Click** on the placed crate
5. **Observe**: Empty crates should be skipped, no transfer occurs

### Expected Results
- ✅ Empty crates are skipped
- ✅ No transfer occurs
- ✅ Stack remains unchanged

---

## Quick Test Checklist

### Pull Tests (Shift+Sneak+Left-Click)
- [ ] **Test 1**: Pull with stack, inventory has space → filled crate stays in hand
- [ ] **Test 2**: Pull with stack, inventory full → filled crate drops
- [ ] **Test 3**: Pull with single crate → works normally
- [ ] **Test 7**: Pull with incompatible items → fails correctly
- [ ] **Test 9**: Pull from empty crate → no transfer

### Push Tests (Shift+Sneak+Right-Click)
- [ ] **Test 4**: Push with stack of filled crates → processes each one
- [ ] **Test 5**: Push with mixed stack → empty crates skipped
- [ ] **Test 6**: Push until clicked crate full → stops correctly
- [ ] **Test 8**: Push with incompatible items → fails correctly
- [ ] **Test 10**: Push with empty stack → no transfer

---

## Common Issues to Watch For

### Item Duplication
- **Symptom**: Items appear in both crates after transfer
- **Check**: Verify stack splitting happens BEFORE transfer
- **Fix**: Ensure `initOnAttackMethod` splits stack before calling `handleManualCrateTransfer`

### Items Lost
- **Symptom**: Items disappear during transfer
- **Check**: Verify transaction commits correctly
- **Fix**: Ensure all transactions are properly committed

### Stack Not Splitting
- **Symptom**: All crates in stack receive items during pull
- **Check**: Verify splitting logic runs before transfer
- **Fix**: Ensure splitting happens in `initOnAttackMethod` before transfer

### Filled Crate Not Dropping
- **Symptom**: Filled crate stays in hand when inventory was full
- **Check**: Verify `inventoryWasFull` flag is tracked correctly
- **Fix**: Ensure flag is set when `insertStack` returns false

### Push Not Processing All Crates
- **Symptom**: Only first crate in stack pushes items
- **Check**: Verify loop processes all crates
- **Fix**: Ensure loop continues until stack is empty or clicked crate is full

---

## Test Commands

### Start Test Server
```powershell
.\build.ps1 -StartServer -MinecraftVersion "1.21.8"
```

### Build Mod
```powershell
.\build.ps1 -MinecraftVersion "1.21.8"
```

---

## Notes

- All tests require clicking on the **front face** of the crate (the side with the opening)
- Manual transfer requires **sneaking** (holding Shift)
- Stack splitting happens automatically - you don't need to manually split stacks
- If inventory is full, items will drop on the floor
- Empty crates are automatically removed from stacks during push operations




