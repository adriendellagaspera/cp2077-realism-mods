# Realistic Arsenal — progress & workstream tracker

Actionable state of every workstream. Vision and locked decisions (including
the composed-vs-built rationale) live in this folder's
[`README.md`](./README.md); this file tracks in-progress and planned work,
including the composition re-verification checklist below.

## Status legend

- `DONE` — merged to `main` (dry: CI green + in-game symbol verified).
- `IMPLEMENTED` — code written & parses, **not yet dry** (symbol unverified).
- `PLANNED` — scoped, not yet coded.
- `IDEA` — direction noted, scope/risk not pinned.
- `BLOCKED` — cannot progress until a listed blocker clears (the shared
  symbol-verification harness).
- `SCOPE-SPIKE` — a time-boxed investigation whose deliverable is a
  build/compose decision, not shippable code.
- `COMPOSED` — concern delegated to a named external mod per the ecosystem
  audit; this mod ships nothing for it.
- `DEFERRED` — scoped and valid but parked behind a **named** blocker (state
  it; distinct from `BLOCKED`, which is specifically the harness).
- `DROPPED` — removed from the roadmap (audit verdict `INVALIDATED` or
  composed away); kept only as a recorded decision.

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

## W1 — Weapon Identity (the tier scale is meaningless)

The single flagship workstream. It absorbs what were separate tracks (C1
damage, C2a colour, C5 scope-rule, a new loot-tier-removal idea, and the
crafting/components track) because they share one root cause — the tier
system — and, for the data facets, one TweakXL/data surface.

### Thesis

> The tier/quality scale is meaningless. A weapon is a weapon — its identity
> comes from real attributes (archetype, ammo, condition, hit-location), and it
> is built and maintained from real, non-tiered components and materials.
> Removing the weapon-tier scale and removing the component-tier scale are the
> *same* data surface, so they are one workstream, not two.

### Facets

**a — Damage de-scaling** · `IMPLEMENTED` · `BLOCKED` (in-game symbol
verification)
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

**b — Asymmetric scope-rule** (was C5) · `PLANNED` — lives inside facet a's
seam.
- **Correction (vanilla already does part of this):** **Body** natively buffs
  melee (blunt / Street Brawler / Gorilla Arms / fists); **blades** scale
  mainly with **Reflexes**; Cool feeds crit/stealth. This *attribute-driven*
  path is **separate** from the level/tier *coefficient* facet a flattens.
- **Real scope:** make facet a's flatten **asymmetric** — strip player-scaling
  from **firearms** (bullet independent of shooter) while **not** collaterally
  flattening the attribute→melee term.
- **Hard dependency:** in-game verification of which path the `RPGManager` seam
  actually touches — same harness as facet a.
- **Dry criteria:**
  - [ ] Firearm per-hit damage independent of shooter attributes & level.
  - [ ] Melee retains Body/Reflexes attribute scaling post-flatten.
  - [ ] Parity both ways; kill-switch (own sub-toggle) restores vanilla.

**c — UI colour neutralisation** (was C2a) · `IMPLEMENTED` · `BLOCKED`
- **Files:** `uiFlatten.reds` (Policy/Gate),
  `uiFlatten_cp2077-{2x,1x}.reds` (quality→colour resolver wrap).
- **Scope:** coerce the quality used for *colour* resolution to a single
  neutral quality so the rarity rainbow stops signalling power. Item
  stats/identity untouched.
- **Blocker:** resolver controller name (`UIInventoryItemsManager` /
  `UIItemColorTheme`) best-effort; confirm/adjust per patch.
- **Composition alternative:** Rarity Color Removed 20767 (data-side) — see
  README Composition; either path achieves a colourless rarity signal.
- **Dry criteria:**
  - [ ] `redscript.log` clean or switched to fallback.
  - [ ] Common vs iconic of same archetype render identical colour in
        inventory, tooltip, world pickup.
  - [ ] Kill-switch off → vanilla colours return.

**d — UI level-hiding** (was C2b/C2c/C2d) · `PLANNED` sub-items.
- C2b enemy nameplate level · C2c item "required level" tooltip · C2d
  level-up / character-screen readout. Each blanks a level label via
  `UiFlattenPolicy.HiddenLevelText()`. Controllers' private field names are
  unknown — do **not** speculatively code until confirmed (phase-1 revert
  lesson). Dry per sub-item: label gone, function intact, kill-switch restores.

**e — Loot / weapon-tier removal** (NEW) · `PLANNED` (spike done — surface
decided)
- **Scope:** a same weapon at drop/vendor/upgrade is one object, not a
  Common→Iconic ladder. No mod removes the scale (gap holds — medium
  confidence, manual Nexus pass still advised).
