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
    for _, slot in ipairs(C.BINDING_SLOTS) do
        local typeAttr, spellAttr = D.KeyToSpellAttrs(slot.key)
        if typeAttr then
            castBtn:SetAttribute(typeAttr, nil)
            castBtn:SetAttribute(spellAttr, nil)
        end
    end
end

local function SetClickSpell(castBtn, slotKey, spellName)
    local typeAttr, spellAttr = D.KeyToSpellAttrs(slotKey)
    if not typeAttr then return end
    castBtn:SetAttribute(typeAttr, "spell")
    castBtn:SetAttribute(spellAttr, spellName)
    if slotKey == "1" then
        castBtn:SetAttribute("type", "spell")
        castBtn:SetAttribute("spell", spellName)
    end
end

local function RowHasBindings()
    local bindings = D.GetBindingsTable()
    if not bindings then return false end
    for _, slot in ipairs(C.BINDING_SLOTS) do
        if D.GetBindingSpellName(bindings[slot.key]) then
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
            local spellName = D.GetBindingSpellName(bindings[slot.key])
            if spellName then
                hasBinding = true
                SetClickSpell(castBtn, slot.key, spellName)
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
        if row.btn:IsShown() and UnitExists(row.unitId)
            and (not UnitIsConnected or UnitIsConnected(row.unitId))
            and castingEnabled then
            ApplyClickBindings(row.castBtn, row.unitId, true, row.btn)
        else
            ApplyClickBindings(row.castBtn, row.unitId, false, row.btn)
        end

        local targetUnitId = row.showTargetPane and D.GetUnitTargetToken(row.unitId) or nil
        if row.btn:IsShown() and targetUnitId and UnitExists(targetUnitId)
            and (not UnitIsConnected or UnitIsConnected(targetUnitId))
            and castingEnabled then
            ApplyClickBindings(row.targetCastBtn, targetUnitId, true, row.targetBtn)
        else
            ApplyClickBindings(row.targetCastBtn, nil, false, row.targetBtn)
        end
    end
end

function B.Initialize(deps) D = deps end
B.ApplyAll = ApplyAllBindings

