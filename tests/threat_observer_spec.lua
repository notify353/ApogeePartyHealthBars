ApogeePartyHealthBars_C = { SLOT_UNITS = { "player", "party1", "party2", "party3", "party4" } }

local now = 10
local tokens = {
    player = { guid = "P", name = "Tank" },
    party1 = { guid = "G1", name = "Healer" },
    party2 = { guid = "G2", name = "Damage" },
    target = { guid = "A", name = "Guarded Brute", hostile = true, target = "player" },
    party1target = { guid = "A", name = "Guarded Brute", hostile = true, target = "player" },
    party2target = { guid = "B", name = "Restless Hound", hostile = true, target = "player" },
    nameplate1 = { guid = "B", name = "Restless Hound", hostile = true, target = "player" },
    nameplate2 = { guid = "C", name = "Loose Marauder", hostile = true, target = "party1", marker = 8 },
    nameplate3 = { guid = "D", name = "Pack Enforcer", hostile = true, target = "player" },
}
tokens.target.cast = { name = "Fireball", startTime = 9, endTime = 12,
    notInterruptible = false, isChannel = false }
for _, entry in pairs(tokens) do
    entry.health = entry.hostile and 75 or 100
    entry.healthMaximum = 100
end
tokens.targettarget = tokens.player
tokens.party1targettarget = tokens.player
tokens.party2targettarget = tokens.player
tokens.nameplate1target = tokens.player
tokens.nameplate2target = tokens.party1
tokens.nameplate3target = tokens.player

local threat = {
    A = { player = { true, 3, 100 }, party1 = { false, 1, 60 } },
    B = { player = { true, 3, 100 }, party2 = { false, 1, 85 } },
    C = { player = { false, 1, 50 }, party1 = { true, 3, 100 } },
    D = { player = { true, 3, 100 }, party2 = { false, 2, 95 } },
}
local threatQueryCount = 0
local auraScanCount = 0

function UnitExists(unit) return tokens[unit] ~= nil end
function UnitCanAttack(_, unit) return tokens[unit] and tokens[unit].hostile == true end
function UnitIsDeadOrGhost(unit) return tokens[unit] and tokens[unit].dead == true end
function UnitGUID(unit) return tokens[unit] and tokens[unit].guid end
function UnitName(unit)
    local entry = tokens[unit]
    return entry and entry.name
end
function UnitIsUnit(left, right)
    local leftEntry = tokens[left]
    return leftEntry and tokens[right] and leftEntry.guid == tokens[right].guid
end
function GetRaidTargetIndex(unit) return tokens[unit] and tokens[unit].marker end
function UnitDetailedThreatSituation(unit, mob)
    threatQueryCount = threatQueryCount + 1
    local guid = UnitGUID(mob)
    local detail = guid and threat[guid] and threat[guid][unit]
    if not detail then return nil end
    return detail[1], detail[2], detail[3], detail[3], detail[3] * 100
end

dofile("PartyFrames/ThreatObserver.lua")
local observer = ApogeePartyHealthBars_ThreatObserver
local playerDebuffs = {
    target = {
        { name = "Later fallback", icon = 900, spellId = 900, applications = 1 },
        { name = "Sunder Armor", icon = 132363, spellId = 7386, applications = 3 },
        { name = "Earlier fallback", icon = 800, spellId = 800, applications = 1 },
    },
    nameplate1 = {
        { name = "Sunder Armor", icon = 132363, spellId = 25225, applications = 5 },
        { name = "Fallback", icon = 900, spellId = 900, applications = 1 },
    },
    nameplate3 = {
        { name = "High fallback", icon = 900, spellId = 900, applications = 1 },
        { name = "Low fallback", icon = 700, spellId = 700, applications = 1 },
        { name = "Middle fallback", icon = 800, spellId = 800, applications = 1 },
    },
}
observer.Initialize({
    Now = function() return now end,
    GetClassToken = function() return "WARRIOR" end,
    DebuffData = {
        GetThreatDebuffSlotCount = function(classToken)
            return classToken == "WARRIOR" and 4 or 0
        end,
        GetThreatDebuffSlot = function(classToken, spellId)
            if classToken == "WARRIOR" and (spellId == 7386 or spellId == 25225) then
                return 1
            end
        end,
    },
    Auras = { GetUnitHarmfulAuraSnapshot = function(unit)
        auraScanCount = auraScanCount + 1
        return { playerAuras = playerDebuffs[unit] or {} }
    end },
    UnitAPI = { GetHealth = function(unit)
        local entry = tokens[unit]
        return entry and entry.health or 0, entry and entry.healthMaximum or 1, entry ~= nil
    end, GetCast = function(unit) return tokens[unit] and tokens[unit].cast end,
        GetGUID = function(unit) return tokens[unit] and tokens[unit].guid end },
})
observer.OnNamePlateAdded("nameplate1")
observer.OnNamePlateAdded("nameplate2")
observer.OnNamePlateAdded("nameplate3")

local first = observer.Refresh()
assert(first.total == 4 and not first.limitedCoverage
        and first.counts.safe == 1 and first.counts.slipping == 1
        and first.counts.critical == 1 and first.counts.lost == 1
        and first.lostTransitions == nil,
    "observer did not deduplicate and classify the observable pack")
