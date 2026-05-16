// Patch 1.x (pre–Phantom Liberty): pre-rework RPG/damage surface.
// Shipped in the level-tier-flatten cp2077-1x archive.
// For patch 2.0+ see levelTierFlatten_cp2077-2x.reds.
//
// Same seam strategy and fallback protocol as the 2.x file — see its header
// for the full rationale. The only difference here is the pre-2.0 method
// name/signature of the shared RPGManager scaling-coefficient helper; the
// 1.x and 2.x files therefore wrap *differently named* methods so the two
// never double-define at joint CI parse (same pattern as the existing
// handleStorageSlot_cp2077-{2x,1x} pair).
//
// In-game verification (per plan): if r6/cache/redscript.log reports an
// unresolved symbol on the wrap below, the installed 1.x build exposes a
// different name/signature — switch to fallback #1/#3 (Policy/Gate unchanged).

@wrapMethod(RPGManager)
public final static func GetWeaponLevelDamageMultiplier(attacker: wref<GameObject>, target: wref<GameObject>) -> Float {
    if !LevelTierFlattenGate.IsEnabled() {
        return wrappedMethod(attacker, target);
    }
    return LevelTierFlattenPolicy.NeutralLevelCoefficient();
}
