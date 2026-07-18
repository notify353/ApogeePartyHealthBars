local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local F = ApogeePartyHealthBars_SecureFrames

ApogeePartyHealthBars_ClickBindings = {}
local B = ApogeePartyHealthBars_ClickBindings
local D

local function ClearCastAttributes(castBtn)
    castBtn:SetAttribute("unit", nil)
    castBtn:SetAttribute("type", nil)
    castBtn:SetAttribute("spell", nil)
    castBtn:SetAttribute("item", nil)
    for _, slot in ipairs(C.BINDING_SLOTS) do
        local typeAttr, spellAttr, itemAttr = D.KeyToActionAttrs(slot.key)
        if typeAttr then
            castBtn:SetAttribute(typeAttr, nil)
            castBtn:SetAttribute(spellAttr, nil)
            castBtn:SetAttribute(itemAttr, nil)
        end
    end
end

local function SetClickAction(castBtn, slotKey, action)
    local typeAttr, spellAttr, itemAttr = D.KeyToActionAttrs(slotKey)
    if not typeAttr then return end
    local actionType, payloadAttr, payload
    if action.kind == "item" then
        actionType, payloadAttr, payload = "item", itemAttr, "item:" .. tostring(action.itemId)
    else
        actionType, payloadAttr = "spell", spellAttr
        payload = action.spellId or action.spellName
    end
    if not payload then return end
    castBtn:SetAttribute(typeAttr, actionType)
    castBtn:SetAttribute(payloadAttr, payload)
    if slotKey == "1" then
        castBtn:SetAttribute("type", actionType)
        castBtn:SetAttribute(actionType, payload)
    end
end

local function RowHasBindings()
    local bindings = D.GetBindingsTable()
    if not bindings then return false end
    for _, slot in ipairs(C.BINDING_SLOTS) do
        if D.GetBindingAction(bindings[slot.key]) then
            return true
        end
    end
    return false
end

local function ApplyClickBindings(castBtn, unitId, active, visibilityFrame)
    if not castBtn or InCombatLockdown() then
        F.RequestSecureUpdate()
        return
    end

    ClearCastAttributes(castBtn)

    if not active or not unitId then
        F.SetMouseEnabled(castBtn, false)
        F.Hide(castBtn)
        return
    end

    castBtn:SetAttribute("unit", unitId)

    local hasBinding = false
    local bindings = D.GetBindingsTable()
    if bindings then
        for _, slot in ipairs(C.BINDING_SLOTS) do
            local action = D.GetBindingAction(bindings[slot.key])
            if action then
                hasBinding = true
                SetClickAction(castBtn, slot.key, action)
            end
        end
    end

    if hasBinding and visibilityFrame:IsShown() then
        F.Show(castBtn)
        F.SetMouseEnabled(castBtn, true)
    else
        F.SetMouseEnabled(castBtn, false)
        F.Hide(castBtn)
    end
end

local function ApplyAllBindings()
    if InCombatLockdown() then
        F.RequestSecureUpdate()
        return
    end

    local castingEnabled = not S.configMode and RowHasBindings()

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        for _, surface in ipairs(row.surfaces) do
            local active = row.btn:IsShown() and surface.visible ~= false
                and surface.unitId and UnitExists(surface.unitId)
                and (not UnitIsConnected or UnitIsConnected(surface.unitId))
                and castingEnabled
            ApplyClickBindings(
                surface.castBtn, surface.unitId, active, surface.btn)
        end
    end
end

function B.Initialize(deps) D = deps end
B.ApplyAll = ApplyAllBindings
