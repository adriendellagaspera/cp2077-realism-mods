#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Realistic Components RC1 — recipe / disassembly de-tiering generator.

#############################################################################
# REFUTED SCHEMA — NON-FUNCTIONAL SCAFFOLD — DO NOT USE AS-IS
#############################################################################
Adversarial review (2026-05-17; psiberx TweakXL wiki, CDPR docs, v1ld
crafting gist) found this generator's schema is contradicted by the docs:

  * Element shape is FLAT — `amount` + `ingredient: Items.X` (a direct
    TweakDBID) — NOT the nested `ingredient: {item, quantity}` / `quantity`
    this tool extracts. Against a real WolvenKit dump every recipe is
    silently skipped (extraction returns None) -> empty output.
  * TweakXL has NO documented `array[index].subfield` flat path; Form A
    (`elements[0].ingredient.item:`) is likely invalid syntax.
  * Form C uses `!append-once`, which APPENDS — it does not replace; vanilla
    tiered ingredients would remain live.
  * The recipe record-type string is likely the long schema name; real
    dumps/TweakXL use the short form -> zero matches.
  * The disassembly pass keys on `gamedataItem_Record` heuristics — wrong
    record family.

The tool is internally consistent against its own (invented) schema and its
"recipes exist but none matched" guard does fire — that guard is the only
real safety net. It MUST be re-derived (flat `amount`/`ingredient`,
short record type, documented array mutation instead of index paths,
correct disassembly family) AND verified against a real TweakDB dump in a
real install before it can emit shippable YAML. Until then it is a
scaffold, not a working generator.
#############################################################################

WHAT THIS IS
    A BUILD-TIME tool. It is NOT run by the game and NOT loaded by TweakXL.
    It reads a TweakDB dump, finds every crafting recipe (and disassembly
    record) that references a tiered / `*Material*` crafting component, and
    emits the bulk TweakXL override YAML into:

        r6/tweaks/realisticComponents/10-recipes.generated.yaml
        r6/tweaks/realisticComponents/20-disassembly.generated.yaml

    The hand-written structural core (00-core.yaml) proves the TweakXL syntax
    by example; THIS tool proves the *coverage*. The full recipe + disassembly
    set is hundreds of records and CANNOT be enumerated by hand: a single
    missed recipe silently leaks a tiered component back into the economy with
    no error (the same silent-failure class as wrong redscript symbols). So
    the bulk MUST be machine-generated from a real dump — never hand-typed.

EPISTEMIC CAVEATS (read before trusting any output of this tool)
    - The record type / field path names this tool matches on
      (gamedataCraftingRecipe_Record, .elements[].ingredient.item, the
      `*Material*` naming convention, the inline `elements_inlineN` sub-record
      naming) come from a research spike, NOT from a dump verified in this
      repo. If those symbols are wrong the generator will simply match nothing
      and emit an empty (but well-formed) file — a silent no-op. ALWAYS read
      the per-run summary this tool prints and sanity-check the match count
      against the known recipe volume before shipping the output.
    - Disassembly-yield location is the WEAKEST claim in this workstream. The
      disassembly pass is heuristic (it scans several plausible field paths)
      and is flagged as low-confidence in its own banner and summary. Treat
      its output with more suspicion than the recipe pass.
    - The chosen target component (--target) MUST be a dump-confirmed real
      vanilla component record OR an ArchiveXL-added item that exists at
      runtime. A TweakDBID that resolves to nothing makes every retargeted
      recipe uncraftable, and TweakXL gives no compile-time error for it.
    - Collapsing every ingredient in a recipe onto one component can change
      ingredient COUNT/cost, not just identity. This tool prefers the
      identity-only per-flat form and only falls back to a full array replace
      when a recipe carries multiple distinct tier ingredients. Even so, the
      economy impact is real and must be reviewed.
    - NONE of this is verified in a real game install.

