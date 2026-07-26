ApogeePartyHealthBars_C = { MAX_ROWS = 1, MAX_PARTY_BUFF_SLOTS = 2 }
ApogeePartyHealthBars_S = {}
ApogeePartyHealthBars_UnitAPI = { Exists = function() return true end }

local inCombat = false
function InCombatLockdown() return inCombat end

local function frame(shown)
    local value = { shown = shown == true, mouseEnabled = false, attributes = {}, mutations = 0 }
    function value:IsShown() return self.shown end
    function value:Show() self.shown = true; self.mutations = self.mutations + 1 end
    function value:Hide() self.shown = false; self.mutations = self.mutations + 1 end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled; self.mutations = self.mutations + 1 end
    function value:SetAttribute(key, data) self.attributes[key] = data; self.mutations = self.mutations + 1 end
    return value
end

local primary = {
    unitId = "player", visible = true, btn = frame(true),
    partyBuffIcons = { frame(true), frame(true) },
    partyBuffCastBtns = { frame(false), frame(false) },
}
local target = {
    unitId = "target", visible = true, btn = frame(true),
    partyBuffIcons = { frame(true), frame(true) },
    partyBuffCastBtns = { frame(false), frame(false) },
}
local row = { btn = primary.btn, surfaces = { primary, target } }

local clickable, deferred, selfBindings = true, 0, 0
dofile("ApogeePartyHealthBars_Layout.lua")
local layout = ApogeePartyHealthBars_Layout
layout.Register({
    rows = { row },
    IsSavedFeatureEnabled = function(key)
        assert(key == "clickableBuffIcons")
        return clickable
    end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
    HideSecureFrame = function(value) value:Hide() end,
    ShowSecureFrame = function(value) value:Show() end,
    SetSecureMouseEnabled = function(value, enabled) value:EnableMouse(enabled) end,
    PositionSecureOverlay = function() return true end,
    GetPartyBuffCastSpellName = function(index)
        return index == 1 and "Power Word: Fortitude" or "Divine Spirit"
    end,
    PlayerUtility = {
        ApplyBinding = function() selfBindings = selfBindings + 1 end,
        HideSecureOverlay = function() end,
    },
})

layout.ApplyAllPartyBuffBindings()
layout.ApplyAllSelfBuffBindings()
assert(primary.partyBuffCastBtns[1].attributes.unit == "player")
assert(target.partyBuffCastBtns[1].attributes.unit == "target")
assert(primary.partyBuffCastBtns[1].attributes.macrotext
    == "/cast [@player,help,nodead] Power Word: Fortitude")
assert(target.partyBuffCastBtns[1].attributes.macrotext
    == "/cast [@target,help,nodead] Power Word: Fortitude")
assert(primary.partyBuffCastBtns[2].attributes.macrotext
    == "/cast [@player,help,nodead] Divine Spirit")
assert(primary.partyBuffCastBtns[1].shown and primary.partyBuffCastBtns[2].shown
        and target.partyBuffCastBtns[1].shown and target.partyBuffCastBtns[2].shown)
assert(selfBindings == 1, "self-buff binding was not delegated")

clickable = false
layout.ApplyAllPartyBuffBindings()
for _, surface in ipairs(row.surfaces) do
    for index, button in ipairs(surface.partyBuffCastBtns) do
        assert(button.attributes.unit == nil)
        assert(not button.shown and not button.mouseEnabled)
        assert(surface.partyBuffIcons[index].shown,
            "disabling clickability hid a reminder texture")
    end
end

local mutationCount = 0
for _, surface in ipairs(row.surfaces) do
    for _, button in ipairs(surface.partyBuffCastBtns) do
        mutationCount = mutationCount + button.mutations
    end
end
clickable = true
inCombat = true
layout.ApplyAllPartyBuffBindings()
local combatMutationCount = 0
for _, surface in ipairs(row.surfaces) do
    for _, button in ipairs(surface.partyBuffCastBtns) do
        combatMutationCount = combatMutationCount + button.mutations
    end
end
assert(combatMutationCount == mutationCount)
assert(deferred == 1, "protected buff bindings did not defer as one transaction")

print("PASS clickable buff reminders")
