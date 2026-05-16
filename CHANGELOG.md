# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial public release of the mod.
- `DisassemblePolicy` — central abstraction for the disassemble action name,
  hint label, eligibility check, and execution (with audio cue).
- `DisassembleGate` — static flag tracking whether the stash screen is open.
- Single wrap on `CraftingSystem.CanItemBeDisassembled` to block disassembly
  outside the stash, the patch-stable choke point every inventory screen hits.
- `FullscreenVendorGameController` wraps to surface the disassemble action,
  hint, and confirmation / quantity-picker flows in the stash UI.
- CI: sanity checks (UTF-8, conflict markers, indentation, brace balance,
  annotation allowlist) and `redscript-cli format` parse check.
- Release workflow: tag `v*` → builds the install ZIP and publishes a GitHub
  Release with auto-generated notes.
- Level/Tier Flatten module (Cyberpunk Realism, tranche 1) — standalone
  companion that neutralises RPG level + item-tier influence on damage with
  strict, structural NPC parity:
  - `LevelTierFlattenPolicy` — single source of truth for the flatten values
    (neutral level coefficient, neutral tier multiplier, scalar clamp helper).
  - `LevelTierFlattenGate` — static kill-switch (default on); every wrap falls
    through to vanilla `wrappedMethod(...)` when off (neutralise, not delete).
  - Split `levelTierFlatten_cp2077-{2x,1x}.reds` wraps on the shared
    `RPGManager` scaling-coefficient static (no player/NPC branch), mirroring
    the existing `handleStorageSlot_*` per-patch compat pattern.
  - CI presence check and release workflow extended with two new archives
    `level-tier-flatten-{version}-cp2077-{2x,1x}.zip`.

[Unreleased]: https://github.com/adriendellagaspera/mod-stash-only-disassemble/commits/main
