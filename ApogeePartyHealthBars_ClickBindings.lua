local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local F = ApogeePartyHealthBars_SecureFrames

ApogeePartyHealthBars_ClickBindings = {}
local B = ApogeePartyHealthBars_ClickBindings
local D

local LEFT_CLICK_COMPOSITE_KEYS = {
    ["1"] = true,
    ["shift-1"] = true,
}

local function GetButtonKey(slotKey)
    return slotKey and slotKey:match("(%d+)$")
end

local function ClearCastAttributes(castBtn)
    castBtn:SetAttribute("unit", nil)
    castBtn:SetAttribute("type", nil)
    castBtn:SetAttribute("spell", nil)
    castBtn:SetAttribute("item", nil)
    castBtn:SetAttribute("macrotext", nil)
    for _, slot in ipairs(C.BINDING_SLOTS) do
        local typeAttr, spellAttr, itemAttr = D.KeyToActionAttrs(slot.key)
        if typeAttr then
            castBtn:SetAttribute(typeAttr, nil)
            castBtn:SetAttribute(spellAttr, nil)
            castBtn:SetAttribute(itemAttr, nil)
            castBtn:SetAttribute(typeAttr:gsub("type", "macrotext"), nil)
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

local function GetMacroLine(action, unitId, condition)
    if not action then return nil end
    local command, payload
    if action.kind == "item" then
        command, payload = "/use", action.itemId and ("item:" .. tostring(action.itemId))
    else
        command, payload = "/cast", action.spellName
    end
    if not payload then return nil end
    return command .. " [" .. condition .. ",@" .. unitId .. ",help,nodead] " .. payload
end

local function SetLeftClickActions(castBtn, unitId, normalAction, shiftAction)
    local lines = {}
    local shiftLine = GetMacroLine(
        shiftAction, unitId, "mod:shift,nomod:ctrl,nomod:alt")
    local normalLine = GetMacroLine(normalAction, unitId, "nomod")
    if shiftLine then lines[#lines + 1] = shiftLine end
    if normalLine then lines[#lines + 1] = normalLine end
    if #lines == 0 then return false end

    local macroText = table.concat(lines, "\n")
    castBtn:SetAttribute("type", "macro")
    castBtn:SetAttribute("macrotext", macroText)
    castBtn:SetAttribute("type1", "macro")
    castBtn:SetAttribute("macrotext1", macroText)
    return true
end

local function ApplyButtonBindings(castBtn, unitId, bindings, buttonKey)
    local hasBinding = false
    if buttonKey == "1" then
        local normalLeft = D.GetBindingAction(bindings["1"])
        local shiftLeft = D.GetBindingAction(bindings["shift-1"])
        hasBinding = SetLeftClickActions(castBtn, unitId, normalLeft, shiftLeft)
    end

    for _, slot in ipairs(C.BINDING_SLOTS) do
        if GetButtonKey(slot.key) == buttonKey
                and not LEFT_CLICK_COMPOSITE_KEYS[slot.key] then
            local action = D.GetBindingAction(bindings[slot.key])
            if action then
                hasBinding = true
                SetClickAction(castBtn, slot.key, action)
            end
        end
    end
    return hasBinding
end

local function ApplyBindingActions(castBtn, unitId, bindings)
    local hasBinding = false
    local seenButtons = {}
    for _, slot in ipairs(C.BINDING_SLOTS) do
        local buttonKey = GetButtonKey(slot.key)
        if buttonKey and not seenButtons[buttonKey] then
            seenButtons[buttonKey] = true
            if ApplyButtonBindings(castBtn, unitId, bindings, buttonKey) then
                hasBinding = true
            end
        end
    end
    return hasBinding
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
        hasBinding = ApplyBindingActions(castBtn, unitId, bindings)
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
