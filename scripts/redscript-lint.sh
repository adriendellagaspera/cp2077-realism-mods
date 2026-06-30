#!/usr/bin/env bash
# Full type-check of the .reds sources against the game's compiled script bundle.
#
# Run this on a machine that has Cyberpunk 2077 installed. Unlike the parse-only
# `redscript-cli format` (which CI and the devcontainer run without the game),
# `lint` resolves real engine types and methods — it catches semantic errors
# such as wrapping a method that doesn't exist or a type mismatch.
#
# The bundle (final.redscripts) is proprietary CD Projekt Red game data: it is
# never committed to this repo. Pass the path to your own local copy.
#
# Usage:
#   scripts/redscript-lint.sh <path-to-final.redscripts> [sources-dir]
#
# Example (default sources-dir is the mod folder):
#   scripts/redscript-lint.sh \
#     "/c/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/cache/final.redscripts"
set -euo pipefail

BUNDLE="${1:?usage: redscript-lint.sh <path-to-final.redscripts> [sources-dir]}"
SRC="${2:-immersive-scrapping}"

if [ ! -f "$BUNDLE" ]; then
  echo "Bundle not found: $BUNDLE" >&2
  echo "Point this at <Cyberpunk 2077>/r6/cache/final.redscripts on a machine with the game installed." >&2
  exit 1
fi

redscript-cli lint -b "$BUNDLE" -s "$SRC"
