# Realistic Components — progress & workstream tracker

Actionable state. Vision and locked decisions live in
[`README.md`](./README.md). This mod has a single workstream.

## Status legend

- `PLANNED` — scoped, not yet built.
- `SCOPE-SPIKE` — time-boxed investigation; deliverable is a decision.
- `BLOCKED` — cannot progress until a named blocker clears.
- `DONE` — shipped (data written + verified in a real install).

## RC1 — Component / crafting de-tiering

- **Status:** `BLOCKED` (TweakDB-dump-gated) · structural syntax
  **UNCONFIRMED and partly REFUTED by docs** (adversarial review 2026-05-17).
  A skeleton + a generator exist, but the generator's schema is contradicted
  by the v1ld crafting gist and the override syntax by the psiberx TweakXL
  docs — fed a real dump it would emit empty/invalid output. This is **not**
  a verified core; it is a refuted scaffold pending re-derivation.
- **Goal:** point every tiered crafting-component reference at one real,
  non-tiered component; make disassembly yield that same component.
- **Surface — premises REFUTED.** Intended approach was BUILD via TweakXL
  data (no redscript) over `RecipeData`/`RecipeElement`. The review found:
  - element shape is **flat** (`amount`, `ingredient: Items.X` a direct
    TweakDBID) per the v1ld gist — **not** nested
    `ingredient: ItemQuantity{ item, quantity }`. (claim 2 — BLOCKER)
  - TweakXL has **no documented `array[index].subfield` flat path**; arrays
    are wholesale-replaced or mutated via `!append`/`!remove`/`!merge`. Form A
    (`elements[0].ingredient.item:`) is likely invalid syntax. (claim 3)
  - `!append-once` (Form C) **appends**, it does not replace — vanilla tiered
    ingredients stay live. (claim 9 — refuted as a replace mechanism)
  - the `gamedataCraftingRecipe_Record` type string is likely the long
    schema name; real dumps/TweakXL use the short form. (claim 1)
  Net: **not redscript-harness-blocked, but equally TweakDB-dump-gated AND
  schema-refuted** — strictly worse than "unverified".
- **Why a separate mod (cascade refuted):** weapon quality (`Quality.*`
  stat-modifier records + `RPGManager`) and component tiers
  (`Items.*Material*` via `RecipeData`/`RecipeElement`) are **two independent
  TweakDB surfaces**. Overriding weapon `Quality.*` does nothing to recipe
  ingredients. This refutation of the "same surface" premise is exactly why
  component de-tiering was split out of Realistic Arsenal.
- **Build, not compose:** no mod de-tiers the component graph — those that
  touch crafting (Preem Weaponsmith, Enhanced Craft) *presuppose* tiers.
- **Main risk:** large recipe surface — every craftable recipe + every
  disassembly-yield record. A missed recipe leaks a tiered component. Needs
  an exhaustive recipe sweep (consider a generated YAML build step; runtime
  is still pure TweakXL data).
- **Confidence:** the "no mod already does this" gap holds at medium
  confidence (Nexus fetch is 403-blocked) — run the manual Nexus pass below
  before finalising.

- **Deliverable shape (core vs generated vs tool):**
  - **Core (hand-written — NOT verified; syntax refuted):**
    `r6/tweaks/realisticComponents/00-core.yaml` — was presented as a
    "structural proof of the real TweakXL syntax"; that syntax
    (`elements[N].ingredient.item:`, nested ingredient) is **documented-wrong**
    (see Surface). The placeholder `gamedataItem_Record` node was **removed**
    (it risked clobbering an item on apply). The file is now an inert,
    documented-wrong stub. Its "silent no-op" safety note was **inverted** and
    corrected: an unknown TweakXL name creates a junk flat / can throw — not a
    safe no-op.
  - **Generated (do not hand-edit):**
    `10-recipes.generated.yaml` + `20-disassembly.generated.yaml` — banner
    stubs, intentionally empty (`{}`) until a dump exists; emitted by the
    tool. Hand-edits are overwritten.
  - **Tool (build-time only, NOT run by the game):**
    `tools/gen_realistic_components.py` — stdlib-only Python, `argparse`,
    runs and exits non-zero with a clear message when no dump is supplied.
