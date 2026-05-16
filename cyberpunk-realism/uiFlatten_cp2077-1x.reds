// Patch 1.x (pre–Phantom Liberty): pre-rework UI controllers.
// Shipped in the cyberpunk-realism cp2077-1x archive.
// For patch 2.0+ see uiFlatten_cp2077-2x.reds.
//
// Same cosmetic seam strategy and fallback protocol as the 2.x file — see
// its header for the full rationale. The only difference here is the pre-2.0
// name/signature of the quality→colour resolver; the 1.x and 2.x files
// therefore wrap *differently named* methods so the two never double-define
// at joint CI parse (same pattern as the handleStorageSlot_* pair).
//
// In-game verification: if r6/cache/redscript.log reports an unresolved
// symbol on the wrap below, the installed 1.x build exposes a different
// name/signature — switch to the fallback noted in PROGRESS.md
// (Policy/Gate unchanged).

@wrapMethod(UIInventoryItemsManager)
public final static func GetItemQualityFromColor(quality: gamedataQuality, theme: ref<UIItemColorTheme>) -> Color {
    if !UiFlattenGate.IsEnabled() {
        return wrappedMethod(quality, theme);
    }
    return wrappedMethod(UiFlattenPolicy.NeutralColorQuality(), theme);
}
