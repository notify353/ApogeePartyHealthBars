ApogeePartyHealthBars_S = { sv = {
    enabled = true, targetEffectRemindersEnabled = true, targetEffectRefreshThreshold = 3,
    targetEffectDisabled = {}, targetEffectPriority = {},
} }

local definitions = {
    { key = "first", classToken = "WARLOCK", label = "First", castIds = { 10, 11 },
        auraIds = { 20, 21 }, auraIdSet = { [20]=true, [21]=true }, defaultPriority = 1 },
    { key = "curseA", classToken = "WARLOCK", label = "Curse A", castIds = { 30 },
        auraIds = { 31 }, auraIdSet = { [31]=true }, defaultPriority = 2, exclusiveGroup = "curse" },
    { key = "curseB", classToken = "WARLOCK", label = "Curse B", castIds = { 40 },
        auraIds = { 41 }, auraIdSet = { [41]=true }, defaultPriority = 3, exclusiveGroup = "curse" },
    { key = "demo", classToken = "WARLOCK", label = "Demo", castIds = { 50, 51 },
        auraIds = { 60, 61 }, auraIdSet = { [60]=true, [61]=true }, defaultPriority = 4,
        maintainedDebuff = true, ownerPolicy = "any", coverageGroup = "attackPower",
        castStrengths = { [50]=1, [51]=2 }, auraStrengths = { [60]=1, [61]=2 },
        casterCentered = true },
    { key = "equivalentDemo", classToken = "DRUID", label = "Equivalent Demo", castIds = { 70 },
        auraIds = { 71 }, auraIdSet = { [71]=true }, defaultPriority = 5,
        maintainedDebuff = true, ownerPolicy = "any", coverageGroup = "attackPower",
        auraStrengths = { [70]=2, [71]=2 } },
    { key = "judgementLight", classToken = "PALADIN", label = "Judgement Light",
        castIds = { 80 }, auraIds = { 81 }, auraIdSet = { [81]=true },
        defaultPriority = 6, maintainedDebuff = true, ownerPolicy = "any",
        actionSpellId = 90, exclusiveGroup = "judgement",
        requiredPlayerAuraIdSet = { [80]=true },
        castStrengths = { [80]=1 }, auraStrengths = { [81]=1 } },
    { key = "judgementWisdom", classToken = "PALADIN", label = "Judgement Wisdom",
        castIds = { 82 }, auraIds = { 83 }, auraIdSet = { [83]=true },
        defaultPriority = 7, maintainedDebuff = true, ownerPolicy = "any",
        actionSpellId = 90, exclusiveGroup = "judgement",
        requiredPlayerAuraIdSet = { [82]=true },
        castStrengths = { [82]=1 }, auraStrengths = { [83]=1 } },
    { key = "battleShout", classToken = "WARRIOR", label = "Battle Shout",
        castIds = { 100 }, auraIds = { 101 }, auraIdSet = { [101]=true },
        defaultPriority = 8, maintainedDebuff = true, ownerPolicy = "any",
        auraUnit = "player", casterCentered = true,
        castStrengths = { [100]=1 }, auraStrengths = { [101]=1 } },
}
ApogeePartyHealthBars_TargetEffectData = {
    ForClass = function(classToken)
        local result = {}
        for _, value in ipairs(definitions) do
            if value.classToken == classToken then result[#result + 1] = value end
        end
        return result
    end,
    Get = function(key) for _, value in ipairs(definitions) do if value.key == key then return value end end end,
    GetCoverageGroup = function(key)
        local result = {}
        for _, value in ipairs(definitions) do
            if value.coverageGroup == key then result[#result + 1] = value end
        end
        return result
    end,
}
local currentClass = "WARLOCK"
ApogeePartyHealthBars_PlayerContext = { GetSnapshot = function()
    return { classToken = currentClass, raceToken = "Human", level = 70, form = 0, stealthed = false }
end }
ApogeePartyHealthBars_PlayerSpells = { IsKnownSpell = function(id) return id ~= 10 end }
local auraSnapshot = { playerBySpellId = {}, bySpellId = {} }
local playerAuraSnapshot = { auras = {} }
local invalidations = 0
ApogeePartyHealthBars_Auras = {
    GetUnitHarmfulAuraSnapshot = function() return auraSnapshot end,
    GetUnitAuraSnapshot = function() return playerAuraSnapshot end,
    SnapshotHasAura = function(snapshot, idSet)
        for _, aura in ipairs(snapshot.auras) do
            if idSet[aura.spellId] then return true end
        end
        return false
    end,
    InvalidateUnitAuraCache = function() invalidations = invalidations + 1 end,
}
local realCooldown = {}
ApogeePartyHealthBars_ActionCooldowns = {
    IsRealCooldownActive = function(id) return realCooldown[id] == true end,
}
local shown = {}
local configurationPreview = {}
ApogeePartyHealthBars_TargetEffectHud = {
    Initialize = function() end,
    SetSuggestions = function(value) shown = value end,
    SetConfigurationPreview = function(value) configurationPreview = value end,
}
ApogeePartyHealthBars_ClientCapabilities = { IsFeatureAvailable = function() return true end }

local now, timers, spellInRange = 100, {}, true
function GetTime() return now end
local targetExists = true
function UnitExists(unit) return unit == "player" or (unit == "target" and targetExists) end
function UnitCanAttack() return true end
function UnitIsDeadOrGhost() return false end
function UnitIsPlayer() return false end
C_Spell = {
    GetSpellTexture = function(id) return id + 1000 end,
    IsSpellUsable = function() return true, false end,
    IsSpellInRange = function() return spellInRange end,
}
C_Timer = { After = function(delay, callback) timers[#timers + 1] = { delay, callback } end }

dofile("Reminders/TargetEffects/TargetEffectTracker.lua")
local T = ApogeePartyHealthBars_TargetEffectTracker
T.Initialize()
assert(#shown == 3 and shown[1].spellId == 11 and shown[2].key == "curseA"
        and shown[3].key == "demo",
    "missing DoTs did not resolve highest ranks or collapse exclusive families")
assert(#configurationPreview == 3 and configurationPreview[1].key == "first"
        and configurationPreview[2].key == "curseA"
        and configurationPreview[3].key == "curseB"
        and configurationPreview[1].preview,
    "configuration did not receive representative learned-effect examples")

auraSnapshot.playerBySpellId[21] = { spellId = 21, duration = 18, expirationTime = 112 }
T.Refresh(false)
assert(#shown == 2 and shown[1].key == "curseA" and shown[2].key == "demo"
        and #timers > 0 and timers[#timers][1] == 9,
    "healthy aura did not defer until its threshold crossing")
now = 109
timers[#timers][2]()
assert(#shown == 3 and shown[1].key == "first" and shown[1].aura.spellId == 21,
    "threshold wake-up did not expose the expiring aura")

realCooldown[11] = true
T.Refresh(false)
assert(shown[1].key == "curseA" and #shown == 2,
    "real cooldown did not hide an otherwise due suggestion")
realCooldown[11] = nil
spellInRange = nil
T.Refresh(false)
assert(#shown == 1 and shown[1].key == "demo",
    "caster-centered debuff was hidden when target range was not applicable")
definitions[4].casterCentered = nil
T.Refresh(false)
assert(#shown == 0, "invalid target range was accepted for a targeted effect")
definitions[4].casterCentered = true
spellInRange = 1
T.Refresh(false)
assert(#shown == 3,
    "legacy numeric in-range results were rejected")
T.SetEnabled("curseA", false)
assert(#shown == 3 and shown[2].key == "curseB",
    "disabled exclusive priority did not fall through to the next usable member")
for _, item in ipairs(configurationPreview) do
    assert(item.key ~= "curseA", "disabled effect remained in configuration examples")
end
local weaker = { spellId = 60, expirationTime = 130, sourceUnit = "party1" }
auraSnapshot.bySpellId[60] = { weaker }
T.Refresh(false)
assert(shown[#shown].key == "demo",
    "weaker equivalent coverage suppressed the stronger maintained debuff")
local equal = { spellId = 71, expirationTime = 130, sourceUnit = "party1" }
auraSnapshot.bySpellId[71] = { equal }
T.Refresh(false)
for _, suggestion in ipairs(shown) do
    assert(suggestion.key ~= "demo", "equal equivalent coverage left a maintained-debuff reminder")
end
currentClass = "PALADIN"
playerAuraSnapshot.auras = { { spellId = 82 } }
T.OnContextChanged()
assert(#shown == 1 and shown[1].key == "judgementWisdom" and shown[1].spellId == 90,
    "Judgement reminder did not follow the player's active seal")
playerAuraSnapshot.auras = { { spellId = 80 } }
T.Refresh(false)
assert(#shown == 1 and shown[1].key == "judgementLight",
    "player aura refresh did not switch the active Judgement family")
currentClass = "WARLOCK"
T.OnContextChanged()
currentClass = "WARRIOR"
targetExists = false
playerAuraSnapshot.auras = {}
T.OnContextChanged()
assert(#shown == 1 and shown[1].key == "battleShout",
    "missing Battle Shout did not remind without a hostile target")
playerAuraSnapshot.auras = { { spellId = 101, expirationTime = 300 } }
T.Refresh(false)
assert(#shown == 0, "active Battle Shout left its self-aura reminder visible")
currentClass = "WARLOCK"
targetExists = true
playerAuraSnapshot.auras = {}
T.OnContextChanged()
auraSnapshot.playerBySpellId[21] = { spellId = 21, duration = 18, expirationTime = 114 }
auraSnapshot.playerBySpellId[41] = { spellId = 41, duration = 18, expirationTime = 114 }
T.Refresh(false)
assert(#shown == 0, "effects outside the shared reminder threshold were shown")
T.AdjustThreshold(1)
assert(ApogeePartyHealthBars_S.sv.targetEffectRefreshThreshold == 4,
    "shared reminder threshold did not persist")
assert(#shown == 0, "shared reminder threshold changed an effect too early")
T.AdjustThreshold(1)
assert(#shown == 2 and shown[1].key == "first" and shown[2].key == "curseB"
        and shown[1].threshold == 5 and shown[2].threshold == 5,
    "shared reminder threshold did not apply to every enabled effect")
assert(T.GetThreshold == nil and T.HasThresholdOverride == nil
        and T.ResetThreshold == nil and T.AdjustDefaultThreshold == nil,
    "removed individual reminder timing APIs were still exposed")
T.Refresh(true)
assert(invalidations > 0, "explicit refresh did not invalidate the target aura cache")

print("PASS context-aware DoT tracker")
