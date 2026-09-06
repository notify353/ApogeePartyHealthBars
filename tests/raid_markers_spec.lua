ApogeePartyHealthBars_S = { sv = { enabled = true } }

local featureSupported = true
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(key)
        return key == "raidMarkers" and featureSupported
    end,
}

local enabled = false
local inCombat = false
local now = 0
local applyAllowed = true
local attempts = {}
local recommendations = {}
local targets = {}
local current

local function addTarget(guid, markerIndex, autoMarkRank, guideKey, stagingContextKey)
    local entry = {
        guid = guid, marker = nil, exists = true, hostile = true, dead = false,
    }
    targets[guid] = entry
    recommendations[guid] = markerIndex and {
        markerIndex = markerIndex,
        autoMarkRank = autoMarkRank or 100,
        guideKey = guideKey or "guide-a",
        stagingContextKey = stagingContextKey
            or ((guideKey or "guide-a") .. "/trash"),
    } or nil
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
    Now = function() return now end,
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
local skullWeak = addTarget("skull-weak", 8, 30)
local skullStrong = addTarget("skull-strong", 8, 10)
local skullWeaker = addTarget("skull-weaker", 8, 40)
local skullEqual = addTarget("skull-equal", 8, 10)
selectTarget(skullWeak.guid)
assert(Markers.EvaluateCurrentTarget() == recommendations[skullWeak.guid]
        and skullWeak.marker == 8, "first out-of-combat Skull was not staged")
selectTarget(skullStrong.guid)
assert(Markers.EvaluateCurrentTarget() == recommendations[skullStrong.guid]
        and skullWeak.marker == nil and skullStrong.marker == 8,
    "stronger out-of-combat Skull did not replace a weaker staged owner")
selectTarget(skullWeaker.guid)
assert(Markers.EvaluateCurrentTarget() == nil and skullStrong.marker == 8
        and skullWeaker.marker == nil,
    "weaker out-of-combat Skull replaced the stronger staged owner")
selectTarget(skullEqual.guid)
assert(Markers.EvaluateCurrentTarget() == nil and skullStrong.marker == 8
        and skullEqual.marker == nil,
    "equal-ranked out-of-combat Skull did not preserve the first owner")

local crossA = addTarget("cross-a", 7)
local circleA = addTarget("circle-a", 2)
selectTarget(crossA.guid); Markers.EvaluateCurrentTarget()
selectTarget(circleA.guid); Markers.EvaluateCurrentTarget()
assert(crossA.marker == 7 and circleA.marker == 2
        and skullStrong.marker == 8,
    "pre-pull Skull, Cross, and Circle were not staged together")

local alreadyMarked = addTarget("already-marked", 8)
alreadyMarked.marker = 1
selectTarget(alreadyMarked.guid)
local attemptsBeforeExisting = #attempts
Markers.EvaluateCurrentTarget()
assert(#attempts == attemptsBeforeExisting and alreadyMarked.marker == 1,
    "an existing target marker was replaced or cleared")

now = 100
inCombat = true
selectTarget(circleA.guid)
Markers.OnCombatStarted()
local skullC = addTarget("skull-c", 8, 1, "guide-a", "guide-a/other-encounter")
local crossB = addTarget("cross-b", 7)
local circleB = addTarget("circle-b", 2)
for _, entry in ipairs({ skullC, crossB, circleB }) do
    selectTarget(entry.guid)
    assert(Markers.EvaluateCurrentTarget() == nil and entry.marker == nil,
        "combat moved an icon away from its living owner")
end

Markers.Initialize(deps)
inCombat = false
local oldGuideSkull = addTarget("old-guide-skull", 8, 10, "guide-a")
local otherGuideSkull = addTarget("other-guide-skull", 8, 30, "guide-b")
selectTarget(oldGuideSkull.guid)
assert(Markers.EvaluateCurrentTarget() and oldGuideSkull.marker == 8,
    "initial guide did not establish staging context")
selectTarget(otherGuideSkull.guid)
assert(Markers.EvaluateCurrentTarget() and oldGuideSkull.marker == nil
        and otherGuideSkull.marker == 8,
    "Dungeon Guide context change did not reset pre-pull staging")

local noGuideTarget = addTarget("no-guide-target", nil)
local sameGuideWeaker = addTarget("same-guide-weaker", 8, 40, "guide-b")
selectTarget(noGuideTarget.guid)
assert(Markers.EvaluateCurrentTarget() == nil, "unknown target changed staging")
selectTarget(sameGuideWeaker.guid)
assert(Markers.EvaluateCurrentTarget() == nil and otherGuideSkull.marker == 8
        and sameGuideWeaker.marker == nil,
    "out-of-combat staging reset before its inactivity timeout")

Markers.Initialize(deps)
now = 0
local encounterSkull = addTarget("encounter-skull", 8, 30,
    "guide-a", "guide-a/encounter-one")
local encounterCircle = addTarget("encounter-circle", 2, 100,
    "guide-a", "guide-a/encounter-one")
local encounterWeaker = addTarget("encounter-weaker", 8, 40,
    "guide-a", "guide-a/encounter-one")
