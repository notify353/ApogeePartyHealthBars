local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_SpellTracker
local W = ApogeePartyHealthBars_WheelMacros

ApogeePartyHealthBars_BindingController = {}
local B = ApogeePartyHealthBars_BindingController
local D

local function AssignBinding(spellID, spellName)
    if not S.selectedBindingKey then return end
    if InCombatLockdown() then
        D.Print("cannot bind spells in combat.")
        return
    end

    if not spellName or spellName == "" then
        if type(spellID) == "number" then
            spellName = GetSpellInfo(spellID)
        elseif type(spellID) == "string" then
            spellName = spellID
        end
    end
    if not spellName or spellName == "" then
        D.Print("could not store that spell.")
        return
    end

    local bindings = D.GetBindingsTable()
    if not bindings then return end
    bindings[S.selectedBindingKey] = {
        id   = (type(spellID) == "number" and spellID > 0) and spellID or nil,
        name = spellName,
    }

    for _, slot in ipairs(C.BINDING_SLOTS) do
        if slot.key == S.selectedBindingKey then
            D.Print("bound |cff00ff00" .. spellName .. "|r to " .. slot.label)
            break
        end
    end

    D.RefreshBindPanel()
    D.ForceRefresh()
end

local function ClearBinding(slotKey)
    local bindings = D.GetBindingsTable()
    if not bindings then return end
    if InCombatLockdown() then
        D.Print("cannot change bindings in combat.")
        return
    end
    bindings[slotKey] = nil
    D.RefreshBindPanel()
    D.ForceRefresh()
end

local function AssignFromSpellButton(spellButton)
    if not S.configMode or (not S.selectedBindingKey and not S.selectedTrackerSlot and not S.selectedWheelSlot)
        or not IsShiftKeyDown() or InCombatLockdown() then
        return false
    end

    local spellID, spellName = D.GetSpellFromSpellButton(spellButton)
    if not spellID and not spellName then
        D.Print("could not read that spell — try another click.")
        return false
    end

    if S.selectedWheelSlot then
        local ok, message = W.AssignDisplaySpell(S.selectedWheelLayout,
            S.selectedWheelSlot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            local ui = D.GetConfigUI()
            if ui and ui.RefreshWheelPanel then ui.RefreshWheelPanel(true) end
        end
        return ok
    elseif S.selectedTrackerSlot then
        local ok, message = T.AssignSpell(S.selectedTrackerSlot, spellID, spellName)
        if message then D.Print(message) end
        if ok then
            D.SyncVisualTicker()
            local ui = D.GetConfigUI()
            if ui and ui.RefreshSpellPanel then ui.RefreshSpellPanel() end
        end
        return ok
    end

    AssignBinding(spellID or spellName, spellName)
    return true
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

function B.Initialize(deps) D = deps end
B.ClearBinding = ClearBinding
B.HookSpellbook = HookSpellbook