- **Surface (decided):** **BUILD via TweakXL data, no redscript.** Override the
  `Quality.*` stat-modifier records + quality stat curves so every tier
  resolves identically, and rewrite loot/vendor/upgrade quality entries.
  `UIData` carries the rarity colour/label (data-side too).
- **Scope ceiling:** the engine `RPGManager` scaling *shape* is not
  TweakXL-reachable; removing it entirely would need redscript (=> harness-
  blocked). Facet e is therefore explicitly scoped to **flatten the data
  curves and accept the neutralised engine residual**, not "remove the engine
  path". Full engine removal stays with facet a (harness-blocked).
- **Not harness-blocked** (pure data).

**f — Component / crafting de-tiering** (NEW) · `PLANNED` (spike done — surface
decided)
- **Scope:** point every tiered component reference at one real, non-tiered
  component. **BUILD via TweakXL data:** rewrite each recipe's
  `RecipeElement` ingredients and the disassembly-yield records to the single
  real component. Pure data, **not harness-blocked**.
- **Rejected:** Immersive Components 11880 (renames tiers, does not remove
  them). **Also do NOT compose Preem Weaponsmith 9692 / Enhanced Craft 4378
  for de-tiering** — the spike found both *presuppose* tiers (Enhanced Craft
  multiplies component cost by tier) and pull redscript deps; composing them
  here would reinforce the scale this facet removes. (They remain *adjacent*
  customisation mods, not part of de-tiering.)
- **Main risk:** large recipe surface — every craftable + disassembly record;
  a missed recipe leaks a tiered component. Needs an exhaustive recipe sweep.

**g — Weapon condition / decay** (NEW) · `COMPOSED` → Weapon Conditioning 10479
- Compose only the **decay/condition/jamming/repair** layer. Weapon
  Conditioning also ships a **tier-gate** ("no tier-up until repaired"; tier ↔
  enemy rarity) that *reinforces* the scale facet e removes; that layer becomes
  moot/contradictory here. The composition checklist must confirm the decay
  layer functions standalone with tiers gone; if it cannot be decoupled,
  weapon decay reverts to a gap to scope-spike.
- **This is WEAPON decay. It is NOT C4 SKILL decay.** See C4.

### Spike outcome — facets e + f (resolved 2026-05-17)

- [x] **Surface:** both e and f are **pure TweakXL data-record edits, no
      redscript** → neither inherits the harness `BLOCKED` state.
- [x] **Cascade claim — REFUTED.** Weapon quality (`Quality.*` stat-modifier
      records + RPGManager) and crafting-component tiers (distinct
      `Items.*Material*` records referenced by `RecipeData`/`RecipeElement`)
      are **two independent TweakDB surfaces**. Removing weapon tiers does
      **not** cascade to components. Facet f is a **separate, independent
      recipe-graph rewrite**, not a free consequence of facet e.
- [x] **Build-vs-compose:** both **BUILD** (TweakXL data, in-mod). Compose is
      rejected for both — no mod de-tiers without presupposing tiers.
- [x] **Output is data** (TweakXL YAML), so e+f are *not* harness-blocked —
      they can progress while facets a/c stay blocked.
- [x] **Packaging:** ship e+f as one TweakXL data archive (one thesis), kept
      separate from the redscript facets a/c.

**Implications that touch earlier locked decisions (raise before editing
those):**
- The merged thesis wording "removing weapon tiers and removing component
  tiers are the *same* data surface" (README vision + CHANGELOG) is now
  **factually wrong** — they are two independent data surfaces (still one mod,
  one thesis, but two edits). Needs a wording correction.
- README Composition currently lists Preem Weaponsmith 9692 / Enhanced Craft
  4378 under crafting; the spike says these reinforce tiers and must not be
  composed for de-tiering. Needs reconciliation.

## C3 — Continuous "learn-by-doing" progression

- **Status:** `DEFERRED` — compose Skillful 9309/9281 as interim.
- The architecture analysis stands as recorded design: keep the point system
  and unbottle the single point-award seam in `PlayerDevelopmentData`
  (engine-adaptive **B**); the continuous-value overhaul (**A**) is the
  traction-gated future migration. Build is deferred under the suite doctrine;
  the interim feel is covered by composition (audit verdict DEFERRED + COMPOSE).
- **Risk:** medium. Coding blocked by the harness; design unblocked.

## C4 — Skill regression / decay

- **Status:** `DEFERRED` — persistence blocker (redscript has no clean per-mod
  persisted save field).
- **Disambiguation:** C4 is **SKILL** decay. It is **NOT** weapon-condition
  decay. Weapon decay is **W1 facet g** (composed: Weapon Conditioning 10479).
  Do not conflate the two.
- **Researched constraint:** the periodic tick is easy (game callbacks / delay
  system). The real obstacle is persistence: decay state must either (a) ride a
  CET/RED4ext companion (hard external dependency); (b) piggyback an
  already-persisted player stat/quest fact (hacky, patch-fragile); or (c) wait
  until C3 exists (decay is only meaningful with a continuous value to decay).
