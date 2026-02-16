# Basic Storage Mod - Click Events Reference

This document lists all supported click events for crates and crate stations.

## Crate Block (`CrateBlock`)

### Right-Click Events (UseBlockCallback)

1. **Right-Click (Normal)**
   - **Condition**: Not sneaking, holding a valid item stack
   - **Action**: Insert one item into the crate
   - **Requirements**: Item must match crate contents or crate must be empty

2. **Right-Click (Empty Hand)**
   - **Condition**: Not sneaking, holding nothing
   - **Action**: Display exact crate contents (item count and type)

3. **Shift + Right-Click**
   - **Condition**: Sneaking, holding a valid item stack
   - **Action**: Insert all matching items from inventory into the crate
   - **Requirements**: Item must match crate contents or crate must be empty

4. **Sneak + Right-Click (Manual Transfer - Push)**
   - **Condition**: Sneaking, holding a crate item
   - **Action**: Transfer items from held crate to clicked crate
   - **Requirements**: Items must be same type or one side must be empty

### Left-Click Events (AttackBlockCallback)

5. **Sneak + Left-Click (Manual Transfer - Pull)**
   - **Condition**: Sneaking, holding a crate item
   - **Action**: Transfer items from clicked crate to held crate
   - **Requirements**: Items must be same type or one side must be empty
   - **Stack Handling**: 
     - If holding a stack of crates (count > 1), the stack will be automatically split
     - 1 crate remains in hand, the rest goes to inventory
     - If inventory is full, the rest of the stack drops on the floor
     - After transfer, if inventory was full, the filled crate will be dropped on the floor
   - **Note**: Prevents block breaking and prevents item duplication

### Block Breaking Start (onBlockBreakStart)

6. **Left-Click (Normal)**
   - **Condition**: Clicking on front face of crate
   - **Action**: Extract one item from crate to inventory

7. **Shift + Left-Click (Normal)**
   - **Condition**: Sneaking, clicking on front face of crate
   - **Action**: Extract one full stack from crate to inventory

## Crate Station Block (`CrateStationBlock`)

### Right-Click Events (UseBlockCallback)

1. **Right-Click (Holding Item)**
   - **Condition**: Not sneaking, holding an item stack
   - **Action**: Search for nearest connected crate containing the item type and deposit the stack
   - **Feedback**: Shows "• No Matching Crates •" if no compatible crate found

2. **Right-Click (Empty Hand)**
   - **Condition**: Not sneaking, holding nothing
   - **Action**: Display number of connected crates
   - **Message**: "• {count} Crates Connected •"

3. **Shift + Right-Click (Deposit Inventory)**
   - **Condition**: Sneaking, holding any item
   - **Action**: Add all items from inventory to connected crates that match
   - **Feedback**: Shows "• No Matching Crates •" if no compatible crates found

4. **Shift + Right-Click (Item Consolidation)**
   - **Condition**: Sneaking, holding nothing
   - **Action**: Consolidate items of the same type across all connected crates into the crate with the most items
   - **Success Message**: "• Items Consolidated •"
   - **Failure Message**: "• No Items To Consolidate •"

### Left-Click Events

- **None**: Crate stations do not respond to left-click events

## Summary Table

| Block | Click Type | Modifiers | Action |
|-------|-----------|-----------|--------|
| Crate | Right-Click | None | Insert 1 item |
| Crate | Right-Click | Empty hand | Show contents |
| Crate | Right-Click | Shift | Insert all matching items |
| Crate | Right-Click | Sneak | Push items from held crate |
| Crate | Left-Click | None | Extract 1 item |
| Crate | Left-Click | Shift | Extract 1 stack |
| Crate | Left-Click | Sneak | Pull items to held crate |
| Crate Station | Right-Click | None (holding item) | Deposit stack to matching crate |
| Crate Station | Right-Click | None (empty hand) | Show connected crate count |
| Crate Station | Right-Click | Shift (holding item) | Deposit all matching items |
| Crate Station | Right-Click | Shift (empty hand) | Consolidate items |

## Notes

- All interactions require clicking on the **front face** of the crate (the side with the opening)
- Manual crate transfer (pull/push) requires holding a crate item in your main hand
- **Stack Splitting**: When pulling items (Sneak+Left-Click) with a stack of crates:
  - The stack is automatically split to prevent item duplication
  - 1 crate stays in hand, rest goes to inventory (or drops if inventory is full)
  - After transfer, if inventory was full, the filled crate drops on the floor
- Items must be compatible (same type or one side empty) for manual transfers
- Crate stations work within a 16-block radius