- **Generation strategy (generator REFUTED against real schema):** the
  enumerate-bulk-from-a-dump *idea* stands (the record set is too large to
  hand-write; a missed recipe leaks a tiered component). But the shipped
  `tools/gen_realistic_components.py` is built on the refuted nested
  `ingredient.item`/`quantity` shape and the undocumented `array[index]`
  flat path, and Form C uses append-not-replace. Run against a real
  WolvenKit dump it would almost certainly emit `{}` (its own
  "recipes-exist-but-none-matched" guard *does* fire — verified — which is
  the one working safety net). Before any dump work the generator must be
  re-derived against the v1ld-confirmed flat element shape (`amount` /
  `ingredient` as a direct TweakDBID), a documented array-mutation mechanism
  (wholesale `elements:` replace or `!remove`+`!append`, not index paths),
  and a disassembly pass keyed on the correct record family (not
  `gamedataItem_Record` heuristics). It is a non-functional scaffold, not a
  ready tool.
- **Uninstall / kill switch:** delete the folder
  `r6/tweaks/realisticComponents/` in its entirety. TweakXL applies no
  override not present on disk; no load order, migration, or residual state.
- **Exit to `DONE`:** a real TweakDB dump fed to the generator; generated
  files populated and the run summary sanity-checked (match count vs known
  recipe volume, all five canonical core IDs seen); target ID replaced with
  a dump-confirmed real component / verified ArchiveXL item; in a real
  install, no tiered component appears in any recipe or disassembly; then
  add the release archive (deferred until now).

### RC1 — falsifiable claims (for refutation)

Every assumption a refutation agent must attack. None is verified against a
real dump or a real game install; all are research-spike level.

1. **Record-type name.** Crafting recipes are records of type
   `gamedataCraftingRecipe_Record`. If wrong, the recipes pass matches zero
   records and emits an empty file (the "none matched" guard catches this).
2. **Recipe-element type/structure.** Each element is a
   `gamedataRecipeElement_Record` shaped
   `{ ingredient: ItemQuantity{ item, quantity }, quantity }`. If the field
   nesting differs, ingredient extraction silently yields nothing.
3. **Ingredient field path.** The retarget path is
   `.elements[].ingredient.item`. A wrong/undocumented path is not a safe
   no-op — TweakXL creates a junk flat / can throw (and `array[index]` paths
   are undocumented; see refutation outcome).
4. **Inline sub-record naming.** Unnamed array sub-records are named
   `<RecipeID>.elements_inlineN` and referenced by TweakDBID from the parent
   `elements` flat. If the dump uses a different inline convention the
   flat-list path drops those elements.
5. **The `Items.*Material1` core IDs.** The canonical tier components are
   `Items.CommonMaterial1 / UncommonMaterial1 / RareMaterial1 /
   EpicMaterial1 / LegendaryMaterial1`. If these IDs are wrong (or the core
   set differs), the "core covered?" summary check is meaningless.
6. **The `*Material*` tail assumption.** The tier-component family is
   captured by the `*Material[0-9]*` regex and the long tail follows that
   naming. Any tier component NOT matching the regex is silently missed and
   leaks back into the economy.
7. **Disassembly-yield location (WEAKEST CLAIM).** Disassembly yields live on
   the scrapped item's record / an RPGManager disassembly path, reachable via
   one of the scanned heuristic flat paths. This is the least certain claim;
   the disassembly pass is explicitly heuristic and may match the wrong
   paths, miss the real ones, or both.
8. **Missed-recipe completeness.** That a single dump-driven sweep with this
   regex actually covers ALL recipes. Any recipe the dump omits, or that
   references a tier component by an unexpected path, silently leaks a tiered
   component (the core silent-failure risk).
