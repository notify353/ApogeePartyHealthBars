local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local MB = ApogeePartyHealthBars_MouseButtonActions
local Items = ApogeePartyHealthBars_ShortcutItems

ApogeePartyHealthBars_BindingController = {}
local B = ApogeePartyHealthBars_BindingController
local D

local function GetBindingSlotLabel(slotKey)
    for _, slot in ipairs(C.BINDING_SLOTS) do
        if slot.key == slotKey then return slot.label end
    end
    return slotKey
end

local function RefreshHealingBindings()
    D.RefreshBindPanel()
    D.ForceRefresh()
end

local function AssignBindingSpell(spellID, spellName, slotKey)
    if not slotKey then return false end
    local ok, message, action = D.AssignBindingSpell(slotKey, spellID, spellName)
    if message then D.Print(message) end
    if not ok then return false end
    D.Print("bound |cff00ff00" .. action.spellName .. "|r to "
        .. GetBindingSlotLabel(slotKey))
    RefreshHealingBindings()
    return true
end

local function AssignBindingItem(itemId, itemName, slotKey)
    if not slotKey then return false end
    local ok, message, action = D.AssignBindingItem(slotKey, itemId, itemName)
    if message then D.Print(message) end
    if not ok then return false end
    D.Print("bound |cff00ff00" .. action.itemName .. "|r to "
        .. GetBindingSlotLabel(slotKey))
    RefreshHealingBindings()
    return true
end

