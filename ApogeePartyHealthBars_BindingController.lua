local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local Items = ApogeePartyHealthBars_ShortcutItems

ApogeePartyHealthBars_BindingController = {}
local B = ApogeePartyHealthBars_BindingController
local D

local function IsAssignableTab(tabName)
    if tabName == "healing" then return S.selectedBindingKey ~= nil end
    return tabName == "shortcuts" or tabName == "keys" or tabName == "wheel"
end

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

local function AssignBindingSpell(spellID, spellName)
    if not S.selectedBindingKey then return end
    local ok, message, action = D.AssignBindingSpell(S.selectedBindingKey, spellID, spellName)
    if message then D.Print(message) end
    if not ok then return false end
    D.Print("bound |cff00ff00" .. action.spellName .. "|r to "
        .. GetBindingSlotLabel(S.selectedBindingKey))
    RefreshHealingBindings()
    return true
end

local function AssignBindingItem(itemId, itemName)
    if not S.selectedBindingKey then return false end
    local ok, message, action = D.AssignBindingItem(S.selectedBindingKey, itemId, itemName)
    if message then D.Print(message) end
    if not ok then return false end
    D.Print("bound |cff00ff00" .. action.itemName .. "|r to "
        .. GetBindingSlotLabel(S.selectedBindingKey))
    RefreshHealingBindings()
    return true
end

local function ClearBinding(slotKey)
    local ok, message = D.ClearBindingAction(slotKey)
    if message then D.Print(message) end
    if not ok then return false end
    RefreshHealingBindings()
    return true
end

