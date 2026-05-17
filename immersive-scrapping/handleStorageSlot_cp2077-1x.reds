// Patch 1.x: HandleStorageSlotInput (renamed to HandleStorageSlotClick in patch 2.0).
// Shipped in the cp2077-1x archive. For patch 2.0+ see handleStorageSlot_cp2077-2x.reds.

@wrapMethod(FullscreenVendorGameController)
private final func HandleStorageSlotInput(evt: ref<ItemDisplayClickEvent>) -> Void {
    wrappedMethod(evt);

    if this.IsStashMode() && evt.actionName.IsAction(DisassemblePolicy.ActionName()) && IsDefined(evt.uiInventoryItem) {
        let item = evt.uiInventoryItem.GetItemData();
        if DisassemblePolicy.IsItemDisassemblable(item) {
            let qty = item.GetQuantity();
            if evt.uiInventoryItem.IsIconic() {
                this.OpenConfirmationPopup(evt.uiInventoryItem, qty, QuantityPickerActionType.Disassembly, VendorConfirmationPopupType.DisassembeIconic);
            } else if qty > 1 {
                this.OpenQuantityPicker(evt.uiInventoryItem, QuantityPickerActionType.Disassembly);
            } else {
                this.TryDisassembleFromStash(item, 1);
            }
        }
    }
}
