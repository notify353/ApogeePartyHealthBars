ApogeePartyHealthBars_S = { sv = { enabled = true } }

local featureSupported = true
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(key)
        return key == "raidMarkers" and featureSupported
    end,
}

local enabled = false
local inCombat = false
local applyAllowed = true
local attempts = {}
local recommendations = {}
local targets = {}
local current

local function addTarget(guid, markerIndex)
    local entry = {
        guid = guid, marker = nil, exists = true, hostile = true, dead = false,
    }
    targets[guid] = entry
    recommendations[guid] = markerIndex and { markerIndex = markerIndex } or nil
    return entry
end

local function selectTarget(guid)
    current = targets[guid]
    return current
end

local function setManualMarker(entry, markerIndex)
    if markerIndex then
        for _, target in pairs(targets) do
            if target.marker == markerIndex then target.marker = nil end
        end
    end
    entry.marker = markerIndex
end

function UnitExists(unit) return unit == "target" and current and current.exists end
function UnitCanAttack(source, unit)
    return source == "player" and unit == "target" and current and current.hostile
end
function UnitIsDeadOrGhost(unit) return unit == "target" and current and current.dead end
function UnitGUID(unit) return unit == "target" and current and current.guid or nil end
function GetRaidTargetIndex(unit) return unit == "target" and current and current.marker or nil end
function InCombatLockdown() return inCombat end
function SetRaidTarget(unit, markerIndex)
    attempts[#attempts + 1] = { unit, markerIndex, current and current.guid }
    if applyAllowed and current then setManualMarker(current, markerIndex) end
end

dofile("PartyFrames/RaidMarkers.lua")
local Markers = ApogeePartyHealthBars_RaidMarkers

local valid, validationError = pcall(Markers.Initialize, {})
assert(not valid and tostring(validationError):find("policy and settings", 1, true),
    "automatic raid markers accepted incomplete dependencies")

local deps = {
    Policy = { GetRecommendationForGuid = function(guid) return recommendations[guid] end },
    Settings = { GetAutoMarkEnabled = function() return enabled end },
}
Markers.Initialize(deps)

local invalid = addTarget("invalid", 8)
selectTarget("invalid")
Markers.EvaluateCurrentTarget()
assert(#attempts == 0, "disabled automatic marking changed the target")

enabled = true
ApogeePartyHealthBars_S.sv.enabled = false
Markers.EvaluateCurrentTarget()
assert(#attempts == 0, "automatic marking ignored the add-on enabled state")
ApogeePartyHealthBars_S.sv.enabled = true

invalid.exists = false
Markers.EvaluateCurrentTarget()
invalid.exists = true
invalid.hostile = false
Markers.EvaluateCurrentTarget()
invalid.hostile = true
invalid.dead = true
Markers.EvaluateCurrentTarget()
invalid.dead = false
assert(#attempts == 0, "invalid, friendly, or dead targets were marked")

recommendations.invalid = nil
Markers.EvaluateCurrentTarget()
recommendations.invalid = { markerKey = "none", markerIndex = nil }
Markers.EvaluateCurrentTarget()
recommendations.invalid = { markerIndex = 5 }
Markers.EvaluateCurrentTarget()
assert(#attempts == 0, "unknown, Moon, or No Auto Mark recommendations applied a marker")

Markers.Initialize(deps)
inCombat = true
local friendlyMarked = addTarget("friendly-marked", 8)
friendlyMarked.hostile, friendlyMarked.marker = false, 8
selectTarget(friendlyMarked.guid)
Markers.OnCombatStarted()
local afterFriendly = addTarget("after-friendly", 8)
selectTarget(afterFriendly.guid)
assert(Markers.EvaluateCurrentTarget() and afterFriendly.marker == 8,
    "a friendly marked target falsely reserved its icon")

Markers.Initialize(deps)
local deadMarked = addTarget("dead-marked", 7)
deadMarked.dead, deadMarked.marker = true, 7
selectTarget(deadMarked.guid)
Markers.OnRaidTargetUpdate()
local afterDead = addTarget("after-dead", 7)
selectTarget(afterDead.guid)
assert(Markers.EvaluateCurrentTarget() and afterDead.marker == 7,
    "a dead marked target falsely reserved its icon")

Markers.Initialize(deps)
inCombat = false
local skullA = addTarget("skull-a", 8)
local skullB = addTarget("skull-b", 8)
selectTarget(skullA.guid)
assert(Markers.EvaluateCurrentTarget() == recommendations[skullA.guid]
        and skullA.marker == 8, "first out-of-combat Skull was not applied")
selectTarget(skullB.guid)
assert(Markers.EvaluateCurrentTarget() == recommendations[skullB.guid]
        and skullA.marker == nil and skullB.marker == 8,
    "out-of-combat target cycling did not move Skull")

local crossA = addTarget("cross-a", 7)
local circleA = addTarget("circle-a", 2)
selectTarget(crossA.guid); Markers.EvaluateCurrentTarget()
selectTarget(circleA.guid); Markers.EvaluateCurrentTarget()
assert(crossA.marker == 7 and circleA.marker == 2,
    "Cross or boss Circle was not applied out of combat")

local alreadyMarked = addTarget("already-marked", 8)
alreadyMarked.marker = 1
selectTarget(alreadyMarked.guid)
local attemptsBeforeExisting = #attempts
Markers.EvaluateCurrentTarget()
assert(#attempts == attemptsBeforeExisting and alreadyMarked.marker == 1,
    "an existing target marker was replaced or cleared")

inCombat = true
selectTarget(circleA.guid)
Markers.OnCombatStarted()
local skullC = addTarget("skull-c", 8)
local crossB = addTarget("cross-b", 7)
local circleB = addTarget("circle-b", 2)
for _, entry in ipairs({ skullC, crossB, circleB }) do
    selectTarget(entry.guid)
    assert(Markers.EvaluateCurrentTarget() == nil and entry.marker == nil,
        "combat moved an icon away from its living owner")
end

Markers.Initialize(deps)
local manualSkull = addTarget("manual-skull", 8)
local nextSkull = addTarget("next-skull", 8)
local combatCross = addTarget("combat-cross", 7)
local combatCircle = addTarget("combat-circle", 2)
setManualMarker(manualSkull, 8)
selectTarget(manualSkull.guid)
Markers.OnCombatStarted()
selectTarget(nextSkull.guid)
assert(Markers.EvaluateCurrentTarget() == nil and nextSkull.marker == nil,
    "an observed manual Skull was stolen during combat")
selectTarget(combatCross.guid)
assert(Markers.EvaluateCurrentTarget() and combatCross.marker == 7,
    "an unlocked Cross was not assigned during combat")
selectTarget(combatCircle.guid)
assert(Markers.EvaluateCurrentTarget() and combatCircle.marker == 2,
    "an unlocked boss Circle was not assigned during combat")
combatCircle.dead, combatCircle.marker = true, nil
local attemptsBeforeCurrentDeath = #attempts
assert(Markers.OnUnitDied(combatCircle.guid)
        and #attempts == attemptsBeforeCurrentDeath,
    "death handling attempted to re-mark the dying current target")

selectTarget(manualSkull.guid)
setManualMarker(manualSkull, nil)
Markers.OnRaidTargetUpdate()
selectTarget(nextSkull.guid)
assert(Markers.EvaluateCurrentTarget() and nextSkull.marker == 8,
    "observed manual removal did not release its icon")
selectTarget(manualSkull.guid)
assert(Markers.EvaluateCurrentTarget() == nil and manualSkull.marker == nil,
    "manual removal was not respected for the rest of combat")

local replacementSkull = addTarget("replacement-skull", 8)
selectTarget(replacementSkull.guid)
assert(Markers.OnUnitDied(nextSkull.guid) and replacementSkull.marker == 8,
    "target death did not release and reassign its marker")
assert(not Markers.OnUnitDied(nil) and not Markers.OnUnitDied("unknown"),
    "invalid or untracked deaths changed marker ownership")

inCombat = false
selectTarget(manualSkull.guid)
assert(Markers.OnCombatEnded() and manualSkull.marker == 8
        and replacementSkull.marker == nil,
    "combat end did not clear suppression and restore fluid marking")

Markers.Initialize(deps)
inCombat = true
applyAllowed = false
local failedSkull = addTarget("failed-skull", 8)
selectTarget(failedSkull.guid)
assert(Markers.EvaluateCurrentTarget() == nil and failedSkull.marker == nil,
    "failed raid-marker assignment was reported as successful")
applyAllowed = true
local successfulSkull = addTarget("successful-skull", 8)
selectTarget(successfulSkull.guid)
assert(Markers.EvaluateCurrentTarget() and successfulSkull.marker == 8,
    "failed assignment created a false combat ownership lock")

featureSupported = false
local unsupported = addTarget("unsupported", 7)
selectTarget(unsupported.guid)
local attemptsBeforeUnsupported = #attempts
Markers.EvaluateCurrentTarget()
assert(#attempts == attemptsBeforeUnsupported,
    "unsupported raid-marker APIs were used")

assert(Markers.GetContainer == nil
        and Markers.GetButton == nil
        and Markers.SetRecommendation == nil
        and Markers.GetAssignedGuid == nil
        and Markers.OnCombatLogEvent == nil,
    "removed marker UI or combat-log assignment APIs were exposed")

print("PASS sticky automatic dungeon marking")
