// Patch 2.0+: post-rework RPG/damage surface.
// Shipped in the level-tier-flatten cp2077-2x archive.
// For patch 1.x see levelTierFlatten_cp2077-1x.reds.
//
// --- Seam choice (priority order; fallback protocol below) ---
// The level/tier signal does not enter damage as direct arithmetic — it
// arrives as a *scaling coefficient* derived from a TweakDB curve, applied
// inside a shared static on RPGManager. Neutralising that one coefficient
// in the shared static is what makes player→NPC, NPC→player and NPC→NPC
// symmetric for free: same code path, no "is this the player" branch.
//
// Choke-points considered (repo idiom: document *why this seam*):
//   1. RPGManager static damage finaliser (absolute damage) — HIGH name/arg
//      drift across the 2.0/2.1 rework; fallback only, clamp via
//      LevelTierFlattenPolicy.FlattenScalar on the *combined* scalar there.
//   2. RPGManager attacker-vs-target scaling-coefficient helper (Float)  ← USED
//      → return the neutral coefficient. Most symmetric, smallest surface,
//      numerically clean (the helper *is* the ~1.0 multiplier).
//   3. RPGManager weapon-damage / quality-multiplier getter → clamp to the
//      neutral tier multiplier, *only if* tier is not already subsumed by
//      #2 (depends on patch order-of-application).
//
// CI is parse-only and cannot prove this symbol resolves against a real
// game build (a limitation the repo already accepts for redscript).
// In-game verification (per plan): launch once and read
// r6/cache/redscript.log. If it reports an unresolved symbol on the wrap
// below, the installed patch exposes a different name/signature — switch
// this wrap to fallback #1 or #3 (no Policy/Gate change needed).

@wrapMethod(RPGManager)
public final static func GetWeaponLevelScalingMultiplier(attacker: wref<GameObject>, target: wref<GameObject>) -> Float {
    if !LevelTierFlattenGate.IsEnabled() {
        return wrappedMethod(attacker, target);
    }
    return LevelTierFlattenPolicy.NeutralLevelCoefficient();
}
