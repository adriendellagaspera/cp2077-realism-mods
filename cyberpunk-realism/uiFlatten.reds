// Policy: single source of truth for *what* the UI layer should flatten.
// Cosmetic tranche — it changes nothing about damage or game logic; it only
// stops the UI from advertising level/tier so the screen matches the already
// de-scaled numbers from the level/tier-flatten (damage) module.
//
// Why a separate cosmetic tranche (see suite design notes): hiding level/tier
// in the UI means several *UI-controller* wraps, which are inherently more
// patch-fragile than the single shared gameplay static. Isolating them here
// keeps that fragility out of the gameplay module and lets this layer be
// shipped / disabled independently.
public class UiFlattenPolicy {
    // Text substituted wherever a numeric level would be drawn (enemy
    // nameplate, item "required level", level-up screen). Empty string so
    // the label collapses instead of showing a misleading number.
    public static func HiddenLevelText() -> String = "";

    // All item qualities are coerced to this single quality for *colour*
    // resolution only, so the rarity rainbow no longer signals power.
    // Common is the neutral baseline; item stats/identity are untouched.
    public static func NeutralColorQuality() -> gamedataQuality = gamedataQuality.Common;
}

// Gate: kill-switch for the whole cosmetic layer. Default ON.
// Every wrap falls through to vanilla `wrappedMethod(...)` when OFF, so the
// stock UI returns instantly — this layer hides, it does not delete data.
class UiFlattenGate {
    private static let s_enabled: Bool = true;

    public static func SetEnabled(value: Bool) -> Void {
        UiFlattenGate.s_enabled = value;
    }

    public static func IsEnabled() -> Bool = UiFlattenGate.s_enabled;
}

// --- Why no wrap lives in this (version-agnostic) file ---
// Mirrors the repo's compat-split convention: UI controllers were among the
// surfaces reworked around patch 2.0/2.1, so every wrap lives in the
// patch-specific pair (`uiFlatten_cp2077-{2x,1x}.reds`) and the two never
// collide at joint parse. This core file carries only Policy + Gate.
//
// SYMBOL STATUS (tracked in PROGRESS.md): the wrapped controller names below
// are best-effort and NOT yet verified against a real game build. CI is
// parse-only. This module stays on the feature branch until the symbols are
// confirmed in r6/cache/redscript.log (or switched to the documented
// fallback) — same maturation rule as the level/tier-flatten module.