local function AssignActionSpell(feature, slot, layoutKey, spellID, spellName)
    if feature == "keys" then
        if not K.IsKnownLayout(layoutKey) then layoutKey = K.GetActiveLayoutKey() end
        local ok, message, assignedSlot = K.AssignSpell(layoutKey, slot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            S.selectedKeyLayout = layoutKey
            local ui = D.GetConfigUI()
            if ui and ui.RefreshKeyPanel then ui.RefreshKeyPanel(assignedSlot) end
        end
        return ok
    elseif feature == "wheel" then
        if not W.IsKnownLayout(layoutKey) then layoutKey = W.GetActiveLayoutKey() end
        local ok, message, assignedSlot = W.AssignSpell(layoutKey, slot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            S.selectedWheelLayout = layoutKey
            local ui = D.GetConfigUI()
            if ui and ui.RefreshWheelPanel then ui.RefreshWheelPanel(assignedSlot) end
        end
        return ok
    elseif feature == "mouseButtons" then
        if not MB.IsKnownLayout(layoutKey) then layoutKey = MB.GetActiveLayoutKey() end
        local ok, message, assignedSlot = MB.AssignSpell(layoutKey, slot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            S.selectedMouseButtonLayout = layoutKey
            local ui = D.GetConfigUI()
            if ui and ui.RefreshMouseButtonPanel then ui.RefreshMouseButtonPanel(assignedSlot) end
        end
        return ok
    elseif feature == "shortcuts" then
        local ok, message, assignedSlot = T.AssignSpell(slot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            D.SyncVisualTicker()
            local ui = D.GetConfigUI()
            if ui and ui.RefreshShortcutPanel then ui.RefreshShortcutPanel(assignedSlot) end
        end
        return ok
    elseif feature == "healing" then
        return AssignBindingSpell(spellID, spellName, slot)
    end
    return false
end

local function AssignActionItem(feature, slot, layoutKey, itemId, itemName)
    if feature == "healing" then
        return AssignBindingItem(itemId, itemName, slot)
    elseif feature == "keys" then
        if not K.IsKnownLayout(layoutKey) then layoutKey = K.GetActiveLayoutKey() end
        local ok, message, assignedSlot = K.AssignItem(layoutKey, slot, itemId, itemName)
        if message then D.Print(message) end
        if ok then
            S.selectedKeyLayout = layoutKey
            local ui = D.GetConfigUI()
            if ui and ui.RefreshKeyPanel then ui.RefreshKeyPanel(assignedSlot) end
        end
        return ok
    elseif feature == "wheel" then
        if not W.IsKnownLayout(layoutKey) then layoutKey = W.GetActiveLayoutKey() end
        local ok, message, assignedSlot = W.AssignItem(layoutKey, slot, itemId, itemName)
        if message then D.Print(message) end
        if ok then
            S.selectedWheelLayout = layoutKey
            local ui = D.GetConfigUI()
            if ui and ui.RefreshWheelPanel then ui.RefreshWheelPanel(assignedSlot) end
        end
        return ok
    elseif feature == "mouseButtons" then
        if not MB.IsKnownLayout(layoutKey) then layoutKey = MB.GetActiveLayoutKey() end
        local ok, message, assignedSlot = MB.AssignItem(layoutKey, slot, itemId, itemName)
        if message then D.Print(message) end
        if ok then
            S.selectedMouseButtonLayout = layoutKey
            local ui = D.GetConfigUI()
            if ui and ui.RefreshMouseButtonPanel then ui.RefreshMouseButtonPanel(assignedSlot) end
        end
        return ok
    elseif feature == "shortcuts" then
        local ok, message, assignedSlot = T.AssignItem(slot, itemId, itemName)
        if message then D.Print(message) end
        if ok then
            D.SyncVisualTicker()
            local ui = D.GetConfigUI()
            if ui and ui.RefreshShortcutPanel then ui.RefreshShortcutPanel(assignedSlot) end
        end
        return ok
    end
    return false
end

local function ClearBinding(slotKey)
    local ok, message = D.ClearBindingAction(slotKey)
    if message then D.Print(message) end
    if not ok then return false, message end
    RefreshHealingBindings()
    return true, message or (GetBindingSlotLabel(slotKey) .. " cleared.")
end

local function MoveBinding(slotKey, direction)
    local ok, message = D.MoveBindingAction(slotKey, direction)
    if not ok then
        if message then D.Print(message) end
        return false, message
    end
    RefreshHealingBindings()
    return true, message
end

function B.Initialize(deps) D = deps end
B.ClearBinding = ClearBinding
B.MoveBinding = MoveBinding

function B.AssignCursor(feature, slot, layoutKey)
    if not D or type(GetCursorInfo) ~= "function" then return false end
    if InCombatLockdown and InCombatLockdown() then
        D.Print("leave combat before changing an action.")
        return false
    end
    if feature ~= "healing" and feature ~= "shortcuts"
        and feature ~= "keys" and feature ~= "wheel" and feature ~= "mouseButtons" then
        return false
    end
    if feature ~= "shortcuts" and not slot then return false end

    local cursorType, cursorValue, bookType, cursorSpellID = GetCursorInfo()
    local ok = false
    if cursorType == "spell" then
        if D.ClientCapabilities
            and not D.ClientCapabilities.IsFeatureAvailable("spellAssignment") then
            D.Print(D.ClientCapabilities.GetFeatureReason("spellAssignment"))
            return false
        end
        local spellID, spellName = D.GetSpellFromCursor(cursorValue, bookType, cursorSpellID)
        if not spellID and not spellName then
            D.Print("could not read that spell — try dragging it again.")
            return false
        end
        ok = AssignActionSpell(feature, slot, layoutKey, spellID, spellName)
    elseif cursorType == "item" then
        if D.ClientCapabilities
            and not D.ClientCapabilities.IsFeatureAvailable("itemAssignment") then
            D.Print(D.ClientCapabilities.GetFeatureReason("itemAssignment"))
            return false
        end
        local itemId = tonumber(cursorValue)
        local itemName = itemId and Items and Items.GetInfo and Items.GetInfo(itemId)
        if not itemId or not itemName then
            D.Print("could not read that item — try dragging it again.")
            return false
        end
        ok = AssignActionItem(feature, slot, layoutKey, itemId, itemName)
    else
        D.Print("drag a Spellbook spell or usable bag item onto that position.")
        return false
    end

    if ok and type(ClearCursor) == "function" then ClearCursor() end
    return ok
end
