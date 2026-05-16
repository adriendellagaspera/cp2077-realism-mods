# Stash Only Disassemble

A small Cyberpunk 2077 mod that confines item disassembly to the stash screen.

## What it does

- Adds the **Disassemble** action to items shown in the stash UI (V's apartment, safehouses, etc.).
- Disables disassembly everywhere else (inventory, backpack, vendors) by gating
  `CraftingSystem.CanItemBeDisassembled` on whether the stash is currently open.

The result: you can't accidentally break down an item from your active inventory,
but the stash becomes your dedicated salvage bench.

## Requirements

- [redscript](https://github.com/jac3km4/redscript) v0.5.x or later (usually
  installed via [RED4ext](https://github.com/WopsS/RED4ext) or a mod manager
  like Vortex).

## Version compatibility

Two archives are published with every release — pick the one that matches your
game version:

| Archive | Game patch | Status |
|---|---|---|
| `stash-only-disassemble-{version}-cp2077-2x.zip` | **2.0 and later** | Supported and tested |
| `stash-only-disassemble-{version}-cp2077-1x.zip` | **1.x** (pre–Phantom Liberty) | Supported and tested |

The only difference between the two is the name of one internal method
(`HandleStorageSlotClick` in 2.x vs `HandleStorageSlotInput` in 1.x). All other
game APIs used by this mod exist in both versions with the same signatures.

CI validates syntax against the redscript v1.0.0-preview parser series
(preview5, preview.22).

## Installation

1. Install redscript if you don't have it already.
2. Download the archive that matches your game version (see table above).
3. Copy both `.reds` files into:
   ```
   <Cyberpunk 2077>/r6/scripts/stashOnlyDisassemble/
   ```
4. Launch the game. redscript will compile the script on startup; check
   `r6/cache/redscript.log` if anything goes wrong.

## Uninstall

Delete the folder you created in step 2 and restart the game.

## How it works

Two small pieces of state cooperate:

- `DisassembleGate` — a static `Bool` flipped on/off in
  `FullscreenVendorGameController.OnInitialize` / `OnUninitialize` whenever a stash
  screen opens or closes.
- `DisassemblePolicy` — owns the action name, hint label, and the
  "is this item disassemblable" check, so controllers don't duplicate that logic.

The core blocker is a single wrap on `CraftingSystem.CanItemBeDisassembled` — the
canonical gate every inventory screen consults before showing the disassemble hint
or running the action. Wrapping it once is more patch-stable than chasing every
UI controller individually.
