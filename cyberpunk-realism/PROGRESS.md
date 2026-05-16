# Cyberpunk Realism — progress & workstream tracker

Actionable state of every workstream. Vision/overview lives in this folder's
[`README.md`](./README.md).

## Status legend

- `DONE` — merged to `main` (dry: CI green + in-game symbol verified).
- `IMPLEMENTED` — code written & parses, **not yet dry** (symbol unverified).
- `PLANNED` — scoped, not yet coded.
- `IDEA` — direction noted, scope/risk not pinned.
- `BLOCKED` — cannot progress until a listed blocker clears.

## Workflow & merge policy

- Integration branch: `feature/cyberpunk-realism`.
- One workstream = one sub-branch `feature/cyberpunk-realism-<workstream>` (dash,
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

## C1 — Level/Tier Damage Flatten (phase 1)

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

## C2 — UI Flatten (phase 2, cosmetic)

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
  do **not** speculatively code until confirmed; phase-1 revert lesson).
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

- **Status:** `IDEA` · **architecture DECIDED: start B, A is traction-gated**
- **Researched seam:** progression is `PlayerDevelopmentData`, reached via
  `PlayerDevelopmentSystem.GetData(player)`; perk/attribute points are
  awarded on level-up and are redscript-modifiable. Reference
  implementations: `cp2077-neurespec` (psiberx) for attribute/perk/skill
  manipulation; the "Skillful" family already scales effects off skill
  proficiencies — the closest existing analogue to this workstream.
- **Scope:** per-axis continuous growth. Axes (CP2077): attributes Body /
  Reflexes / Technical Ability / Intelligence / Cool; skills Handguns,
  Assault, Blades, Street Brawler, Athletics, Annihilation, Stealth,
  Engineering, Crafting, Quickhacking, Cold Blood. Use-based XP is already
  vanilla — the work is removing the milestone gating.
- **Architectures (decision made — see suite doctrine in cross-cutting):**
  - **B — chosen starting implementation (engine-adaptive).** Keep the point
    system; unbottle the single point-award seam in `PlayerDevelopmentData`
    so milestones stop being the constraint. Minimal, reversible surface;
    painless across game updates; coexists with the modding ecosystem
    (neurespec / Skillful). Still point-based underneath — less "continuous"
    in feel than A, an accepted concession.
  - **A — traction-gated future migration (deep overhaul).** Drive effects
    directly off the continuous skill-proficiency value; neutralise the
    perk/attribute *point* milestone gating entirely. Closest to the Skyrim
    feel. Large surface (stat reads spread wide), own UI pass, and would
    eventually need dedicated ecosystem addons. **Not abandoned —
    explicitly deferred** until project traction justifies the cost.
- **Decision:** ship **B** first to validate the feel cheaply and reversibly;
  re-evaluate **A** only if traction warrants the deep-overhaul cost. Shares
  "continuous value + decay" building blocks with C4 and C6.
- **Open questions:** the single neutralisation seam; interaction with C1/C5
  damage terms; continuous-value UI.
- **Risk:** medium. **Coding blocked by** the symbol-verification harness;
  **design is unblocked** (this entry). **Mod-split:** likely its own mod.

## C4 — Skill regression / decay

- **Status:** `IDEA` · hardest workstream · depends on C3 architecture
- **Researched constraint:** the periodic tick is easy (game callbacks /
  delay system). The real obstacle is **persistence**: redscript has no clean
  per-mod persisted save field. Decay state must therefore either (a) ride a
  CET/RED4ext companion (RedData-style sidecar) — a hard external dependency;
  (b) piggyback an already-persisted player stat/quest fact as the store —
  hacky and patch-fragile; or (c) wait until C3 exists (decay is only
  meaningful once there is a continuous value to decay).
- **Reframed blocker:** persistence, not the tick.
- **Recommendation (under the suite doctrine):** prefer **engine-native /
  piggyback persistence** first; **defer the CET/RED4ext companion** (the
  deep-overhaul path) until traction justifies a hard external dependency.
  Still gate C4 behind C3's seam landing, and treat persistence as its own
  isolated spike before any code.