9. **Recipe validity / economy when collapsing arrays.** Form C array
   replace collapses multiple distinct tier ingredients onto one component;
   this can change ingredient COUNT and cost, not just identity, and may
   produce degenerate or rebalanced recipes.
10. **Conflict with Enhanced Craft tier-cost scaling.** Enhanced Craft (and
    similar) multiply component cost by tier; running alongside a de-tiered
    component graph, those tier assumptions conflict and may distort cost.
11. **Target component resolves at runtime.** The chosen `--target` ID is a
    real vanilla component or a runtime-present ArchiveXL item. A
    non-resolving TweakDBID makes every retargeted recipe uncraftable, with
    no compile-time error from TweakXL.
12. **No in-game verification.** Nothing here has been observed working in a
    real Cyberpunk 2077 install; all behaviour is inferred.

### RC1 — refutation outcome (2026-05-17)

Adversarial review (sourced: psiberx TweakXL wiki, CDPR/REDmodding docs,
v1ld crafting gist; generator run empirically). Verdicts on the 12 claims:

- **1 — REFUTED (MAJOR):** `gamedataCraftingRecipe_Record` exact-string match
  likely matches zero real records (long vs short schema name; recipes may be
  `craftingRecipe:` on a package, not loose records).
- **2 — REFUTED (BLOCKER):** real element shape is flat (`amount`,
  `ingredient` = direct TweakDBID), not nested `ingredient.item`/`quantity`;
  generator extraction yields nothing on real data.
- **3 — REFUTED (BLOCKER):** no documented TweakXL `array[index].subfield`
  flat path; Form A is likely invalid syntax.
- **9 — REFUTED (MAJOR):** Form C `!append-once` appends, does not replace —
  vanilla tiered ingredients remain live; degenerate recipes.
- **7 — REFUTED as guesswork (MAJOR):** disassembly paths are uncorroborated
  heuristics on the wrong record family.
- **4, 8, 10 — UNVERIFIABLE** (dump/game-gated) · **5 SURVIVES**
  (`*Material1` IDs) · **6 SURVIVES w/ caveat** (regex false-positive risk) ·
  **11 BLOCKER (acknowledged):** placeholder target + an item-defining node
  that could clobber on apply · **12 SURVIVES — headline:** nothing
  observed in a real install.
- Generator is internally consistent **against its own invented schema**;
  the "none matched" guard fires correctly — the one real safety net.

**Actions taken:** RC1 → `BLOCKED` (TweakDB-dump-gated, schema-refuted);
"verifiable core" framing retracted; the clobber-risk `gamedataItem_Record`
node removed from `00-core.yaml` and the file made an inert documented-wrong
stub; inverted "silent no-op" safety wording corrected here and in the files;
generator marked a non-functional scaffold with the required re-derivation
(flat `amount`/`ingredient`, documented array mutation, correct disassembly
family) recorded. Re-derivation is itself dump+verification gated.

## Composition re-verification (planned · manual)

Crafting/component-mod verdicts in README Composition are search-snippet
level (Nexus 403). Confirm each on the real mod page / in a real install:

- [ ] 9692 Preem Weaponsmith — confirm it presupposes tiers and pulls
      redscript deps (so: adjacent customisation only, not composed for
      de-tiering).
- [ ] 4378 Enhanced Craft — confirm it scales component cost by tier
      (presupposes tiers; adjacent only).
- [ ] 16154 Immersive Crafting Access — −30% component cost; optional,
      tier-agnostic.
- [ ] 11880 Immersive Components — confirm the rejection: only renames tiered
      components, does NOT remove tiers.
- [ ] 22824 Immersive Crafting — restricts crafting to the stash (craft-side);
      adjacency to the Immersive Scraping mod (disassemble-side).

## Packaging

Deferred: no archive / CI presence entry until RC1 has real data files
(repo discipline — package only a module that exists). When ready, mirror
the per-mod folder/archive pattern (`realistic-components-*`).
