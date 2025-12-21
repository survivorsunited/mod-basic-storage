#### [🤝 Contribute Translations](https://poeditor.com/join/project/mmucxtutwG)  |  [⚡Visit khazoda.com](https://khazoda.com)  |  [💬 Get direct support on Discord](https://discord.com/invite/vEZUkSxwR9)

### This repository contains the source code for the Basic Storage mod for Minecraft Java Edition, available on [Modrinth](https://modrinth.com/mod/basic-storage) and [CurseForge](https://www.curseforge.com/minecraft/mc-mods/basic-storage).

The code in this repository is under the [MIT License](https://github.com/Khazoda/basic-storage/blob/latest-stable/LICENSE).

Issues and pull requests are welcome, but please contribute translations via the POEditor platform [here](https://poeditor.com/join/project/mmucxtutwG).

![Basic Storage mod banner](https://github.com/Khazoda/basic-storage/blob/Web-Assets/description_common/banner.png?raw=true)

## Click Events Reference

### Crate Block Interactions

#### Right-Click Events

- **Right-Click** (normal, holding item) → Insert 1 item into the crate
- **Right-Click** (empty hand) → Display exact crate contents (item count and type)
- **Shift + Right-Click** → Insert all matching items from inventory into the crate
- **Shift + Sneak + Right-Click** → Push items from held crate to clicked crate (manual transfer)

#### Left-Click Events

- **Left-Click** (normal) → Extract 1 item from crate to inventory
- **Shift + Left-Click** → Extract 1 full stack from crate to inventory
- **Shift + Sneak + Left-Click** → Pull items from clicked crate to held crate (manual transfer)
  - If holding a stack of crates, the stack will be split (1 crate in hand, rest in inventory)
  - If inventory is full, the filled crate will be dropped on the floor

### Crate Station Block Interactions

#### Right-Click Events

- **Right-Click** (holding item) → Deposit stack to matching connected crate
- **Right-Click** (empty hand) → Display number of connected crates
- **Shift + Right-Click** (holding item) → Deposit all matching items from inventory
- **Shift + Right-Click** (empty hand) → Consolidate items across all connected crates

#### Left-Click Events

- **None** - Crate stations do not respond to left-click events

### Quick Reference Table

| Block | Click Type | Modifiers | Action |
|-------|-----------|-----------|--------|
| Crate | Right-Click | None | Insert 1 item |
| Crate | Right-Click | Empty hand | Show contents |
| Crate | Right-Click | Shift | Insert all matching items |
| Crate | Right-Click | Shift + Sneak | Push items from held crate |
| Crate | Left-Click | None | Extract 1 item |
| Crate | Left-Click | Shift | Extract 1 stack |
| Crate | Left-Click | Shift + Sneak | Pull items to held crate |
| Crate Station | Right-Click | None (holding item) | Deposit stack to matching crate |
| Crate Station | Right-Click | None (empty hand) | Show connected crate count |
| Crate Station | Right-Click | Shift (holding item) | Deposit all matching items |
| Crate Station | Right-Click | Shift (empty hand) | Consolidate items |

### Important Notes

- All crate interactions require clicking on the **front face** of the crate (the side with the opening)
- Manual crate transfer (pull/push) requires holding a crate item in your main hand
- When pulling items with a stack of crates, the stack will automatically split to prevent duplication
- Items must be compatible (same type or one side empty) for manual transfers
- Crate stations work within a 16-block radius
- For detailed documentation, see [docs/CLICK_EVENTS.md](docs/CLICK_EVENTS.md)
