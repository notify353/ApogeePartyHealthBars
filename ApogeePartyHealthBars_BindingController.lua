local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_SpellTracker

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

local function HookSpellButton(btn)
    if not btn or btn._PHSpellHooked then return false end
    btn._PHSpellHooked = true
    btn:HookScript("PreClick", function(self)
        if not S.configMode or (not S.selectedBindingKey and not S.selectedTrackerSlot)
            or not IsShiftKeyDown() then return end
        local spellID, spellName = D.GetSpellFromSpellButton(self)
        if spellID or spellName then
            if S.selectedTrackerSlot then
                local ok, message = T.AssignSpell(S.selectedTrackerSlot, spellID, spellName)
                if message then D.Print(message) end
                if ok then
                    D.SyncVisualTicker()
                    local ui = D.GetConfigUI(); if ui and ui.RefreshSpellPanel then ui.RefreshSpellPanel() end
                end
            else
                AssignBinding(spellID or spellName, spellName)
            end
        else
            D.Print("could not read that spell — try another click.")
        end
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

local function OpenSpellbook()
    local alreadyOpen = SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown()
    if not alreadyOpen and ToggleSpellBook then
        ToggleSpellBook(BOOKTYPE_SPELL)
    elseif not alreadyOpen and SpellBookFrame and ShowUIPanel then
        ShowUIPanel(SpellBookFrame)
    end
    HookSpellbook()
    return SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown() or false
end

function B.Initialize(deps) D = deps end
B.ClearBinding = ClearBinding
B.HookSpellbook = HookSpellbook
B.OpenSpellbook = OpenSpellbook
