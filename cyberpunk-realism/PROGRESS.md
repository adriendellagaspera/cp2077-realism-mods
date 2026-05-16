# Cyberpunk Realism — progress & chantier tracker

Actionable state of every chantier. Vision/overview lives in this folder's
[`README.md`](./README.md).

## Status legend

- `DONE` — merged to `main` (dry: CI green + in-game symbol verified).
- `IMPLEMENTED` — code written & parses, **not yet dry** (symbol unverified).
- `PLANNED` — scoped, not yet coded.
- `IDEA` — direction noted, scope/risk not pinned.
- `BLOCKED` — cannot progress until a listed blocker clears.

## Workflow & merge policy

- Integration branch: `feature/cyberpunk-realism`.
- One chantier = one sub-branch `feature/cyberpunk-realism-<chantier>` (dash,
  not slash: a `feature/cyberpunk-realism/...` ref collides with the
  integration branch ref).
- Sub-branch → PR into `feature/cyberpunk-realism`.
- `feature/cyberpunk-realism` → `main` **only when dry**: CI green **and**
  every wrapped game symbol verified in `r6/cache/redscript.log` (or switched
  to its documented fallback seam). `main` never carries unfinished work.
- The "dry" gate exists because CI is **parse-only**: it proves syntax, never
  that a wrapped `RPGManager` / UI-controller symbol exists in a real build.

## In-game verification harness (cross-cutting, BLOCKED on input)

Every gameplay/UI module shares one blocker: confirming wrapped symbols.
To clear it we need, from a real install, **either**:
- `r6/cache/redscript.log` after one game launch with the module installed
  (an unresolved-symbol line names the bad wrap), **or**
- a script dump of the target patch to confirm names/signatures offline.

Until then, `IMPLEMENTED` modules stay on the feature branch by policy.

---

## C1 — Level/Tier Damage Flatten (tranche 1)