EXPECTED DUMP FORMAT
    A JSON dump of TweakDB records/flats, as produced by common tooling
    (WolvenKit "Export TweakDB" / RED4ext TweakDB dump). Two shapes are
    accepted:

      1. Record-keyed object:
         {
           "Items.SomeRecipe_Crafting": {
             "$type": "gamedataCraftingRecipe_Record",
             "elements": [
               { "$type": "gamedataRecipeElement_Record",
                 "ingredient": { "item": "Items.CommonMaterial1",
                                 "quantity": 3 },
                 "quantity": 3 },
               ...
             ]
           },
           ...
         }

      2. Flat-list / `.str`-like form: a list of
         { "id": "<TweakDBID>", "type": "<recordType>",
           "flats": { "<flatName>": <value>, ... } }
         where array sub-records appear either nested under "elements" or as
         sibling records named "<RecipeID>.elements_inlineN" referenced by an
         array of TweakDBIDs in the parent's "elements" flat.

    The tool normalises both into the same internal model. If a real dump in
    the wild differs, adjust _load_dump() / _iter_records() — that is the only
    dump-coupled surface. Everything else operates on the normalised model.

    NOTE: a `.str` text dump is NOT parsed directly here (its grammar is
    tool-version specific). Convert it to JSON first; this script documents
    that requirement rather than guessing a fragile text grammar.

USAGE
    python3 tools/gen_realistic_components.py \
        --dump path/to/tweakdb_dump.json \
        --target Items.RealScrapComponent \
        --recipes-out r6/tweaks/realisticComponents/10-recipes.generated.yaml \
        --disassembly-out r6/tweaks/realisticComponents/20-disassembly.generated.yaml

    With no --dump the tool exits non-zero with a clear message (this repo
    ships no dump on purpose — the generated files stay empty stubs until a
    real dump is supplied at build time).

    Stdlib only. No external dependencies. `python3 -m py_compile` clean.

UNINSTALL / KILL SWITCH (of the mod, not this tool)
    Delete the folder r6/tweaks/realisticComponents/ in its entirety. TweakXL
    applies no override that is not on disk.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Any, Dict, Iterable, List, Optional, Tuple

# -----------------------------------------------------------------------------
# Constants — the spike-derived symbols. Single source of truth; if the dump
# proves these wrong, change them HERE and document the correction.
# -----------------------------------------------------------------------------

RECIPE_RECORD_TYPE = "gamedataCraftingRecipe_Record"
RECIPE_ELEMENT_TYPE = "gamedataRecipeElement_Record"
ITEM_RECORD_TYPE = "gamedataItem_Record"

# A component reference is "tiered" if its TweakDBID matches this. The canonical
# core is Items.{Common,Uncommon,Rare,Epic,Legendary}Material1 but the dump
# carries a long *Material* tail — match the family, not the five known IDs,
# precisely because the tail cannot be enumerated by hand.
TIER_COMPONENT_RE = re.compile(r"(?i)(?:^|\.)[A-Za-z0-9_]*Material[0-9]*$")

# Canonical core IDs — used only for the summary's "known core covered?" check,
# never as the match set (matching is by the regex above so the tail is caught).
CANONICAL_CORE = (
    "Items.CommonMaterial1",
    "Items.UncommonMaterial1",
    "Items.RareMaterial1",
    "Items.EpicMaterial1",
    "Items.LegendaryMaterial1",
)

# Heuristic field paths the disassembly pass scans on a record for a yielded
# component. WEAKEST-CONFIDENCE: these are plausible, not dump-confirmed.
DISASSEMBLY_YIELD_PATHS = (
    "disassembleItems",
    "disassembleRecipe",
    "scrapResult",
    "disassemblyYield",
    "rpgManager.disassembleItems",
)

GENERATED_BANNER = (
    "# GENERATED — DO NOT HAND-EDIT — REQUIRES TWEAKDB DUMP\n"
    "# =============================================================================\n"
    "# Emitted by tools/gen_realistic_components.py. Hand-edits are overwritten on\n"
    "# the next generator run. See 00-core.yaml for the hand-written structural\n"
    "# core, the epistemic caveats, and the uninstall (delete the folder) note.\n"
)


# -----------------------------------------------------------------------------
# Dump loading / normalisation — the only dump-coupled surface.
# -----------------------------------------------------------------------------


class Record:
    """Normalised TweakDB record."""

    __slots__ = ("rec_id", "rec_type", "flats")

    def __init__(self, rec_id: str, rec_type: str, flats: Dict[str, Any]):
        self.rec_id = rec_id
        self.rec_type = rec_type
        self.flats = flats


def _load_dump(path: str) -> Any:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        raise SystemExit("error: dump file not found: %s" % path)
    except json.JSONDecodeError as exc:
        raise SystemExit(
            "error: dump is not valid JSON (%s). If you have a .str text dump, "
            "convert it to JSON first — see this tool's module docstring." % exc
        )


