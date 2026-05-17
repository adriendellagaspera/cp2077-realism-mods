# Realistic Components — progress & workstream tracker

Actionable state. Vision and locked decisions live in
[`README.md`](./README.md). This mod has a single workstream.

## Status legend

- `PLANNED` — scoped, not yet built.
- `SCOPE-SPIKE` — time-boxed investigation; deliverable is a decision.
- `BLOCKED` — cannot progress until a named blocker clears.
- `DONE` — shipped (data written + verified in a real install).

## RC1 — Component / crafting de-tiering

- **Status:** scaffold + generator landed; bulk pending TweakDB dump
  (was `PLANNED`; scope-spike done 2026-05-17 — surface decided). The
  hand-written structural core, the two generated-file stubs, and the
  build-time generator now exist; the hundreds of recipe/disassembly
  overrides stay empty until a real dump is fed to the generator.
- **Goal:** point every tiered crafting-component reference at one real,
  non-tiered component; make disassembly yield that same component.
- **Surface (decided):** **BUILD via TweakXL data, no redscript.** Components
  are `Items.*Material*` records; recipes reference them via
  `RecipeData` / `RecipeElement` ingredient entries. Rewrite each recipe's
  `RecipeElement` ingredients and the disassembly-yield records to the single
  real component. **Not harness-blocked** (pure data — can progress while
  Realistic Arsenal facets a/c stay blocked).
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
  - **Core (hand-written, verifiable):**
    `r6/tweaks/realisticComponents/00-core.yaml` — declares the single real
    target component (placeholder `Items.RealScrapComponent`, MUST become a
    dump-confirmed real component or an ArchiveXL item before ship) and 2–3
    representative recipe retargets as a STRUCTURAL PROOF of the real TweakXL
    syntax (per-flat `elements[N].ingredient.item:` and full `elements:` array
    replace). Header carries the epistemic caveats, the silent-fail warning,
    and uninstall = delete the folder.
  - **Generated (do not hand-edit):**
    `10-recipes.generated.yaml` + `20-disassembly.generated.yaml` — banner
    stubs, intentionally empty (`{}`) until a dump exists; emitted by the
    tool. Hand-edits are overwritten.
  - **Tool (build-time only, NOT run by the game):**
    `tools/gen_realistic_components.py` — stdlib-only Python, `argparse`,
    runs and exits non-zero with a clear message when no dump is supplied.
- **Generation strategy:** the full recipe + disassembly record set is
  hundreds of records and CANNOT be enumerated blind — a missed recipe
  silently leaks a tiered component (same silent-failure class as wrong
  redscript symbols). So only the small structural core is hand-authored;
  the bulk is machine-generated. The tool ingests a WolvenKit/RED4ext
  TweakDB dump JSON (record-keyed object OR flat-list with
  `<RecipeID>.elements_inlineN` sibling sub-records — both shapes
  normalised), filters every `gamedataCraftingRecipe_Record`, finds
  `.elements[].ingredient.item` matching the `*Material*`/tier regex (catches
  the un-enumerated tail, not just the five core IDs), and emits per-recipe
  overrides — Form A (per-flat, identity-only, count-preserving) by default,
  Form C (array replace) only when a recipe carries multiple distinct tier
  ingredients. A second, explicitly heuristic disassembly pass scans
  plausible yield paths on item records. Every run prints a summary (record
  count, recipes matched, core IDs seen) and warns if recipes exist but none
  matched — that warning means the spike symbols are wrong; do not ship.
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
   records and emits an empty file — a silent no-op.
2. **Recipe-element type/structure.** Each element is a
   `gamedataRecipeElement_Record` shaped
   `{ ingredient: ItemQuantity{ item, quantity }, quantity }`. If the field
   nesting differs, ingredient extraction silently yields nothing.
3. **Ingredient field path.** The retarget path is
   `.elements[].ingredient.item`. A wrong path makes every per-flat (Form A)
   override a silent no-op with no TweakXL error.
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
