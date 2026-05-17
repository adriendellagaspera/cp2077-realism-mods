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

The flagship workstream of the **Realistic Arsenal** mod (weapons). It
absorbs what were separate tracks (C1 damage, C2a colour, C5 scope-rule, and
a loot/weapon-tier-removal idea) because they share one root cause — the
weapon tier system.

> **Component de-tiering is NOT here.** The scope-spike refuted the premise
> that weapon tiers and crafting-component tiers are the same data surface —
> they are two independent TweakDB surfaces. Component de-tiering is its own
> mod, **Realistic Components** (`../realistic-components/`); this mod is
> weapons only.

### Thesis

> The weapon tier/quality scale is meaningless. A weapon is a weapon — its
> identity comes from real attributes (archetype, ammo, condition,
> hit-location), not a hidden Common→Iconic ladder, a rarity rainbow, or a
> level delta.

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

**e — Loot / weapon-tier removal** (NEW) · `BLOCKED` (TweakDB-dump-gated) ·
spike "shape confirmed" conclusion **REFUTED** — see "refutation outcome"
- **Scope:** a same weapon at drop/vendor/upgrade is one object, not a
  Common→Iconic ladder. No mod removes the scale (gap holds — medium
  confidence, manual Nexus pass still advised).
- **Surface — premise REFUTED.** The spike claimed "flatten the `Quality.*`
  modifier `value` ⇒ tiers collapse". The adversarial review refuted this on
  public docs: `Quality.*` are `ConstantStatModifier` records with three
  flats (`statType`/`modifierType`/`value`); tier differentiation is *which*
  `Quality.*` record is appended to an item's `statModifiers` array (and
  `Items.*QualityRandomization`), **not** one shared scalar. Overriding bare
  `value` does not de-tier. A correct approach must be re-derived from a real
  TweakDB dump (the `Quality.*` bodies + the quality-assignment path), not
  the modifier magnitude.
- **Not redscript-harness-blocked, but equally TweakDB-dump-blocked.** "Pure
  data, not blocked" was misleading: the data paths/mechanism cannot be
  verified without a TweakDB dump, an epistemic gate as hard as facet a's
  `redscript.log`. The four YAML files are now honest dump-gated stubs (no
  shippable override), **not** a working scaffold.
- **Scope ceiling (unchanged):** the engine `RPGManager` scaling *shape* is
  not TweakXL-reachable; full engine removal stays with facet a
  (redscript, harness-blocked).

**f — Component / crafting de-tiering** — **SPLIT OUT** to the
[Realistic Components](../realistic-components/PROGRESS.md) mod. The
scope-spike refuted the "same data surface" premise (weapon `Quality.*` vs
recipe `RecipeElement` are independent), so this is a separate mod, not a
facet here.

**g — Weapon condition / decay** (NEW) · `COMPOSED` → Weapon Conditioning 10479
- Compose only the **decay/condition/jamming/repair** layer. Weapon
  Conditioning also ships a **tier-gate** ("no tier-up until repaired"; tier ↔
  enemy rarity) that *reinforces* the scale facet e removes; that layer becomes
  moot/contradictory here. The composition checklist must confirm the decay
  layer functions standalone with tiers gone; if it cannot be decoupled,
  weapon decay reverts to a gap to scope-spike.
- **This is WEAPON decay. It is NOT C4 SKILL decay.** See C4.

### Spike outcome — facet e (resolved 2026-05-17)

- [x] **Surface (later REFUTED):** the spike said facet e is pure TweakXL
      data that can progress while a/c stay blocked. The adversarial review
      refuted the *mechanism* (modifier-`value` override ≠ de-tier) and showed
      it is TweakDB-dump-gated, not free. See "refutation outcome" below.
- [x] **Cascade claim — REFUTED.** Weapon quality (`Quality.*` stat-modifier
      records + RPGManager) and crafting-component tiers (distinct
      `Items.*Material*` records referenced by `RecipeData`/`RecipeElement`)
      are **two independent TweakDB surfaces**. This refutation is *why*
      component de-tiering was split out into the Realistic Components mod.
- [x] **Build-vs-compose:** facet e is **BUILD** (TweakXL data, in-mod). No
      mod de-tiers weapons without presupposing tiers.
- [x] **Scope ceiling accepted:** data-flatten the `Quality.*` records/curves
      + loot/vendor/upgrade entries; the engine `RPGManager` scaling shape is
      not TweakXL-reachable and stays with facet a (harness-blocked).
- [x] **Packaging:** facet e ships as a TweakXL data archive, separate from
      the redscript facets a/c.
- [x] **Resolved enacted decisions:** the "same data surface" premise was
      dropped (component de-tiering → Realistic Components mod); Preem
      Weaponsmith 9692 / Enhanced Craft 4378 reclassified as *adjacent
      customisation* mods (not composed for de-tiering — they presuppose
      tiers). See README Composition.

### Facet e — deliverable shape (post-refutation)

TweakXL skeleton at `r6/tweaks/realisticArsenal/`, four files — **all four are
now inert dump-gated stubs**; there is no shippable override. The earlier
"confirmed-structure CORE" label on 00/02 was **retracted** (refuted, see
below):

- `00-quality-stats.yaml` — was an active `Quality.* value` override; the
  override premise is refuted (wrong mechanism). Now an inert stub; the old
  body is preserved commented as documented-wrong, do-not-uncomment.
