// Patch 2.0+: post-rework UI controllers.
// Shipped in the cyberpunk-realism cp2077-2x archive.
// For patch 1.x see uiFlatten_cp2077-1x.reds.
//
// --- Seam choice (cosmetic; fallback protocol below) ---
// Scope of THIS file: the rarity-colour concern only — coerce the quality
// used for *colour* resolution to a single neutral quality so the tier
// rainbow stops signalling power. Wrapped at the quality→colour resolver
// (one central point) rather than per item widget.
//
// The level-hiding concerns (enemy nameplate, item "required level"
// tooltip, level-up screen) are deliberately NOT speculatively coded here.
// Each needs a private-field / controller name we cannot confirm from CI,
// and the tranche-1 revert showed unverified guesses are a liability. They
// are tracked as discrete, actionable items in PROGRESS.md with their
// candidate controllers, to be coded once confirmed.
//
// CI is parse-only and cannot prove this controller symbol resolves.
// In-game verification: launch once, read r6/cache/redscript.log; on an
// unresolved-symbol error the installed patch exposes a different
// name/signature — switch to the fallback noted in PROGRESS.md (no
// Policy/Gate change). This module stays on the feature branch until that
// verification passes.

@wrapMethod(UIInventoryItemsManager)
public final static func GetItemQualityColor(quality: gamedataQuality, theme: ref<UIItemColorTheme>) -> HDRColor {
    if !UiFlattenGate.IsEnabled() {
        return wrappedMethod(quality, theme);
    }
    return wrappedMethod(UiFlattenPolicy.NeutralColorQuality(), theme);
}
