ApogeePartyHealthBars_C = {
    SLOT_UNITS = { "player", "party1", "party2" },
}

local existing = {
    player = true,
    target = true,
    party1 = true,
    party1target = true,
    party2 = true,
}
local dead = {}
local sameUnit = {}
local incomingByUnit = {}
local featureEnabled = true
local configMode = false

function UnitExists(unitId) return existing[unitId] == true end
function UnitIsDeadOrGhost(unitId) return dead[unitId] == true end
function UnitIsUnit(left, right) return sameUnit[left .. ":" .. right] == true end
function UnitGetIncomingHeals(unitId) return incomingByUnit[unitId] end
function UnitHealth() return 50 end
function UnitHealthMax() return 100 end

local function PredictionBar()
    local bar = { shown = false }
    function bar:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function bar:SetValue(value) self.value = value end
    function bar:Show() self.shown = true end
    function bar:Hide() self.shown = false end
    return bar
end

dofile("ApogeePartyHealthBars_IncomingHeals.lua")
local incomingHeals = ApogeePartyHealthBars_IncomingHeals

local valid, validationError = pcall(incomingHeals.Initialize, {})
assert(not valid and tostring(validationError):find("IsSavedFeatureEnabled", 1, true),
    "IncomingHeals accepted incomplete dependencies")

incomingHeals.Initialize({
    IsSavedFeatureEnabled = function(key)
        assert(key == "incomingHealEnabled")
        return featureEnabled
    end,
    IsConfigMode = function() return configMode end,
    IsTrackedUnit = function(unitId)
        return unitId ~= "focus"
    end,
})

assert(incomingHeals.IsEnabled(), "incoming-heal feature state was not forwarded")
for _, unitId in ipairs({ "player", "target", "party1", "party1target", "targettarget",
    "party1targettarget" }) do
    existing[unitId] = true
    assert(incomingHeals.ShouldTrackUnit(unitId), unitId .. " was rejected")
end
assert(not incomingHeals.ShouldTrackUnit("focus"), "untracked unit was accepted")
dead.party1 = true
assert(not incomingHeals.ShouldTrackUnit("party1"), "dead party unit was accepted")
dead.party1 = nil

incomingByUnit.player = 35
assert(incomingHeals.GetAmount("player") == 35, "direct incoming heal was lost")

incomingByUnit.target = 0
incomingByUnit.party1 = 72
sameUnit["target:party1"] = true
assert(incomingHeals.GetAmount("target") == 72,
    "target alias did not fall back to its canonical party token")

local bar = PredictionBar()
incomingByUnit.player = 30
incomingHeals.UpdateBarVisual(bar, "player", 125)
assert(bar.shown and bar.minimum == 0 and bar.maximum == 125 and bar.value == 80,
    "incoming-heal overlay geometry changed")

incomingByUnit.player = 100
incomingHeals.UpdateBarVisual(bar, "player", 125)
assert(bar.value == 125, "incoming-heal overlay exceeded its visual maximum")

local rowBar = PredictionBar()
incomingByUnit.player = 20
incomingHeals.UpdateRowVisual({ healPredBar = rowBar }, "player", 100)
assert(rowBar.shown and rowBar.value == 70,
    "row wrapper did not forward incoming-heal geometry")

incomingByUnit.player = 0
incomingHeals.UpdateBarVisual(bar, "player", 100)
assert(not bar.shown, "zero incoming healing left the overlay visible")

incomingByUnit.player = 20
configMode = true
incomingHeals.UpdateBarVisual(bar, "player", 100)
assert(not bar.shown, "configuration mode displayed incoming healing")
configMode = false
featureEnabled = false
incomingHeals.UpdateBarVisual(bar, "player", 100)
assert(not bar.shown, "disabled incoming-heal feature displayed an overlay")

local originalUnitGetIncomingHeals = UnitGetIncomingHeals
UnitGetIncomingHeals = nil
featureEnabled = true
assert(incomingHeals.GetAmount("player") == 0,
    "missing client prediction API did not fail closed")
UnitGetIncomingHeals = originalUnitGetIncomingHeals

print("PASS incoming heals")