def _iter_records(dump: Any) -> Iterable[Record]:
    """Yield Record objects from either accepted dump shape."""
    if isinstance(dump, dict):
        # Shape 1: record-keyed object.
        for rec_id, body in dump.items():
            if not isinstance(body, dict):
                continue
            rec_type = body.get("$type") or body.get("type") or ""
            flats = {k: v for k, v in body.items() if not k.startswith("$")}
            flats.pop("type", None)
            yield Record(str(rec_id), str(rec_type), flats)
        return
    if isinstance(dump, list):
        # Shape 2: flat-list form.
        for entry in dump:
            if not isinstance(entry, dict):
                continue
            rec_id = entry.get("id")
            if rec_id is None:
                continue
            rec_type = entry.get("type") or entry.get("$type") or ""
            flats = entry.get("flats")
            if not isinstance(flats, dict):
                flats = {
                    k: v
                    for k, v in entry.items()
                    if k not in ("id", "type", "$type")
                }
            yield Record(str(rec_id), str(rec_type), flats)
        return
    raise SystemExit(
        "error: unrecognised dump top-level type %s — expected a JSON object "
        "(record-keyed) or array (flat-list). See module docstring."
        % type(dump).__name__
    )


def _index(records: Iterable[Record]) -> Dict[str, Record]:
    return {r.rec_id: r for r in records}


# -----------------------------------------------------------------------------
# Element / ingredient extraction.
# -----------------------------------------------------------------------------


def _resolve_elements(
    rec: Record, by_id: Dict[str, Record]
) -> List[Dict[str, Any]]:
    """Return a recipe's elements as a list of dicts.

    Handles both inline-nested elements and the `<RecipeID>.elements_inlineN`
    sibling-record convention (unnamed array sub-records get an inline name).
    """
    raw = rec.flats.get("elements")
    elements: List[Dict[str, Any]] = []
    if isinstance(raw, list):
        for item in raw:
            if isinstance(item, dict):
                elements.append(item)
            elif isinstance(item, str):
                # A TweakDBID reference to a sibling inline sub-record.
                sub = by_id.get(item)
                if sub is not None:
                    elements.append(sub.flats)
    return elements


def _ingredient_item(element: Dict[str, Any]) -> Optional[str]:
    ing = element.get("ingredient")
    if isinstance(ing, dict):
        val = ing.get("item")
        if isinstance(val, str):
            return val
    return None


def _ingredient_quantity(element: Dict[str, Any]) -> Any:
    ing = element.get("ingredient")
    if isinstance(ing, dict) and "quantity" in ing:
        return ing.get("quantity")
    return element.get("quantity", 1)


def _is_tier_component(item_id: str) -> bool:
    return bool(TIER_COMPONENT_RE.search(item_id or ""))


# -----------------------------------------------------------------------------
# YAML emission — minimal, hand-rolled (stdlib only, no PyYAML).
# Output is deliberately simple TweakXL syntax mirroring 00-core.yaml.
# -----------------------------------------------------------------------------


