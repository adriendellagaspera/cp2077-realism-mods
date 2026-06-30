# Testing

These mods are [redscript](https://github.com/jac3km4/redscript) files that
`@wrapMethod`/`@addMethod` onto **native Cyberpunk 2077 classes**
(`CraftingSystem`, `FullscreenVendorGameController`, `ItemActionsHelper`, …).
Historically the only way to know a hook actually resolved was to launch the
game and read `r6/cache/redscript.log`. This page describes how to verify a mod
**without opening the game**.

## What is (and isn't) possible offline

Running redscript outside the game is **not** possible — there is no standalone
VM, so there are no behavioural unit tests. What *is* possible, and what catches
the dangerous bugs, is a **semantic type-check at compile time**:

- a `@wrapMethod` whose signature no longer matches the real method,
- a method **renamed between patches**
  (`HandleStorageSlotInput` 1.x → `HandleStorageSlotClick` 2.x),
- a missing/renamed field, enum variant, or type.

All of these fail the compile. A clean compile means every wrapped method,
field, enum and type resolves against the actual game definitions.

## Ground truth: the game's own bundle

The real source of truth is **`final.redscripts`**, the compiled script bundle
that ships with the game (you already have it — you own the game). Compiling the
mod against it reproduces *exactly* the step the game runs at startup, minus the
launch. The decompiled sources at
[codeberg.org/adamsmasher/cyberpunk](https://codeberg.org/adamsmasher/cyberpunk)
are a handy **reference** for reading signatures, but they cannot be recompiled
on their own (`redscript-cli compile` always requires an existing `-b` bundle),
so they are not used as the compile target.

> The bundle is a game file: it is **never** committed or redistributed
> (`*.redscripts` is git-ignored).

## Running the check

Install [`redscript-cli`](https://github.com/jac3km4/redscript) (on `PATH`), then
point `CP2077_REDSCRIPTS` at your game root and run:

```sh
CP2077_REDSCRIPTS="/path/to/Cyberpunk 2077" ./scripts/typecheck.sh
```

The script derives the bundle from `r6/cache/`, preferring the pristine backup
`final.redscripts.bk` over an already-modded `final.redscripts`, and compiles the
patch-2.x variant (`immersiveScrapping.reds` + `handleStorageSlot_cp2077-2x.reds`).
If `CP2077_REDSCRIPTS` or `redscript-cli` is missing it **skips** (exit 0).

This check also runs automatically via the **pre-commit** hook
(`redscript-typecheck` in `.pre-commit-config.yaml`) on any `.reds` change.

## Where each layer runs

| Check | Where | Tool |
|-------|-------|------|
| Sanity (encoding, whitespace, braces, annotations) | CI + pre-commit | `.github/workflows/ci.yml` |
| Syntax parse (all `.reds`) | CI | `redscript-cli format -s .` |
| **Semantic type-check (ground truth)** | **pre-commit (local)** | `scripts/typecheck.sh` |

Public CI cannot hold the bundle (a copyrighted game file), so the ground-truth
type-check lives in the local pre-commit hook. A maintainer with a self-hosted
runner can enable it in CI by exporting `CP2077_REDSCRIPTS` there; otherwise the
CI step skips cleanly.

Patch **1.x** is out of scope for the offline check and stays covered by in-game
manual testing.

## Verifying the guard catches a real bug

On a machine with the game (so the bundle is available, `CP2077_REDSCRIPTS` set):

1. **Positive control** — clean tree: `./scripts/typecheck.sh` succeeds.
2. **Renamed wrap** — rename `CanItemBeDisassembled` to a name that doesn't
   exist; the check fails (unresolved `@wrapMethod` target). Revert.
3. **Signature drift** — drop the `itemData` parameter from that wrap; the check
   fails (this is the "re-signatured between patches" class that previously only
   appeared in-game).
4. **Field / enum typo** — `m_storageUserData` → `m_storageUserDataX`, or
   `QuantityPickerActionType.Disassembly` → `.DisassemblyX`; each fails. Revert.