local function AssignFromSpellButton(spellButton)
    if not S.configMode or not IsAssignableTab(S.configTab)
        or not IsShiftKeyDown() or InCombatLockdown() then
        return false
    end

    local spellID, spellName = D.GetSpellFromSpellButton(spellButton)
    if not spellID and not spellName then
        D.Print("could not read that spell — try another click.")
        return false
    end

    if S.configTab == "keys" then
        local layoutKey = S.selectedKeyLayout
        if not K.IsKnownLayout(layoutKey) then layoutKey = K.GetActiveLayoutKey() end
        local ok, message, assignedSlot = K.AssignSpell(layoutKey,
            S.selectedKeySlot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            S.selectedKeyLayout = layoutKey
            S.focusedKeySlot = assignedSlot
            S.selectedKeySlot = nil
            local ui = D.GetConfigUI()
            if ui and ui.RefreshKeyPanel then ui.RefreshKeyPanel(assignedSlot) end
        end
        return ok
    elseif S.configTab == "wheel" then
        local layoutKey = S.selectedWheelLayout
        if not W.IsKnownLayout(layoutKey) then layoutKey = W.GetActiveLayoutKey() end
        local ok, message, assignedSlot = W.AssignSpell(layoutKey,
            S.selectedWheelSlot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            S.selectedWheelLayout = layoutKey
            S.selectedWheelSlot = nil
            local ui = D.GetConfigUI()
            if ui and ui.RefreshWheelPanel then ui.RefreshWheelPanel(assignedSlot) end
        end
        return ok
    elseif S.configTab == "shortcuts" then
        local ok, message, assignedSlot = T.AssignSpell(S.selectedShortcutSlot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            S.selectedShortcutSlot = nil
            D.SyncVisualTicker()
            local ui = D.GetConfigUI()
            if ui and ui.RefreshShortcutPanel then ui.RefreshShortcutPanel(assignedSlot) end
        end
        return ok
    end

    return AssignBindingSpell(spellID, spellName)
end

local function AssignFromItemButton(itemButton)
    if not S.configMode or not IsAssignableTab(S.configTab)
        or not IsShiftKeyDown() or InCombatLockdown() then
        return false
    end

    local parent = itemButton and itemButton.GetParent and itemButton:GetParent()
    local bagId = itemButton and itemButton.GetBagID and itemButton:GetBagID()
        or (parent and parent.GetID and parent:GetID())
    local slotId = itemButton and itemButton.GetID and itemButton:GetID()
    local itemId = bagId ~= nil and slotId and C_Container and C_Container.GetContainerItemID
        and C_Container.GetContainerItemID(bagId, slotId)
    local itemName = itemId and Items and Items.GetInfo and Items.GetInfo(itemId)
    if not itemId or not itemName then
        D.Print("could not read that item — try another click.")
        return false
    end

    local function DismissNativeSplitStack()
        if StackSplitFrame and StackSplitFrame.IsShown and StackSplitFrame:IsShown() then
            StackSplitFrame:Hide()
        end
    end

    if S.configTab == "healing" then
        local ok = AssignBindingItem(itemId, itemName)
        if ok then DismissNativeSplitStack() end
        return ok
    elseif S.configTab == "keys" then
        local layoutKey = S.selectedKeyLayout
        if not K.IsKnownLayout(layoutKey) then layoutKey = K.GetActiveLayoutKey() end
        local ok, message, assignedSlot = K.AssignItem(layoutKey,
            S.selectedKeySlot, itemId, itemName)
        if message then D.Print(message) end
        if ok then
            DismissNativeSplitStack()
            S.selectedKeyLayout = layoutKey
            S.focusedKeySlot = assignedSlot
            S.selectedKeySlot = nil
            local ui = D.GetConfigUI()
            if ui and ui.RefreshKeyPanel then ui.RefreshKeyPanel(assignedSlot) end
        end
        return ok
    elseif S.configTab == "wheel" then
        local layoutKey = S.selectedWheelLayout
        if not W.IsKnownLayout(layoutKey) then layoutKey = W.GetActiveLayoutKey() end
        local ok, message, assignedSlot = W.AssignItem(layoutKey,
            S.selectedWheelSlot, itemId, itemName)
        if message then D.Print(message) end
        if ok then
            DismissNativeSplitStack()
            S.selectedWheelLayout = layoutKey
            S.selectedWheelSlot = nil
            local ui = D.GetConfigUI()
            if ui and ui.RefreshWheelPanel then ui.RefreshWheelPanel(assignedSlot) end
        end
        return ok
    end

    local ok, message, assignedSlot = T.AssignItem(S.selectedShortcutSlot, itemId, itemName)
    if message then D.Print(message) end
    if ok then
        DismissNativeSplitStack()
        S.selectedShortcutSlot = nil
        D.SyncVisualTicker()
        local ui = D.GetConfigUI()
        if ui and ui.RefreshShortcutPanel then ui.RefreshShortcutPanel(assignedSlot) end
    end
    return ok
end

local function HookSpellButton(button)
    if not button or button._PHSpellHooked then return false end
    button._PHSpellHooked = true
    -- HookScript is a secure post-hook: Blizzard finishes its protected click
    -- handler before this callback observes a Shift-click. Never use PreClick
    -- or replace the Spellbook button's OnClick script.
    button:HookScript("OnClick", function(self)
        AssignFromSpellButton(self)
    end)
    return true
end

local function HookSpellbook()
    if S.spellbookHooked then return true end
    local foundButton = false
    for i = 1, 12 do
        local button = _G["SpellButton" .. i]
        if button then foundButton = true; HookSpellButton(button) end
    end
    for i = 1, 24 do
        local button = _G["SpellBookSkillLineAbility" .. i]
        if button then foundButton = true; HookSpellButton(button) end
    end
    S.spellbookHooked = foundButton
    return foundButton
end

local function HookContainerItems()
    if S.containerItemsHooked then return true end
    if type(hooksecurefunc) ~= "function"
        or type(ContainerFrameItemButton_OnModifiedClick) ~= "function" then
        return false
    end
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(button)
        AssignFromItemButton(button)
    end)
    S.containerItemsHooked = true
    return true
end

function B.Initialize(deps) D = deps end
B.ClearBinding = ClearBinding
B.HookSpellbook = HookSpellbook
B.HookContainerItems = HookContainerItems
