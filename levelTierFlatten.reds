// Policy: single source of truth for *what* "flatten" means numerically.
// Wraps only decide *where* to apply it — this class decides the values.
//
// "Flatten" is neutralisation, never deletion: the level/tier signal still
// flows through the engine, we just collapse its multiplier to a no-op so
// combat is driven by weapon archetype + cyberware + hit location instead.
// Entity level fields are untouched (perks / requirements / quests intact);
// only the *damage coefficient* contribution of the level/tier delta is
// clamped. This survives patches and deep mod stacks — it does not fight
// the engine.
public class LevelTierFlattenPolicy {
    // Attacker-vs-target level-delta scaling coefficient, forced neutral.
    // 1.0 == "effective level delta is zero" → no per-level damage swing.
    public static func NeutralLevelCoefficient() -> Float = 1.0;

    // Item tier / quality damage multiplier, forced neutral.
    // 1.0 == a common and an iconic of the same archetype hit identically.
    public static func NeutralTierMultiplier() -> Float = 1.0;

    // Clamp helper for seams that expose an already-combined scalar: keep
    // the engine's value only when it is *below* neutral (debuffs, damage
    // falloff, resistances still matter), collapse any level/tier *amplifi-
    // cation* above neutral. Symmetric by construction — the same scalar is
    // computed for player→NPC, NPC→player and NPC→NPC, so flattening it once
    // in the shared static makes Night City lethal both ways automatically.
    public static func FlattenScalar(raw: Float) -> Float {
        if raw < LevelTierFlattenPolicy.NeutralLevelCoefficient() { return raw; }
        return LevelTierFlattenPolicy.NeutralLevelCoefficient();
    }
}

// Gate: kill-switch for the whole flatten layer. Default ON.
// Every wrap falls through to vanilla `wrappedMethod(...)` when OFF, which
// is what proves this layer neutralises rather than deletes: flipping the
// gate restores stock scaling instantly, no reload of game data required.
class LevelTierFlattenGate {
    private static let s_enabled: Bool = true;

    public static func SetEnabled(value: Bool) -> Void {
        LevelTierFlattenGate.s_enabled = value;
    }

    public static func IsEnabled() -> Bool = LevelTierFlattenGate.s_enabled;
}

// --- Why no wrap lives in this (version-agnostic) file ---
// The CP2077 RPG/damage surface was reworked substantially around patch
// 2.0/2.1 (method *names and signatures* drifted). Mirroring the repo's
// existing `handleStorageSlot_cp2077-{2x,1x}` split, every RPGManager wrap
// lives in the patch-specific pair so the two never collide at joint parse.
// This core file carries only Policy + Gate (and would carry any wrap proven
// byte-identical across both game lines — none qualifies here).
