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

---

# Level/Tier Flatten (Cyberpunk Realism — Tranche 1)

A standalone companion module, built on the same architecture, that
**neutralises the influence of the RPG level + item-tier system on damage**.
Combat is then driven by weapon archetype + cyberware + hit location, with
strict NPC parity — Night City becomes genuinely lethal in *both* directions.

It is a separate drop-in (its own `r6/scripts/levelTierFlatten/` folder and its
own release archives); install it on its own or alongside the disassemble mod.

## What it does

- Collapses the attacker-vs-target level-delta scaling coefficient to a no-op
  (`1.0`) and clamps the tier/quality multiplier to neutral, in the **shared
  static** on `RPGManager`.
- Because that static is the same code path for player→NPC, NPC→player and
  NPC→NPC, parity is **structural**: there is deliberately *no* "is this the
  player" branch anywhere. The same flat rule applies to everyone.
- Weapon archetype stats and hit-location remain untouched — only the
  level/tier *amplification* is removed. Entity level fields are not modified,
  so perks, requirements and quests are unaffected.

This is **neutralisation, not deletion**: the signal still flows through the
engine, just collapsed to a no-op. `LevelTierFlattenGate` is a kill-switch
(default on) — turning it off restores stock scaling instantly via the vanilla
`wrappedMethod(...)` fallthrough. This is what keeps it stable across patches
and deep mod stacks: it does not fight the engine.

## Scope & composition

This module flattens **damage** (the redscript-reachable layer). It does **not**
rescale NPC health pools — that bullet-sponge effect is TweakDB-data-driven and
out of scope for redscript here. Without a companion, damage is already fully
de-scaled and lethal both ways, but vanilla NPC health bars make time-to-kill
longer than you may expect.

For the health-pool layer, **compose** with an established, configurable mod
rather than reimplementing it:

- [No Enemy Scaling](https://www.nexusmods.com/cyberpunk2077/mods/24244), or
- [Damage Scaling and Balance](https://www.nexusmods.com/cyberpunk2077/mods/1712).

## Version compatibility

Same 2.x / 1.x split as above (the RPG/damage surface was reworked around patch
2.0/2.1, so method names and signatures differ between game lines):

| Archive | Game patch |
|---|---|
| `level-tier-flatten-{version}-cp2077-2x.zip` | **2.0 and later** |
| `level-tier-flatten-{version}-cp2077-1x.zip` | **1.x** (pre–Phantom Liberty) |

CI parses both lines but cannot validate the wrapped `RPGManager` signature
against a real game build. After installing, launch once and check
`r6/cache/redscript.log`: an unresolved-symbol error means your patch exposes a
different name — the file headers document the ordered fallback seam to switch
to (Policy/Gate need no change).