- **Status:** `IMPLEMENTED` · `BLOCKED` (in-game symbol verification)
- **Branch:** on `feature/cyberpunk-realism` (was PR #11 → reverted from
  `main` by PR #12; preserved here intentionally).
- **Files:** `levelTierFlatten.reds` (Policy/Gate),
  `levelTierFlatten_cp2077-{2x,1x}.reds` (wraps).
- **Scope:** neutralise level-delta scaling coefficient → 1.0 and tier/quality
  multiplier → neutral, in the shared `RPGManager` static. No player/NPC
  branch (structural parity). Archetype + hit-location untouched.
- **Blocker:** wrapped `RPGManager` static name/signature is best-effort.
  Verify in `redscript.log`; fallback seam chain (#1 finaliser / #3 quality
  getter) documented in the `_cp2077-*` file headers.
- **Dry criteria (behavioural, prove parity — not just "damage changed"):**
  - [ ] `redscript.log` clean (symbol resolves) or switched to fallback.
  - [ ] Tier invariance: common vs iconic, same archetype/location → equal TTK.
  - [ ] Level invariance player→NPC: low vs high-level enemy → equal per-hit.
  - [ ] Parity NPC→player and NPC→NPC: no side over-sponges by level.
  - [ ] Kill-switch off → vanilla scaling returns instantly.
- **Mod-split:** standalone — ships as `level-tier-flatten-*` archive.

## C2 — UI Flatten (tranche 2, cosmetic)

Stops the UI advertising level/tier so it matches C1's de-scaled numbers.
Changes no game logic. Several fragile UI-controller wraps → split into
sub-items so each can go dry independently.

### C2a — Rarity-colour neutralisation
- **Status:** `IMPLEMENTED` · `BLOCKED` (symbol verification)
- **Branch:** `feature/cyberpunk-realism-tranche2-ui`
- **Files:** `uiFlatten.reds` (Policy/Gate),
  `uiFlatten_cp2077-{2x,1x}.reds` (quality→colour resolver wrap).
- **Scope:** coerce the quality used for *colour* resolution to a single
  neutral quality so the rarity rainbow stops signalling power. Item
  stats/identity untouched.
- **Blocker:** resolver controller name (`UIInventoryItemsManager` /
  `UIItemColorTheme`) best-effort; confirm/adjust per patch.
- **Dry criteria:**
  - [ ] `redscript.log` clean or switched to fallback.
  - [ ] Common vs iconic of same archetype render identical colour in
        inventory, tooltip, world pickup.
  - [ ] Kill-switch off → vanilla colours return.

### C2b — Enemy nameplate level hidden
- **Status:** `PLANNED`
- **Scope:** blank the level label on the enemy nameplate
  (`UiFlattenPolicy.HiddenLevelText()` already provides the substitution).
- **Candidate controllers:** `NameplateBarsLogicController` /
  `healthbarInjector` level setter (private level-text field name unknown —
  do **not** speculatively code until confirmed; tranche-1 revert lesson).
- **Dry criteria:** nameplate shows no level; danger/threat coloring (if any)
  unaffected; kill-switch restores.

### C2c — Item "required level" tooltip hidden
- **Status:** `PLANNED`
- **Scope:** suppress the "Requires Level N" line/lock on item tooltips.
- **Candidate controllers:** tooltip / requirement display controller
  (confirm name per patch).
- **Dry criteria:** no required-level line; item still usable; kill-switch.

### C2d — Level-up / character screen level hidden
- **Status:** `PLANNED`
- **Scope:** suppress the player-level readout and the level-up popup.
- **Candidate controllers:** level-up notification + character-sheet
  controller (confirm per patch).
- **Dry criteria:** no level number / popup; perks & attributes still
  function; kill-switch.

- **Mod-split (C2):** standalone cosmetic module — own `r6/scripts/uiFlatten/`
  + own archive; install with or without C1.

## C3 — Continuous "learn-by-doing" progression (Skyrim-like)

- **Status:** `IDEA`
- **Scope:** replace level-milestone / perk-point gating with continuous
  per-axis growth. Axes (CP2077): attributes Body / Reflexes / Technical
  Ability / Intelligence / Cool; skills Handguns, Assault, Blades, Street
  Brawler, Athletics, Annihilation, Stealth, Engineering, Crafting,
  Quickhacking, Cold Blood. Use-based XP already vanilla → the work is
  neutralising the milestone gating and driving effects off a continuous
  proficiency value (redscript stat-read seam).
- **Open questions:** which gate is the single neutralisation point;
  interaction with C1/C5 damage terms; UI for a continuous value (C2-like).
- **Risk:** medium. **Mod-split:** likely its own mod.

## C4 — Skill regression / decay

- **Status:** `IDEA` · hardest chantier
- **Scope:** skills decay if not practised. No native CP2077 decay → custom
  periodic tick + persisted per-axis state (redscript).
- **Risk:** high — new persisted subsystem; main scope driver of any tranche
  it lands in. Isolate hard. **Mod-split:** almost certainly its own mod.

## C5 — Firearm vs. melee damage asymmetry

- **Status:** `PLANNED` (composes with C1)
- **Scope:** firearms = weapon-archetype damage only (bullet independent of
  shooter); melee/blades = archetype **+ Body/strength term**. Reintroduce a
  *physical* term for melee only, at the same `RPGManager` seam C1 wraps,
  after the flatten — so it stacks cleanly on a de-scaled base.
- **Depends on:** C1 dry (shares the seam).
- **Risk:** medium. **Mod-split:** could fold into C1's module or ship as an
  add-on toggled by its own Gate.

## Cross-cutting backlog

- **Release packaging per module:** `release.yml` already builds
  `level-tier-flatten-*`. Add `ui-flatten-*` (and future modules) **only when
  each is dry** — deferred deliberately to avoid shipping unverified config.
- **Multi-repo extraction:** modules are folder/archive-isolated; document the
  extraction steps when the suite outgrows this repo.
