# cp2077-realism-mods

A repository of small, independent Cyberpunk 2077 realism mods. **Each mod
lives in its own homonymous top-level folder** with its own README and release
archive, so mods install independently and can be extracted to separate repos
without rework.

## Mods

- **[Immersive Scrapping](./immersive-scrapping/README.md)** —
  [`immersive-scrapping/`](./immersive-scrapping/) — confines item scrapping
  (disassembly) to the stash screen. Shipped.

Additional realism mods are developed on integration branches and land here
once dry; see the per-mod folders as they arrive.

## Layout

```
immersive-scrapping/      # the Immersive Scrapping mod (reds + its README)
.github/                 # CI, release, issue/PR templates (repo-wide)
CHANGELOG.md SECURITY.md LICENSE
```

## Releases

Tagging `v*` builds and publishes per-mod archives
(`<mod>-{version}-cp2077-{2x,1x}.zip`). See each mod's README for the
game-version archive table and install path.