def _q(value: Any) -> str:
    """Render a scalar for YAML. TweakDBIDs and numbers stay unquoted."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    return str(value)


def emit_recipes_yaml(overrides: List[Tuple[str, List[Tuple[int, Any]], bool]],
                      target: str) -> str:
    """Build the 10-recipes.generated.yaml body.

    overrides: list of (recipe_id, [(element_index, quantity), ...], full_replace)
    Per-flat (Form A) is used unless full_replace is set, in which case the
    whole elements array is collapsed onto one target ingredient.
    """
    out: List[str] = [GENERATED_BANNER]
    out.append(
        "# Recipes pass: %d recipe(s) carry a tiered/*Material* ingredient.\n"
        "# Each is retargeted to the single real component: %s\n"
        "# =============================================================================\n"
        % (len(overrides), target)
    )
    if not overrides:
        out.append("{}\n")
        return "".join(out)

    for recipe_id, elements, full_replace in sorted(overrides):
        out.append("\n%s:\n" % recipe_id)
        if full_replace:
            # Form C — full array replace (economy-affecting; used only when a
            # recipe has multiple distinct tier ingredients).
            out.append("  # multiple tier ingredients collapsed — array replace\n")
            out.append("  elements:\n")
            for _idx, qty in elements:
                out.append("    - !append-once\n")
                out.append("      ingredient:\n")
                out.append("        item: %s\n" % target)
                out.append("        quantity: %s\n" % _q(qty))
                out.append("      quantity: %s\n" % _q(qty))
        else:
            # Form A — per-flat scalar override (identity only, preserves
            # ingredient count/quantity; the safe default).
            for idx, _qty in elements:
                out.append(
                    "  elements[%d].ingredient.item: %s\n" % (idx, target)
                )
    return "".join(out)


def emit_disassembly_yaml(overrides: List[Tuple[str, str, str]],
                          target: str) -> str:
    """Build the 20-disassembly.generated.yaml body.

    overrides: list of (record_id, flat_path, original_item)
    """
    out: List[str] = [GENERATED_BANNER]
    out.append(
        "#\n"
        "# *** WEAKEST-CONFIDENCE AREA *** disassembly-yield location is the\n"
        "# least certain claim in this workstream. The matched paths below are\n"
        "# heuristic (scanned, not dump-confirmed). Audit every entry before\n"
        "# shipping. %d record(s) matched; retarget = %s\n"
        "# =============================================================================\n"
        % (len(overrides), target)
    )
    if not overrides:
        out.append("{}\n")
        return "".join(out)

    grouped: Dict[str, List[Tuple[str, str]]] = {}
    for rec_id, flat_path, original in overrides:
        grouped.setdefault(rec_id, []).append((flat_path, original))

    for rec_id in sorted(grouped):
        out.append("\n%s:\n" % rec_id)
        for flat_path, original in sorted(grouped[rec_id]):
            out.append("  # heuristic match (was: %s)\n" % original)
            out.append("  %s: %s\n" % (flat_path, target))
    return "".join(out)


# -----------------------------------------------------------------------------
# Passes.
# -----------------------------------------------------------------------------


def recipes_pass(
    records: List[Record], by_id: Dict[str, Record]
) -> List[Tuple[str, List[Tuple[int, Any]], bool]]:
    overrides: List[Tuple[str, List[Tuple[int, Any]], bool]] = []
    for rec in records:
        if rec.rec_type != RECIPE_RECORD_TYPE:
            continue
        elements = _resolve_elements(rec, by_id)
        tier_hits: List[Tuple[int, Any]] = []
        distinct_items = set()
        for idx, element in enumerate(elements):
            item_id = _ingredient_item(element)
            if item_id and _is_tier_component(item_id):
                tier_hits.append((idx, _ingredient_quantity(element)))
                distinct_items.add(item_id)
        if not tier_hits:
            continue
        # Prefer the safe per-flat identity form. Only fall back to a full
        # array replace when more than one DISTINCT tier ingredient is present
        # in the same recipe (collapsing them is the economy-affecting case).
        full_replace = len(distinct_items) > 1
        overrides.append((rec.rec_id, tier_hits, full_replace))
    return overrides


def _walk_for_tier_yield(value: Any) -> List[str]:
    """Return tier component IDs found anywhere in a (possibly nested) value."""
    found: List[str] = []
    if isinstance(value, str):
        if _is_tier_component(value):
            found.append(value)
    elif isinstance(value, dict):
        for sub in value.values():
            found.extend(_walk_for_tier_yield(sub))
    elif isinstance(value, list):
        for sub in value:
            found.extend(_walk_for_tier_yield(sub))
    return found


def disassembly_pass(
    records: List[Record],
) -> List[Tuple[str, str, str]]:
    """Heuristic. WEAKEST-CONFIDENCE pass — see banners/docstring."""
    overrides: List[Tuple[str, str, str]] = []
    for rec in records:
        # Item records are the spike's best guess for where disassembly yields
        # live (on the scrapped item's record / its RPGManager path).
        if rec.rec_type and rec.rec_type != ITEM_RECORD_TYPE:
            continue
        for path in DISASSEMBLY_YIELD_PATHS:
            node: Any = rec.flats
            ok = True
            for part in path.split("."):
                if isinstance(node, dict) and part in node:
                    node = node[part]
                else:
                    ok = False
                    break
            if not ok:
                continue
            for hit in _walk_for_tier_yield(node):
                # The flat path emitted is the leaf scalar path. The generic
                # form retargets the whole sub-tree's item ref; a real dump
                # would let us address the exact index — kept conservative and
                # flagged in the file banner for human audit.
                overrides.append((rec.rec_id, "%s" % path, hit))
    return overrides


# -----------------------------------------------------------------------------
# CLI.
# -----------------------------------------------------------------------------


def _write(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="gen_realistic_components.py",
        description=(
            "Build-time generator for Realistic Components RC1. Reads a "
            "TweakDB dump and emits the bulk recipe/disassembly de-tiering "
            "TweakXL YAML. NOT run by the game."
        ),
        epilog="With no --dump the tool exits non-zero (no dump ships here).",
    )
    parser.add_argument(
        "--dump",
        metavar="PATH",
        help="Path to a TweakDB dump JSON (WolvenKit/RED4ext export). "
        "Required to emit non-empty output.",
    )
    parser.add_argument(
        "--target",
        default="Items.RealScrapComponent",
        help="The single real target component TweakDBID. MUST be a "
        "dump-confirmed real vanilla component or an ArchiveXL-added item. "
        "Default: the 00-core.yaml placeholder.",
    )
    parser.add_argument(
        "--recipes-out",
        default="r6/tweaks/realisticComponents/10-recipes.generated.yaml",
        help="Output path for the recipes pass.",
    )
    parser.add_argument(
        "--disassembly-out",
        default="r6/tweaks/realisticComponents/20-disassembly.generated.yaml",
        help="Output path for the disassembly pass.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Compute and print the summary but do not write files.",
    )
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    if not args.dump:
        sys.stderr.write(
            "error: no --dump supplied.\n\n"
            "This repo ships NO TweakDB dump on purpose. The generated files\n"
            "stay empty stubs until a real dump is provided at build time.\n"
            "Supply a WolvenKit/RED4ext TweakDB dump JSON:\n\n"
            "  python3 tools/gen_realistic_components.py \\\n"
            "      --dump path/to/tweakdb_dump.json \\\n"
            "      --target Items.RealScrapComponent\n\n"
            "See this tool's --help and module docstring for the dump format.\n"
        )
        return 2

    dump = _load_dump(args.dump)
    records = list(_iter_records(dump))
    by_id = _index(records)

    recipe_overrides = recipes_pass(records, by_id)
    disasm_overrides = disassembly_pass(records)

    # Per-run summary — ALWAYS read this and sanity-check the counts before
    # shipping. An empty/tiny match set against a real dump means the spike's
    # symbols are wrong and every override silently no-ops.
    n_recipes = sum(1 for r in records if r.rec_type == RECIPE_RECORD_TYPE)
    core_seen = set()
    for rec in records:
        if rec.rec_type != RECIPE_RECORD_TYPE:
            continue
        for el in _resolve_elements(rec, by_id):
            it = _ingredient_item(el)
            if it in CANONICAL_CORE:
                core_seen.add(it)

    sys.stderr.write(
        "Realistic Components RC1 generator — run summary\n"
        "  records in dump .............. %d\n"
        "  crafting recipes ............. %d\n"
        "  recipes retargeted ........... %d\n"
        "  disassembly matches (HEURISTIC, low confidence) .. %d\n"
        "  canonical core IDs seen ...... %d/%d  %s\n"
        "  target component ............. %s\n"
        % (
            len(records),
            n_recipes,
            len(recipe_overrides),
            len(disasm_overrides),
            len(core_seen),
            len(CANONICAL_CORE),
            sorted(core_seen) or "(none — SUSPECT: spike symbols may be wrong)",
            args.target,
        )
    )
    if n_recipes and not recipe_overrides:
        sys.stderr.write(
            "  WARNING: recipes exist but NONE matched the tier regex — the\n"
            "  research-spike symbols are likely wrong. Do NOT ship this.\n"
        )

    recipes_yaml = emit_recipes_yaml(recipe_overrides, args.target)
    disasm_yaml = emit_disassembly_yaml(disasm_overrides, args.target)

    if args.dry_run:
        sys.stderr.write("  (dry-run: no files written)\n")
        return 0

    _write(args.recipes_out, recipes_yaml)
    _write(args.disassembly_out, disasm_yaml)
    sys.stderr.write(
        "  wrote %s\n  wrote %s\n" % (args.recipes_out, args.disassembly_out)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
