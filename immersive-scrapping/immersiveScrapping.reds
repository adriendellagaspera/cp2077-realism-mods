// Policy: single source of truth for what "disassemble" means.
// Controllers only decide *when* — this class decides *what*.
public class DisassemblePolicy {
    public static func ActionName() -> CName = n"disassemble_item";

    public static func HintLabel() -> CName {
        return StringToName(GetLocalizedText("LocKey#6887"));
    }

    public static func IsItemDisassemblable(item: wref<gameItemData>) -> Bool {
        return IsDefined(ItemActionsHelper.GetDisassembleAction(item.GetID()))
            && item.GetQuantity() > 0;
    }

    public static func Execute(player: ref<GameObject>, itemID: ItemID, qty: Int32) -> Void {
        ItemActionsHelper.DisassembleItem(player, itemID, qty);
        GameInstance.GetAudioSystem(player.GetGame()).Play(n"ui_menu_item_disassemble");
    }
}

// Gate: a single Bool tracking whether the stash screen is open.
// redscript does not support mutable static class fields, so the flag lives
// on CraftingSystem itself (a singleton ScriptableSystem) via @addField — the
// same object whose CanItemBeDisassembled we gate below. A single bool here
// replaces 4 fragile UI-layer wraps.
@addField(CraftingSystem)
public let m_stashDisassembleOpen: Bool;

// --- Core blocker: one wrap at the game-logic layer covers every UI ---
// CraftingSystem.CanItemBeDisassembled is the canonical gate checked by
// all inventory screens before showing the hint or allowing the action.
// This is more patch-stable than wrapping individual UI controller methods.

@wrapMethod(CraftingSystem)
public final const func CanItemBeDisassembled(itemData: wref<gameItemData>) -> Bool {
    if !this.m_stashDisassembleOpen { return false; }
    return wrappedMethod(itemData);
}

// --- Track stash lifecycle ---

@wrapMethod(FullscreenVendorGameController)
protected cb func OnInitialize() -> Bool {
    let result = wrappedMethod();
    if this.IsStashMode() { this.SetStashDisassembleGate(true); }
    return result;
}

@wrapMethod(FullscreenVendorGameController)
protected cb func OnUninitialize() -> Bool {
    if this.IsStashMode() { this.SetStashDisassembleGate(false); }
    return wrappedMethod();
}

// --- Enable disassembly UI in the stash ---
// HandleStorageSlot* wrap lives in handleStorageSlot_cp2077-{2x,1x}.reds: the
// method was renamed HandleStorageSlotInput (1.x) → HandleStorageSlotClick (2.0).

@wrapMethod(FullscreenVendorGameController)
protected func OnConfirmationPopupClosed(data: ref<inkGameNotificationData>) -> Bool {
    let handled = wrappedMethod(data);
    if IsDefined(data) {
        let resultData = data as VendorConfirmationPopupCloseData;
        if Equals(resultData.confirm, true) && Equals(resultData.type, VendorConfirmationPopupType.DisassembeIconic) && this.IsStashMode() && IsDefined(resultData.inventoryItem) && resultData.inventoryItem.IsIconic() {
            this.TryDisassembleFromStash(resultData.inventoryItem.GetItemData(), resultData.quantity);
            handled = true;
        }
    }
    return handled;
}

@wrapMethod(FullscreenVendorGameController)
protected func OnQuantityPickerPopupClosed(data: ref<inkGameNotificationData>) -> Bool {
    let handled = wrappedMethod(data);
    if IsDefined(data) {
        let resultData = data as QuantityPickerPopupCloseData;
        if Equals(resultData.actionType, QuantityPickerActionType.Disassembly) && this.IsStashMode() && IsDefined(resultData.inventoryItem) && resultData.choosenQuantity > 0 {
            this.TryDisassembleFromStash(resultData.inventoryItem.GetItemData(), resultData.choosenQuantity);
            handled = true;
        }
    }
    return handled;
}

@wrapMethod(FullscreenVendorGameController)
protected cb func OnInventoryItemHoverOver(evt: ref<ItemDisplayHoverOverEvent>) -> Bool {
    let controller: ref<DropdownListController> = inkWidgetRef.GetController(this.m_sortingDropdown) as DropdownListController;
    if !controller.IsOpened() && this.IsStashMode() {
        if evt.uiInventoryItem != null && DisassemblePolicy.IsItemDisassemblable(evt.uiInventoryItem.GetItemData()) {
            this.m_buttonHintsController.AddButtonHint(DisassemblePolicy.ActionName(), DisassemblePolicy.HintLabel(), true);
        };
    };
    wrappedMethod(evt);
}

@wrapMethod(FullscreenVendorGameController)
protected cb func OnInventoryItemHoverOut(evt: ref<ItemDisplayHoverOutEvent>) -> Bool {
    wrappedMethod(evt);
    this.m_buttonHintsController.RemoveButtonHint(DisassemblePolicy.ActionName());
}

@addMethod(FullscreenVendorGameController)
private func IsStashMode() -> Bool = (!IsDefined(this.m_vendorUserData) && IsDefined(this.m_storageUserData));

@addMethod(FullscreenVendorGameController)
private func SetStashDisassembleGate(open: Bool) -> Void {
    let game = this.GetPlayerControlledObject().GetGame();
    let craftingSystem = GameInstance.GetScriptableSystemsContainer(game).Get(n"CraftingSystem") as CraftingSystem;
    if IsDefined(craftingSystem) {
        craftingSystem.m_stashDisassembleOpen = open;
    }
}

@addMethod(FullscreenVendorGameController)
private func TryDisassembleFromStash(item: wref<gameItemData>, qty: Int32) -> Void {
    let player = this.GetPlayerControlledObject();
    DisassemblePolicy.Execute(player, item.GetID(), qty);
    this.Update();
}
