# Cyberpunk Realism — suite overview

> Vision and current state. For the actionable, per-chantier tracker (status,
> branches, blockers, verification), see [`PROGRESS.md`](./PROGRESS.md).

## Vision

A realism overhaul for Cyberpunk 2077 that strips the RPG-shooter abstraction
layer — the level/tier "bullet-sponge" math — so combat is driven by **weapon
archetype, cyberware, hit location, and skill**, not by a hidden level delta.

The guiding fantasy: **Night City is lethal in both directions.** A pistol
round is a pistol round whether it leaves your gun or a gonk's; what changes
outcomes is positioning, gear, and what you hit — not whether an enemy is
"six levels above you".

This is a *suite*, not a single mod. Each concern is a standalone module with
its own `r6/scripts/<module>/` folder and its own release archive, so modules
can be installed independently and the suite can later be split across several
repos/mods without rework.

## Design tenets (locked)

1. **Neutralise, never delete.** Collapse a signal's influence to a no-op
   rather than ripping it out. Survives game patches and deep mod stacks; does
   not fight the engine. Every module has a default-on kill-switch that falls
   through to vanilla `wrappedMethod(...)`.
2. **Structural symmetry.** Parity between player and NPC is achieved by
   wrapping the *shared* code path — never by branching on "is this the
   player". Same rule both ways, by construction.
3. **Compose, don't reimplement.** Data-driven layers already covered by
   mature, configurable mods (e.g. NPC health pools) are delegated via
   documented composition, not rebuilt.
4. **Modular & multi-repo-ready.** Standalone modules, extractable at no cost.
5. **Discipline before `main`.** Work matures on the `feature/cyberpunk-realism`
   integration branch (one dash-separated sub-branch per chantier). A module
   reaches `main` only when **dry**: CI green **and** its wrapped game symbols
   verified in-game via `r6/cache/redscript.log` (or switched to the
   documented fallback seam). Public `main` never carries unfinished work.

## Modules — what the suite does to date

| Module | Tranche | Concern | State |
|---|---|---|---|
| Level/Tier Damage Flatten | 1 | Remove level + item-tier influence on damage (shared `RPGManager` static), strict NPC parity | Implemented, **pending in-game symbol verification** |
| UI Flatten | 2 | Stop the UI advertising level/tier (cosmetic) so the screen matches the de-scaled numbers | Rarity-colour seam implemented (best-effort); level-hiding sub-items tracked |

**Composition (out of redscript scope):** NPC health-pool / time-to-kill is
TweakDB-data-driven and intentionally not reimplemented. Compose with an
established mod — e.g. [No Enemy Scaling](https://www.nexusmods.com/cyberpunk2077/mods/24244)
or [Damage Scaling and Balance](https://www.nexusmods.com/cyberpunk2077/mods/1712).
Without one, damage is already de-scaled and lethal both ways, but vanilla
health bars make time-to-kill longer than expected.

## Roadmap (directions — to be challenged, not committed)

These are candidate chantiers; several are large enough to become their own
mods. Tracked with scope and risk in [`PROGRESS.md`](./PROGRESS.md).

- **Continuous "learn-by-doing" progression** (Skyrim-like): replace the
  level-milestone / perk-point gating with continuous per-axis progression
  (CP2077 attributes: Body, Reflexes, Technical Ability, Intelligence, Cool;
  skills: Handguns, Assault, Blades, Street Brawler, Athletics, Annihilation,
  Stealth, Engineering, Crafting, Quickhacking, Cold Blood). Use-based growth
  already exists in vanilla — the work is neutralising the milestone gating.
- **Skill regression / decay** (the hard one): no native decay in CP2077 → a
  custom tick + persisted-state subsystem. Highest risk; likely its own mod.
- **Firearm vs. melee damage asymmetry**: firearms driven by weapon archetype
  alone (the bullet does not depend on the shooter); melee = archetype **+ a
  Body/strength term** (force matters). Composes with Module 1 at the same
  `RPGManager` seam.

## How it relates to this repo

This repo also ships the unrelated `stash-only-disassemble` mod (see the
[repo README](../README.md)); the Cyberpunk Realism suite lives in this
`cyberpunk-realism/` folder for now because tooling is repo-scoped, but is
structured to extract cleanly into its own repo.
