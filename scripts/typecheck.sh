#!/bin/sh
# Offline redscript type-check for cp2077-realism-mods.
#
# Why: the mods are @wrapMethod/@addMethod hooks onto native game classes.
# A wrong signature, a renamed-between-patches method, or a missing field/enum
# only surfaces in-game in r6/cache/redscript.log at launch. This script
# reproduces the game's startup compilation WITHOUT launching the game, by
# compiling the mod sources against the game's own compiled script bundle
# (final.redscripts) -- the real source of truth for native definitions.
#
# Runtime execution of redscript is impossible offline (no standalone VM), so
# this is a semantic *type-check*, not a behavioural test. A clean compile
# means every wrapped method, field, enum and type resolves against the game.
#
# Usage:
#   CP2077_REDSCRIPTS="/path/to/Cyberpunk 2077" ./scripts/typecheck.sh
#
# CP2077_REDSCRIPTS points at the GAME ROOT. The script derives the bundle at
# r6/cache/final.redscripts, preferring the pristine backup final.redscripts.bk
# (an already-modded bundle would skew the result). If the variable is unset or
# the bundle is missing, the script SKIPS cleanly (exit 0) so contributors
# without the game installed -- and public CI -- are never blocked.
#
# Tooling: needs `redscript-cli` on PATH. Override the binary with RS_CLI.
# Scope: patch 2.x only (the -1x variant stays covered by in-game testing).
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
MOD_SHARED="$ROOT/immersive-scrapping/immersiveScrapping.reds"
MOD_VARIANT="$ROOT/immersive-scrapping/handleStorageSlot_cp2077-2x.reds"
RS_CLI="${RS_CLI:-redscript-cli}"

skip() {
    printf 'redscript typecheck: SKIP (%s)\n' "$1"
    exit 0
}

# --- Locate the game script bundle (ground truth) ---
if [ -z "${CP2077_REDSCRIPTS:-}" ]; then
    skip "CP2077_REDSCRIPTS not set; point it at your Cyberpunk 2077 install to enable"
fi

CACHE_DIR="$CP2077_REDSCRIPTS/r6/cache"
if [ -f "$CACHE_DIR/final.redscripts.bk" ]; then
    BUNDLE="$CACHE_DIR/final.redscripts.bk"
elif [ -f "$CACHE_DIR/final.redscripts" ]; then
    BUNDLE="$CACHE_DIR/final.redscripts"
else
    skip "no final.redscripts(.bk) under $CACHE_DIR"
fi

# --- Locate the compiler ---
if ! command -v "$RS_CLI" >/dev/null 2>&1; then
    skip "$RS_CLI not found on PATH (install redscript-cli or set RS_CLI)"
fi

# --- Type-check: compile the mod against the real game bundle ---
# redscript-cli memory-maps BOTH the bundle and the source files it reads.
# mmap() fails with ENODEV ("failed to map file, no such device") on
# filesystems that don't support it -- notably Docker Desktop bind mounts
# (9p/virtiofs/gRPC-FUSE) used to share a Windows/macOS game install (and the
# repo) into a dev container. So stage the bundle AND the sources onto the
# container's native FS (TMPDIR) before compiling. On a native install these
# are just fast local copies.
#
# Only the 2.x source set is staged: the folder also holds the mutually
# exclusive 1.x storage-slot variant, which would not resolve against a 2.x
# bundle. Passing the staged dir as a single -s keeps the 1.x file out.
LOCAL_BUNDLE=$(mktemp "${TMPDIR:-/tmp}/cp2077-bundle.XXXXXX.redscripts")
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/cp2077-src.XXXXXX")
OUT=$(mktemp "${TMPDIR:-/tmp}/cp2077-typecheck.XXXXXX.redscripts")
trap 'rm -rf "$LOCAL_BUNDLE" "$STAGE" "$OUT"' EXIT
cp "$BUNDLE" "$LOCAL_BUNDLE"
cp "$MOD_SHARED" "$MOD_VARIANT" "$STAGE/"

printf 'redscript typecheck: compiling against %s\n' "$BUNDLE"
"$RS_CLI" compile \
    -b "$LOCAL_BUNDLE" \
    -s "$STAGE" \
    -o "$OUT" \
    -L warning
printf 'redscript typecheck: OK\n'