- `02-quality-uidata.yaml` — was an active UIData override with an invented
  `colorTheme` field / wrong scalar type. Now an inert stub (same treatment).
  Load-order/redundancy note vs Rarity Color Removed 20767 / facet c kept.
- `01-quality-curves.yaml` — inert stub (quality→damage curve), unchanged.
- `03-loot-vendor-upgrade.yaml` — inert stub (loot/vendor/upgrade quality
  assignment, the largest unknown), unchanged.

**Safety model (corrected).** Earlier headers claimed "wrong TweakDBID = a
silent no-op, no error". This is **false and inverted**: per the psiberx
TweakXL docs an unknown name *creates a new (junk) flat*, and ambiguous
implicit value types can *throw a load error*. Wrong paths therefore fail
*semantically* (intended record untouched) **and** can pollute TweakDB / error
— never a safe no-op. All four headers were corrected.

**Uninstall caveat (corrected).** TweakXL is non-persistent, so deleting the
folder reverts the *data*; but any item that already rolled a quality has it
serialised in the save — already-spawned items are not retroactively
de-tiered. "Clean uninstall" is true for the data layer only.

### Facet e — falsifiable claims (for refutation)

Every assumption a refutation agent must attack:

1. The `Quality.*` record paths in `00-quality-stats.yaml` (`Quality.Common`,
   `.CommonPlus`, `.Uncommon[Plus]`, `.Rare[Plus]`, `.Epic[Plus]`,
   `.Legendary[Plus]`, `.IconicItem`) are the real patch-2.x TweakDB record
   names — UNVERIFIED; wrong IDs do **not** safely no-op (they create junk
   flats / can throw — see refutation outcome).
2. `value` is the correct (and the SOLE) flat lever on the constant
   stat-modifier records — there may be other quality flats, or `value` may be
   the wrong flat name.
3. The UIData flat names in `02-quality-uidata.yaml` (`uiData` / `colorTheme`)
   are the real rarity-colour/label flats — UNVERIFIED, structurally-likely
   shape only.
4. Quality in 2.x is genuinely stat-modifier driven feeding `BaseStats.Quality`
   (the spike's core premise) — if quality has another primary source,
   flattening these records does not de-tier.
5. Flattening 00 + 02 alone is insufficient: a quality→damage curve residual
   (stub 01) and loot/vendor/upgrade quality ASSIGNMENT (stub 03) remain
   tier signals not addressed by the shipped core.
6. The engine RPGManager scaling residual (out of scope, facet a) is actually
   neutralised "enough" that data-flatten yields tier-invariant behaviour —
   facet e accepts this residual untested; it may still scale.
7. No quality-keyed economy side-effect: de-tiering does not collapse/distort
   craft cost, upgrade cost, vendor buy/sell pricing, or scrap/shard yields
   (these are commonly keyed on quality — UNCHECKED pending dump).
8. No conflict / load-order hazard with composed Weapon Conditioning 10479
   (its tier-gate reinforces the scale facet e removes) or Rarity Color
   Removed 20767 (overlapping UIData writes — last-write-wins assumed benign).
9. The facet is verifiable: in fact there is NO in-game verification (data is
   pure-TweakXL so not harness-blocked, but "CI green + parses" proves
   nothing about whether tiers actually flatten in a real build).

### Facet e — refutation outcome (2026-05-17)

Adversarial review (sourced: psiberx TweakXL wiki, CDPR/REDmodding docs).
Verdicts on the 9 claims:

- **2 — REFUTED (BLOCKER):** `Quality.*` are `ConstantStatModifier`
  (`statType`/`modifierType`/`value`); tier = *which* `Quality.*` is appended
  to an item's `statModifiers` (+ `Items.*QualityRandomization`), not one
  scalar. Overriding `value` does not de-tier.
- **3 — REFUTED (MAJOR):** `02` used an inline-typed UIData with an invented
  `colorTheme` field and a String where a CName/TweakDBID is expected.
- **Unknown-unknown — REFUTED (BLOCKER):** the "wrong name = silent no-op"
  safety model is *inverted* — TweakXL creates junk flats / can throw on
  unknown names.
- **1 SURVIVES-weak** (names exist) · **4 SURVIVES** (premise sound, impl
  not) · **5 SURVIVES** (and understated) · **6/7/8 UNVERIFIABLE**
  (dump/game-gated) · **9 SURVIVES — the headline:** no in-game verification;
  not redscript-blocked but equally dump-blocked.
- Uninstall claim over-broad (already-rolled item qualities persist in saves).

**Actions taken:** facet e `IMPLEMENTED → BLOCKED (TweakDB-dump-gated)`; spike
"shape confirmed" marked **REFUTED**; `00`/`02` retracted from "CORE" to inert
stubs (old bodies preserved commented as documented-wrong); the inverted
safety model corrected in all four file headers; uninstall caveat corrected.
A correct facet e must be re-derived from a real TweakDB dump against the
*quality-assignment* mechanism, not modifier magnitude.

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
weapon-tier-removal gap to build.

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
- [ ] 20767 Rarity Color Removed — data-side colour removal; alternative or
      complement to W1 facet c.

(Crafting/component-mod re-verification — 9692, 4378, 16154, 11880, 22824 —
moved to the Realistic Components mod's PROGRESS.)

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
