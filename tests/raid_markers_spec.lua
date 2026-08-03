ApogeePartyHealthBars_S = { sv = { enabled = true } }

local featureSupported = true
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(key)
        return key == "raidMarkers" and featureSupported
    end,
}

local enabled = false
local inCombat = false
local recommendation
local applied = {}
local target = {
    exists = true,
    hostile = true,
    dead = false,
    guid = "Creature-0-0-0-0-4293-0000000001",
    marker = nil,
}

function UnitExists(unit) return unit == "target" and target.exists end
function UnitCanAttack(source, unit)
    return source == "player" and unit == "target" and target.hostile
end
function UnitIsDeadOrGhost(unit) return unit == "target" and target.dead end
function UnitGUID(unit) return unit == "target" and target.guid or nil end
function GetRaidTargetIndex(unit) return unit == "target" and target.marker or nil end
function InCombatLockdown() return inCombat end
function SetRaidTarget(unit, markerIndex)
    applied[#applied + 1] = { unit, markerIndex, target.guid }
    target.marker = markerIndex
end

dofile("PartyFrames/RaidMarkers.lua")
local Markers = ApogeePartyHealthBars_RaidMarkers

local valid, validationError = pcall(Markers.Initialize, {})
assert(not valid and tostring(validationError):find("policy and settings", 1, true),
    "automatic raid markers accepted incomplete dependencies")

Markers.Initialize({
    Policy = { GetRecommendationForGuid = function() return recommendation end },
    Settings = { GetAutoMarkEnabled = function() return enabled end },
})

local function evaluate(markerIndex)
    recommendation = markerIndex and { markerIndex = markerIndex } or nil
    return Markers.EvaluateCurrentTarget()
end

evaluate(8)
assert(#applied == 0, "disabled automatic marking changed the target")

enabled = true
ApogeePartyHealthBars_S.sv.enabled = false
evaluate(8)
assert(#applied == 0, "automatic marking ignored the add-on enabled state")
ApogeePartyHealthBars_S.sv.enabled = true

target.exists = false
evaluate(8)
target.exists = true
target.hostile = false
evaluate(8)
target.hostile = true
target.dead = true
evaluate(8)
target.dead = false
assert(#applied == 0, "invalid, friendly, or dead targets were marked")

evaluate(nil)
recommendation = { markerKey = "none", markerIndex = nil }
Markers.EvaluateCurrentTarget()
assert(#applied == 0, "unknown or No Mark recommendations applied a marker")

for _, markerIndex in ipairs({ 8, 7, 5, 2 }) do
    target.marker = nil
    target.guid = target.guid .. tostring(markerIndex)
    local result = evaluate(markerIndex)
    assert(result == recommendation
            and applied[#applied][1] == "target"
            and applied[#applied][2] == markerIndex,
        "out-of-combat target did not receive its recommended marker")
end
assert(#applied == 4,
    "rapid target cycling retained assignment state instead of evaluating each target")

target.marker = 1
evaluate(2)
assert(#applied == 4 and target.marker == 1,
    "an existing target marker was replaced or cleared")

inCombat = true
target.marker = nil
evaluate(7)
evaluate(5)
assert(#applied == 4, "Cross or Moon was applied during combat")
local result = evaluate(8)
assert(result == recommendation and #applied == 5 and target.marker == 8,
    "Skull was not applied during combat")
target.marker = nil
target.guid = target.guid .. "2"
result = evaluate(2)
assert(result == recommendation and #applied == 6 and target.marker == 2,
    "Circle was not applied to a boss during combat")

featureSupported = false
target.marker = nil
evaluate(8)
assert(#applied == 6, "unsupported raid-marker APIs were used")

assert(Markers.GetContainer == nil
        and Markers.GetButton == nil
        and Markers.SetRecommendation == nil
        and Markers.GetAssignedGuid == nil
        and Markers.OnCombatLogEvent == nil,
    "removed marker UI or assignment-tracking APIs were still exposed")

print("PASS stateless automatic dungeon marking")