assert(threatQueryCount == 12 and auraScanCount == 4,
    "observer performed duplicate threat or aura work for aliased mobs")
observer.Refresh()
assert(threatQueryCount == 24 and auraScanCount == 4,
    "observer did not reuse stable per-mob debuff layouts")
observer.InvalidateAuras("target")
observer.Refresh()
assert(threatQueryCount == 36 and auraScanCount == 5,
    "observer did not invalidate only the changed mob's debuff layout")
assert(first.enemies[1].guid == "C" and first.enemies[1].victim == "Healer"
        and first.enemies[1].raidMarker == 8,
    "observer did not rank or describe the worst enemy")
local firstByGuid = {}
for _, enemy in ipairs(first.enemies) do firstByGuid[enemy.guid] = enemy end
assert(firstByGuid.A.control == 40 and firstByGuid.A.severity == "safe"
        and firstByGuid.A.health == 75 and firstByGuid.A.healthMaximum == 100
        and firstByGuid.A.healthValid == true
        and firstByGuid.A.cast and firstByGuid.A.cast.name == "Fireball"
        and #firstByGuid.A.playerDebuffSlots == 6
        and firstByGuid.A.playerDebuffSlots[1].applications == 3
        and firstByGuid.A.playerDebuffSlots[2] == false
        and firstByGuid.A.playerDebuffSlots[5].spellId == 800
        and firstByGuid.A.playerDebuffSlots[6].spellId == 900
        and firstByGuid.A.playerDebuffOverflow == 0
        and firstByGuid.B.control == 15 and firstByGuid.B.severity == "slipping"
        and firstByGuid.B.playerDebuffSlots[1].spellId == 25225
        and firstByGuid.B.playerDebuffSlots[2] == false
        and firstByGuid.C.control == -50 and firstByGuid.C.severity == "lost"
        and firstByGuid.D.control == 5 and firstByGuid.D.severity == "critical"
        and firstByGuid.D.playerDebuffSlots[1] == false
        and firstByGuid.D.playerDebuffSlots[5].spellId == 700
        and firstByGuid.D.playerDebuffSlots[6].spellId == 800
        and firstByGuid.D.playerDebuffOverflow == 1,
    "observer did not calculate threat or stable class debuff columns")
assert(firstByGuid.A.observed == nil and firstByGuid.A.sourcePriority == nil,
    "observer exposed internal source-selection or retired transition state")

first.enemies[1].name = "mutated"
assert(observer.GetSnapshot().enemies[1].name == "Loose Marauder",
    "observer exposed mutable internal snapshot state")

tokens.nameplate2.dead = true
local afterDeath = observer.Refresh()
for _, enemy in ipairs(afterDeath.enemies) do
    assert(enemy.guid ~= "C", "known dead enemy remained as a stale threat loss")
end
tokens.nameplate2.dead = false
observer.Refresh()

threat.A.player = { false, 1, 70 }
threat.A.party1 = { true, 3, 100 }
local lost = observer.Refresh()
local lostA
for _, enemy in ipairs(lost.enemies) do if enemy.guid == "A" then lostA = enemy end end
assert(lostA and lostA.control == -30,
    "lost enemy did not expose the player's recovery deficit")
assert(lost.lostTransitions == nil and observer.Refresh().lostTransitions == nil,
    "observer retained sound-only lost-transition state")

threat.A.player = nil
local missingPlayer = observer.Refresh()
local missingPlayerA
for _, enemy in ipairs(missingPlayer.enemies) do
    if enemy.guid == "A" then missingPlayerA = enemy end
end
assert(missingPlayerA and missingPlayerA.control == -100,
    "missing player threat did not produce the full recovery deficit")

tokens.target, tokens.party1target = nil, nil
now = 11
local stale = observer.Refresh()
local staleA
for _, enemy in ipairs(stale.enemies) do if enemy.guid == "A" then staleA = enemy end end
assert(staleA and staleA.stale and not staleA.live and staleA.control == nil,
    "lost enemy did not remain as a non-live last-seen warning")
assert(staleA.playerDebuffSlots == nil and staleA.playerDebuffOverflow == nil,
    "stale enemy retained obsolete player debuffs")
assert(staleA.health == nil and staleA.healthMaximum == nil and staleA.healthValid == nil,
    "stale enemy retained obsolete health values")
assert(staleA.cast == nil, "stale enemy retained obsolete cast state")
now = 13.1
local expired = observer.Refresh()
for _, enemy in ipairs(expired.enemies) do
    assert(enemy.guid ~= "A", "stale lost enemy did not expire")
end

observer.OnNamePlateRemoved("nameplate1")
observer.OnNamePlateRemoved("nameplate2")
observer.OnNamePlateRemoved("nameplate3")
tokens.nameplate1, tokens.nameplate2, tokens.nameplate3 = nil, nil, nil
tokens.nameplate1target, tokens.nameplate2target, tokens.nameplate3target = nil, nil, nil
now = 15.2
local limited = observer.Refresh()
assert(limited.limitedCoverage and limited.total == 1 and limited.enemies[1].guid == "B",
    "party-target fallback or reduced-coverage state was not preserved")

print("PASS multi-enemy threat observer")
