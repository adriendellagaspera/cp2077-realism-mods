# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Renamed **Stash Only Disassemble → Immersive Scrapping** and moved the mod
  into its own top-level folder `immersive-scrapping/` (repo is now multi-mod,
  one homonymous folder per mod). File `stashOnlyDisassemble.reds` →
  `immersive-scrapping/immersiveScrapping.reds`; the `handleStorageSlot_*`
  compat files moved alongside it; per-mod README at
  `immersive-scrapping/README.md`; root README is now a repo index. Release
  archives `stash-only-disassemble-*` → `immersive-scrapping-*`; CI presence
  checks and release staging rewired to the new paths. Internal classes
  (`DisassemblePolicy` / `DisassembleGate`) and engine CNames intentionally
  unchanged. Advisory/commit URLs recanonicalised to the renamed GitHub
  repository `cp2077-realism-mods`.

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

[Unreleased]: https://github.com/adriendellagaspera/cp2077-realism-mods/commits/main