- **Risk:** high — new persisted subsystem. **Mod-split:** its own mod.

## C5 — Firearm vs. melee asymmetry (reframed: a scope-rule of C1)

- **Status:** `PLANNED` — **reframed**, lives inside `levelTierFlatten`.
- **Correction (vanilla already does part of this):** **Body** natively
  buffs melee (blunt / Street Brawler / Gorilla Arms / fists); **blades**
  scale mainly with **Reflexes**; Cool feeds crit/stealth. This
  *attribute-driven* path is **separate** from the level/tier *coefficient*
  C1 flattens. So C5 is not "add a Body term that doesn't exist".
- **Real scope:** make C1's flatten **asymmetric** — it must strip
  player-scaling from **firearms** (bullet independent of shooter) while
  **not** collaterally flattening the attribute→melee term (force still
  matters in a knife/fist fight). Optionally normalise the Body→melee
  relationship for realism afterward.
- **Hard dependency:** in-game verification of *which* path C1's `RPGManager`
  seam actually touches (attribute term vs level/tier coefficient) — same
  harness as C1. Until that is known, C5's exact code is undefined.
- **Dry criteria:**
  - [ ] Firearm per-hit damage independent of shooter attributes & level.
  - [ ] Melee retains Body/Reflexes attribute scaling post-flatten.
  - [ ] Parity both ways; kill-switch (own Gate sub-toggle) restores vanilla.
- **Mod-split:** inside the `levelTierFlatten` module (it defines what C1
  does/doesn't flatten), gated by its own sub-toggle.

## C6 — Organic notoriety / heat system (new — from design discussion)

- **Status:** `IDEA`
- **Motivation:** vanilla notoriety/wanted is a coarse, under-used
  continuous-ish system (crude tiers, near-binary decay). It is a strong
  *first* vehicle for "continuous value + organic decay" mechanics because,
  unlike C3, it does **not** fight the perk/point system — lower risk.
- **Target (to scope):** graduated, organic escalation; faction/location
  awareness; behaviour- and time-based decay; witness/evidence logic — a
  deeper heat model than the vanilla tier ladder.
- **Synergy:** shares design bricks with C3 (continuous value) and C4
  (decay curve, persistence) → a good lower-risk prototype for those
  mechanics before committing them to progression.
- **Candidate seam:** the wanted/prevention/heat system (e.g.
  `PreventionSystem` / wanted-level data) — confirm via the verification
  harness.
- **Risk:** medium (design-heavy, far fewer parity concerns than combat).
  **Mod-split:** its own mod, reusing C3/C4 building blocks.

## Suite doctrine — engine-adaptive first, deep overhaul on traction

The governing principle for every workstream, generalised from the phase-1
revert (do not fight unverified engine internals speculatively):

> **Adapt to the engine first.** Accept the concessions; the payoff is
> painless game updates and frictionless coexistence with the modding
> ecosystem. Treat a deep-overhaul variant (one that would eventually need
> dedicated ecosystem addons / hard external dependencies) as a **future
> migration gated on project traction** — designed for, never abandoned,
> but not paid for until the traction justifies the cost.

Applications already recorded: **C3** ships B (engine-adaptive) with A as the
traction-gated overhaul; **C4** prefers engine-native/piggyback persistence
and defers the CET/RED4ext companion; **C5** lives inside C1's seam rather
than adding a parallel system. New workstreams should state which side of this
line they sit on.

## Cross-cutting backlog

- **Symbol-verification harness is the top unblocker.** C1, C2a and C5 all
  gate on it (see the harness section above). C3, C4 and C6 *design* can
  progress without a game; their *code* does not.
- **Shared "continuous value + decay + persistence" toolkit:** C3, C4 and C6
  converge on the same primitives. Factor a shared module out **only once
  ≥2 of them actually need it** — do not build it speculatively.
- **Release packaging per module:** `release.yml` already builds
  `level-tier-flatten-*`. Add `ui-flatten-*` (and future modules) **only when
  each is dry** — deferred deliberately to avoid shipping unverified config.
- **Multi-repo extraction:** modules are folder/archive-isolated; document the
  extraction steps when the suite outgrows this repo.
