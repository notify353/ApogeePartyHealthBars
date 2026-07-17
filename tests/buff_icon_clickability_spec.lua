ApogeePartyHealthBars_C = { MAX_ROWS = 1 }
ApogeePartyHealthBars_S = {}

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitExists() return true end

local function frame(shown)
    local value = {
        shown = shown == true,
        mouseEnabled = false,
        attributes = {},
        mutations = 0,
    }
    function value:IsShown() return self.shown end
    function value:Show() self.shown = true; self.mutations = self.mutations + 1 end
    function value:Hide() self.shown = false; self.mutations = self.mutations + 1 end
    function value:EnableMouse(enabled)
        self.mouseEnabled = enabled
        self.mutations = self.mutations + 1
    end
    function value:SetAttribute(key, attributeValue)
        self.attributes[key] = attributeValue
        self.mutations = self.mutations + 1
    end
    return value
end

local row = {
    unitId = "player",
    showTargetPane = true,
    btn = frame(true),
    castBtn = frame(true),
    partyBuffIcon = frame(true),
    targetPartyBuffIcon = frame(true),
    selfBuffIcon = frame(true),
    partyBuffCastBtn = frame(false),
    targetPartyBuffCastBtn = frame(false),
    selfBuffCastBtn = frame(false),
}
row.castBtn.attributes.spell1 = "Flash Heal"

local clickable = true
local deferred = 0
local function hide(overlay) overlay:Hide() end
local function show(overlay) overlay:Show() end
local function setMouseEnabled(overlay, enabled) overlay:EnableMouse(enabled) end

dofile("ApogeePartyHealthBars_Layout.lua")
local layout = ApogeePartyHealthBars_Layout
layout.Register({
    rows = { row },
    IsSavedFeatureEnabled = function(key)
        assert(key == "clickableBuffIcons")
        return clickable
    end,
    GetUnitTargetToken = function(unitId) return unitId .. "target" end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
    HideSecureFrame = hide,
    ShowSecureFrame = show,
    SetSecureMouseEnabled = setMouseEnabled,
    PositionSecureOverlay = function() return true end,
    GetPartyBuffCastSpellName = function() return "Power Word: Fortitude" end,
    GetSelfBuffCastSpellName = function() return "Inner Fire" end,
})

layout.ApplyAllPartyBuffBindings()
layout.ApplyAllSelfBuffBindings()

assert(row.partyBuffCastBtn.attributes.unit == "player")
assert(row.partyBuffCastBtn.attributes.macrotext == "/cast [@player,help,nodead] Power Word: Fortitude")
assert(row.targetPartyBuffCastBtn.attributes.unit == "playertarget")
assert(row.targetPartyBuffCastBtn.attributes.macrotext == "/cast [@playertarget,help,nodead] Power Word: Fortitude")
assert(row.selfBuffCastBtn.attributes.unit == "player")
assert(row.selfBuffCastBtn.attributes.macrotext == "/cast [@player,help,nodead] Inner Fire")
assert(row.partyBuffCastBtn.shown and row.partyBuffCastBtn.mouseEnabled)
assert(row.targetPartyBuffCastBtn.shown and row.targetPartyBuffCastBtn.mouseEnabled)
assert(row.selfBuffCastBtn.shown and row.selfBuffCastBtn.mouseEnabled)

clickable = false
layout.ApplyAllPartyBuffBindings()
layout.ApplyAllSelfBuffBindings()

for _, overlay in ipairs({
    row.partyBuffCastBtn,
    row.targetPartyBuffCastBtn,
    row.selfBuffCastBtn,
}) do
    assert(overlay.attributes.unit == nil, "disabled overlay retained its unit")
    assert(overlay.attributes.type == nil, "disabled overlay retained its action type")
    assert(overlay.attributes.macrotext == nil, "disabled overlay retained its macro")
    assert(not overlay.shown, "disabled overlay remained visible")
    assert(not overlay.mouseEnabled, "disabled overlay retained mouse capture")
end
assert(row.partyBuffIcon.shown and row.targetPartyBuffIcon.shown and row.selfBuffIcon.shown,
    "disabling clickability hid reminder textures")
assert(row.castBtn.attributes.spell1 == "Flash Heal", "ordinary row click binding changed")

local mutationCount = row.partyBuffCastBtn.mutations
    + row.targetPartyBuffCastBtn.mutations
    + row.selfBuffCastBtn.mutations
clickable = true
inCombat = true
layout.ApplyAllPartyBuffBindings()
layout.ApplyAllSelfBuffBindings()
local combatMutationCount = row.partyBuffCastBtn.mutations
    + row.targetPartyBuffCastBtn.mutations
    + row.selfBuffCastBtn.mutations
assert(combatMutationCount == mutationCount, "secure overlays mutated during combat")
assert(deferred == 2, "combat updates were not deferred")

inCombat = false
layout.ApplyAllPartyBuffBindings()
layout.ApplyAllSelfBuffBindings()
assert(row.partyBuffCastBtn.attributes.unit == "player", "party buff overlay was not restored")
assert(row.targetPartyBuffCastBtn.attributes.unit == "playertarget", "target buff overlay was not restored")
assert(row.selfBuffCastBtn.attributes.unit == "player", "self buff overlay was not restored")
assert(row.castBtn.attributes.spell1 == "Flash Heal", "row click binding changed after deferred refresh")

print("PASS clickable buff reminders")
