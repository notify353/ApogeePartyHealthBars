ApogeePartyHealthBars_C = { MAX_ROWS = 1 }
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
    partyBuffIcon = frame(true), partyBuffCastBtn = frame(false),
}
local target = {
    unitId = "target", visible = true, btn = frame(true),
    partyBuffIcon = frame(true), partyBuffCastBtn = frame(false),
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
    GetPartyBuffCastSpellName = function() return "Power Word: Fortitude" end,
    PlayerUtility = {
        ApplyBinding = function() selfBindings = selfBindings + 1 end,
        HideSecureOverlay = function() end,
    },
})

layout.ApplyAllPartyBuffBindings()
layout.ApplyAllSelfBuffBindings()
assert(primary.partyBuffCastBtn.attributes.unit == "player")
assert(target.partyBuffCastBtn.attributes.unit == "target")
assert(primary.partyBuffCastBtn.attributes.macrotext
    == "/cast [@player,help,nodead] Power Word: Fortitude")
assert(target.partyBuffCastBtn.attributes.macrotext
    == "/cast [@target,help,nodead] Power Word: Fortitude")
assert(primary.partyBuffCastBtn.shown and target.partyBuffCastBtn.shown)
assert(selfBindings == 1, "self-buff binding was not delegated")

clickable = false
layout.ApplyAllPartyBuffBindings()
for _, surface in ipairs(row.surfaces) do
    assert(surface.partyBuffCastBtn.attributes.unit == nil)
    assert(not surface.partyBuffCastBtn.shown and not surface.partyBuffCastBtn.mouseEnabled)
    assert(surface.partyBuffIcon.shown, "disabling clickability hid a reminder texture")
end

local mutationCount = primary.partyBuffCastBtn.mutations + target.partyBuffCastBtn.mutations
clickable = true
inCombat = true
layout.ApplyAllPartyBuffBindings()
assert(primary.partyBuffCastBtn.mutations + target.partyBuffCastBtn.mutations == mutationCount)
assert(deferred == 1, "protected buff bindings did not defer as one transaction")

print("PASS clickable buff reminders")
