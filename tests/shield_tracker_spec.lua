unpack = unpack or table.unpack

ApogeePartyHealthBars_C = {
    SLOT_UNITS = { "player", "party1" },
    PW_SHIELD_RANKS = {
        [17] = { 80, 0.2 },
        [25218] = { 100, 0.5 },
    },
}
local clientFlavor = "tbcAnniversary"
ApogeePartyHealthBars_ClientCapabilities = {
    GetClientInfo = function() return { flavor = clientFlavor } end,
}

local existing = { player = true, party1 = true, target = true }
local dead = {}
local snapshots = {
    player = { hasShield = false },
    party1 = { hasShield = false },
}
local featureEnabled = true
local configMode = false
local requestUpdates = 0
local currentCombatLog

function UnitExists(unitId) return existing[unitId] == true end
function UnitIsDeadOrGhost(unitId) return dead[unitId] == true end
function UnitGUID(unitId) return unitId and ("GUID-" .. unitId) or nil end
function UnitHealth() return 50 end
function UnitHealthMax() return 100 end
function GetSpellBonusHealing() return 50 end
function CombatLogGetCurrentEventInfo()
    if not currentCombatLog then return nil end
    return unpack(currentCombatLog, 1, 22)
end

local Auras = {
    GetUnitAuraSnapshot = function(unitId)
        return snapshots[unitId] or { hasShield = false }
    end,
    UnitHasPWShieldFromSnapshot = function(snapshot)
        return snapshot and snapshot.hasShield == true
    end,
    GetShieldPointsFromSnapshot = function(snapshot)
        return snapshot and snapshot.amount or nil
    end,
    GetShieldSpellIdFromSnapshot = function(snapshot)
        return snapshot and snapshot.spellId or nil
    end,
    IsPowerWordShieldAura = function(spellId, spellName)
        return spellId == 17 or spellId == 25218 or spellName == "Power Word: Shield"
    end,
}

local function CombatLogEvent(subevent)
    local info = {}
    for index = 1, 22 do info[index] = false end
    info[1] = 1
    info[2] = subevent
    info[4] = "GUID-player"
    info[8] = "GUID-player"
    return info
end

local function ShieldBar()
    local bar = { shown = false, points = {} }
    function bar:ClearAllPoints() self.points = {} end
    function bar:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function bar:SetWidth(width) self.width = width end
    function bar:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function bar:SetValue(value) self.value = value end
    function bar:Show() self.shown = true end
    function bar:Hide() self.shown = false end
    return bar
end

dofile("ApogeePartyHealthBars_UnitAPI.lua")
dofile("ApogeePartyHealthBars_ShieldTracker.lua")
local tracker = ApogeePartyHealthBars_ShieldTracker

local valid, validationError = pcall(tracker.Initialize, {})
assert(not valid and tostring(validationError):find("Auras", 1, true),
    "ShieldTracker accepted incomplete dependencies")

tracker.Initialize({
    Auras = Auras,
    IsSavedFeatureEnabled = function(key)
        assert(key == "shieldEnabled")
        return featureEnabled
    end,
    IsConfigMode = function() return configMode end,
    RequestUpdate = function() requestUpdates = requestUpdates + 1 end,
    IsTrackedUnit = function(unitId)
        return unitId == "player" or unitId == "party1" or unitId == "target"
    end,
    GetTrackedUnits = function() return { "player", "party1", "target" } end,
})

assert(tracker.IsEnabled(), "shield feature state was not forwarded")
assert(tracker.ShouldTrackUnit("player") and tracker.ShouldTrackUnit("party1")
        and tracker.ShouldTrackUnit("target"),
    "registered primary or target unit was rejected")
dead.party1 = true
assert(not tracker.ShouldTrackUnit("party1"), "dead party unit remained trackable")
dead.party1 = nil

snapshots.player = { hasShield = true, amount = 300 }
tracker.SeedFromAuras()
assert(tracker.GetRemaining("player") == 300,
    "aura seeding did not prefer the client-reported shield amount")
