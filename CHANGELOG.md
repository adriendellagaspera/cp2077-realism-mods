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

[Unreleased]: https://github.com/adriendellagaspera/mod-stash-only-disassemble/commits/main