local encounterNoAuto = addTarget("encounter-no-auto", nil)
recommendations[encounterNoAuto.guid] = {
    markerIndex = nil,
    autoMarkRank = nil,
    guideKey = "guide-a",
    stagingContextKey = "guide-a/encounter-two",
}
selectTarget(encounterSkull.guid); Markers.EvaluateCurrentTarget()
selectTarget(encounterCircle.guid); Markers.EvaluateCurrentTarget()
selectTarget(encounterNoAuto.guid)
assert(Markers.EvaluateCurrentTarget() == nil and encounterSkull.marker == 8
        and encounterCircle.marker == 2,
    "No Auto Mark target changed the active encounter staging context")
selectTarget(encounterWeaker.guid)
assert(Markers.EvaluateCurrentTarget() == nil and encounterSkull.marker == 8
        and encounterCircle.marker == 2 and encounterWeaker.marker == nil,
    "targets in one encounter did not share ranked staging")

local nextEncounterSkull = addTarget("next-encounter-skull", 8, 50,
    "guide-a", "guide-a/encounter-two")
local nextEncounterCircle = addTarget("next-encounter-circle", 2, 200,
    "guide-a", "guide-a/encounter-two")
selectTarget(nextEncounterSkull.guid)
assert(Markers.EvaluateCurrentTarget() and encounterSkull.marker == nil
        and nextEncounterSkull.marker == 8,
    "new encounter context did not discard an unrelated automatic Skull owner")
selectTarget(nextEncounterCircle.guid)
assert(Markers.EvaluateCurrentTarget() and encounterCircle.marker == nil
        and nextEncounterCircle.marker == 2,
    "new encounter context did not discard an unrelated automatic Circle owner")

Markers.Initialize(deps)
now = 0
local timeoutOwner = addTarget("timeout-owner", 8, 10)
local timeoutWeakerA = addTarget("timeout-weaker-a", 8, 30)
local timeoutWeakerB = addTarget("timeout-weaker-b", 8, 40)
local timeoutReplacement = addTarget("timeout-replacement", 8, 50)
selectTarget(timeoutOwner.guid)
assert(Markers.EvaluateCurrentTarget() and timeoutOwner.marker == 8,
    "timeout test did not stage its initial owner")
now = 14
selectTarget(timeoutWeakerA.guid)
assert(Markers.EvaluateCurrentTarget() == nil and timeoutOwner.marker == 8,
    "staging expired before 15 seconds of inactivity")
now = 28
selectTarget(timeoutWeakerB.guid)
assert(Markers.EvaluateCurrentTarget() == nil and timeoutOwner.marker == 8,
    "eligible target cycling did not refresh staging activity")
now = 42
selectTarget(encounterNoAuto.guid)
assert(Markers.EvaluateCurrentTarget() == nil and timeoutOwner.marker == 8,
    "No Auto Mark target changed or refreshed staging ownership")
now = 43
selectTarget(timeoutReplacement.guid)
assert(Markers.EvaluateCurrentTarget() and timeoutOwner.marker == nil
        and timeoutReplacement.marker == 8,
    "staging did not reset after 15 seconds without an eligible guide target")

Markers.Initialize(deps)
local automaticOwner = addTarget("automatic-owner", 8, 30)
local manualOwner = addTarget("manual-owner", 8, 50)
local manualChallenger = addTarget("manual-challenger", 8, 1,
    "guide-a", "guide-a/other-encounter")
selectTarget(automaticOwner.guid)
assert(Markers.EvaluateCurrentTarget() and automaticOwner.marker == 8,
    "automatic pre-pull owner was not staged")
setManualMarker(manualOwner, 8)
selectTarget(manualOwner.guid)
Markers.OnRaidTargetUpdate()
now = now + 16
selectTarget(manualChallenger.guid)
assert(Markers.EvaluateCurrentTarget() == nil and manualOwner.marker == 8
        and manualChallenger.marker == nil,
    "timeout or encounter change replaced an observed manual pre-pull owner")

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
local survivingManual = addTarget("surviving-manual", 8, 100)
local postCombatAutomatic = addTarget("post-combat-automatic", 8, 1)
setManualMarker(survivingManual, 8)
selectTarget(survivingManual.guid)
Markers.OnCombatStarted()
inCombat = false
Markers.OnCombatEnded()
selectTarget(postCombatAutomatic.guid)
assert(Markers.EvaluateCurrentTarget() == nil and survivingManual.marker == 8
        and postCombatAutomatic.marker == nil,
    "combat reset forgot an observed manual marker owner")

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

for _, attempt in ipairs(attempts) do
    assert(attempt[1] == "target",
        "automatic raid marking assigned an icon through a non-target unit token")
end
local markerSource = assert(io.open("PartyFrames/RaidMarkers.lua", "rb"))
local markerBody = markerSource:read("*a")
markerSource:close()
for _, forbidden in ipairs({
    "C_NamePlate", "NAME_PLATE_UNIT_ADDED", "TargetUnit(",
    "TargetNearestEnemy(", "TargetLastTarget(", "GetTime(", "C_Timer",
}) do
    assert(not markerBody:find(forbidden, 1, true),
        "automatic raid marking introduced scanning or target selection: " .. forbidden)
end

assert(Markers.GetContainer == nil
        and Markers.GetButton == nil
        and Markers.SetRecommendation == nil
        and Markers.GetAssignedGuid == nil
        and Markers.OnCombatLogEvent == nil,
    "removed marker UI or combat-log assignment APIs were exposed")

print("PASS sticky automatic dungeon marking")