snapshots.player.amount = 400
assert(tracker.GetRemaining("player") == 300,
    "display reads overwrote an existing shield ledger entry")

currentCombatLog = CombatLogEvent("SPELL_AURA_APPLIED")
currentCombatLog[12] = 17
currentCombatLog[13] = "Power Word: Shield"
currentCombatLog[16] = 250
tracker.OnCombatLog()
assert(tracker.GetRemaining("player") == 250 and requestUpdates == 1,
    "combat-log shield application did not set the ledger")

currentCombatLog = CombatLogEvent("SPELL_ABSORBED")
currentCombatLog[12] = 9001
currentCombatLog[13] = "Fireball"
currentCombatLog[19] = 17
currentCombatLog[22] = 40
tracker.OnCombatLog()
assert(tracker.GetRemaining("player") == 210 and requestUpdates == 2,
    "SPELL_ABSORBED did not reduce the shield ledger")

currentCombatLog = CombatLogEvent("SPELL_ABSORBED")
currentCombatLog[12] = "SWING"
currentCombatLog[16] = 17
currentCombatLog[19] = 10
tracker.OnCombatLog()
assert(tracker.GetRemaining("player") == 200 and requestUpdates == 3,
    "swing SPELL_ABSORBED payload did not reduce the shield ledger")

currentCombatLog = CombatLogEvent("SPELL_AURA_REFRESH")
currentCombatLog[12] = 17
currentCombatLog[13] = "Power Word: Shield"
tracker.OnCombatLog()
assert(tracker.GetRemaining("player") == 90 and requestUpdates == 4,
    "shield refresh without an amount did not use rank and healing estimation")

currentCombatLog = CombatLogEvent("SPELL_AURA_REMOVED")
currentCombatLog[12] = 17
currentCombatLog[13] = "Power Word: Shield"
snapshots.player = { hasShield = false }
tracker.OnCombatLog()
assert(tracker.GetRemaining("player") == 0 and requestUpdates == 5,
    "shield removal did not clear the ledger")

snapshots.party1 = { hasShield = true, amount = 333 }
assert(tracker.GetRemaining("party1") == 333, "aura shield amount fallback was lost")
snapshots.party1.amount = 444
assert(tracker.GetRemaining("party1") == 444,
    "aura fallback was incorrectly persisted into the private ledger")
snapshots.party1.amount = nil
assert(tracker.GetRemaining("party1") == 125,
    "missing aura amount did not fall back to the shield estimate")

local shieldBar = ShieldBar()
local row = {
    bar = { GetWidth = function() return 200 end },
    shieldBar = shieldBar,
}
snapshots.player = { hasShield = true, amount = 25 }
tracker.UpdateRowVisual(row, "player", 25)
assert(shieldBar.shown and shieldBar.width == 40,
    "shield segment width changed")
assert(shieldBar.points[1][4] == 80 and shieldBar.points[2][4] == 80,
    "shield segment no longer begins after current health")
assert(shieldBar.minimum == 0 and shieldBar.maximum == 1 and shieldBar.value == 1,
    "shield segment value range changed")

configMode = true
tracker.UpdateRowVisual(row, "player", 25)
assert(not shieldBar.shown, "configuration mode displayed a shield segment")
configMode = false
featureEnabled = false
tracker.UpdateRowVisual(row, "player", 25)
assert(not shieldBar.shown, "disabled shield feature displayed a segment")

featureEnabled = true
clientFlavor = "classicEra"
snapshots.player = { hasShield = true, spellId = 99999 }
assert(tracker.GetRemaining("player") == 0,
    "Classic Era unknown shield rank fell back to the TBC maximum")
snapshots.player.spellId = 17
assert(tracker.GetRemaining("player") == 90,
    "Classic Era recognized shield rank did not retain its verified estimate")

print("PASS shield tracker")