- **Recommendation (suite doctrine):** prefer engine-native/piggyback
  persistence first; defer the CET/RED4ext companion until traction justifies a
  hard dependency. Treat persistence as its own isolated spike before any code.
- **Risk:** high — new persisted subsystem.

## C6 — Organic notoriety / heat system

- **Status:** `DROPPED` — `COMPOSED` (Enemies of Dogtown 27898 + Night City
  Remembers 29008 + NCPD Duty Expansion 21547). Kept as a recorded decision.
- The vanilla wanted system is coarse; rather than build a heat model, the
  ecosystem already delivers graduated escalation, faction/location awareness
  and behavioural decay across those three mods. See README Composition.

## Consumables

- **Status:** `COMPOSED` — Immersive Grenades 25334 (finite/inventory model).

## Suite doctrine — engine-adaptive first, deep overhaul on traction

The governing principle for every workstream, generalised from the phase-1
revert (do not fight unverified engine internals speculatively):

> **Adapt to the engine first.** Accept the concessions; the payoff is
> painless game updates and frictionless coexistence with the modding
> ecosystem. Treat a deep-overhaul variant (one that would eventually need
> dedicated ecosystem addons / hard external dependencies) as a **future
> migration gated on project traction** — designed for, never abandoned,
> but not paid for until the traction justifies the cost.

**Compose-first is also a prioritisation rule, not only an implementation
rule.** Before scoping any new workstream, check the ecosystem first: a mature,
configurable mod that serves the thesis is the **default** (record it in README
Composition); build only the gap nothing covers; scope-spike anything
ambiguous. This was generalised from the survey that collapsed
C6/consumables/skills/weapon-decay into compositions and left only the
tier-removal/crafting gap to build.

Applications recorded: **C3** ships B (engine-adaptive) with A traction-gated;
**C4** prefers engine-native/piggyback persistence; **W1 facet b** lives inside
facet a's seam rather than adding a parallel system; **C6/consumables/weapon-
decay** are composed.

## Composition re-verification (planned · manual)

Composed dependencies are a **locked direction but unconfirmed**: Nexus is not
auto-fetchable (HTTP 403), so the verdicts in README Composition are
search-snippet level. Before any composition is relied upon, the maintainer
confirms each on the real mod page / in a real install:

- [ ] 24244 No Enemy Scaling — maintained for current patch; data-only;
      coexists with the redscript damage flatten.
- [ ] 1712 Damage Scaling and Balance — config surface; alternative to 24244.
- [ ] 27898 / 29008 / 21547 — together approximate organic heat; no hard
      conflict with the damage flatten.
- [ ] 25334 Immersive Grenades — consumable scope only; no tier dependency.
- [ ] 9309 / 9281 Skillful — scales effects off proficiency without fighting
      the point system; acceptable C3 interim.
- [ ] 10479 Weapon Conditioning — confirm the tier-gate logic (no tier-up
      until repaired; tier ↔ enemy rarity) **and** that the decay/condition/
      jamming/repair layer still functions standalone with tiers removed. If
      it cannot be decoupled, W1 facet g reverts from `COMPOSED` to a
      scope-spike.
- [ ] 9692 Preem Weaponsmith — adds real modules (muzzles/triggers, smart/tech
      conversion, recoil/fire-rate); optional progression locks; no hard tier
      dependency.
- [ ] 4378 Enhanced Craft — presets / skin / name / damage-type; non-tiered.
- [ ] 16154 Immersive Crafting Access — −30% component cost; optional economy.
- [ ] 11880 Immersive Components — confirm the rejection: only renames tiered
      components, does NOT remove tiers; does not serve the thesis.
- [ ] 22824 Immersive Crafting — restricts crafting to the stash (craft-side);
      adjacency to the Immersive Scraping mod (disassemble-side).
- [ ] 20767 Rarity Color Removed — data-side colour removal; alternative or
      complement to W1 facet c.

## Cross-cutting backlog

- **Symbol-verification harness is the top unblocker.** W1 facets a, c (and b
  by dependency) gate on it. C3/C4 *design* can progress without a game; their
  *code* cannot.
- **Survey the ecosystem before scoping** any new workstream — record composed
  dependencies in README Composition; build only the gap nothing covers.
- **Shared "continuous value + decay + persistence" toolkit:** C3, C4 and the
  composed heat layer converge on the same primitives. Factor a shared module
  out **only once ≥2 actually need it** — do not build it speculatively.
- **Release packaging:** `release.yml` builds `realistic-arsenal-*` from the
  facet a/c files. Extend only when each facet is dry — deferred deliberately
  to avoid shipping unverified config.
- **Multi-repo extraction:** the mod is folder/archive-isolated; document the
  extraction steps when it outgrows this repo.
