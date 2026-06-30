# cp2077-realism-mods

**Work in progress**

A repository of small, independent Cyberpunk 2077 realism mods. **Each mod
lives in its own homonymous top-level folder** with its own README and release
archive, so mods install independently.

## Mods

- **[Immersive Scrapping](./immersive-scrapping/README.md)** —
  [`immersive-scrapping/`](./immersive-scrapping/) — confines item scrapping
  (disassembly) to the stash screen. Shipped.

Additional realism mods are developed on integration branches and land here
once dry; see the per-mod folders as they arrive.

## Layout

```
immersive-scrapping/      # the Immersive Scrapping mod (reds + its README)
scripts/                 # offline checks (typecheck.sh)
.github/                 # CI, release, issue/PR templates (repo-wide)
CHANGELOG.md SECURITY.md TESTING.md LICENSE
```

## Testing

The mods hook onto native game classes, so the reliable offline check is a
**semantic type-check** that compiles a mod against the game's own
`final.redscripts` bundle — reproducing the game's startup compile without
launching it. CI runs sanity + parse checks on every PR; the ground-truth
type-check runs in the pre-commit hook. See **[TESTING.md](./TESTING.md)**.

## Releases

Tagging `v*` builds and publishes per-mod archives
(`<mod>-{version}-cp2077-{2x,1x}.zip`). See each mod's README for the
game-version archive table and install path.
