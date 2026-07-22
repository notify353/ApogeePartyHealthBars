ApogeePartyHealthBars_S = { sv = {
    enabled = true, dotRemindersEnabled = true, dotRefreshThreshold = 3,
    dotDisabled = {}, dotPriority = {}, dotThresholds = {},
} }

local definitions = {
    { key = "first", classToken = "WARLOCK", label = "First", castIds = { 10, 11 },
        auraIds = { 20, 21 }, auraIdSet = { [20]=true, [21]=true }, defaultPriority = 1 },
    { key = "curseA", classToken = "WARLOCK", label = "Curse A", castIds = { 30 },
        auraIds = { 31 }, auraIdSet = { [31]=true }, defaultPriority = 2, exclusiveGroup = "curse" },
    { key = "curseB", classToken = "WARLOCK", label = "Curse B", castIds = { 40 },
        auraIds = { 41 }, auraIdSet = { [41]=true }, defaultPriority = 3, exclusiveGroup = "curse" },
}
ApogeePartyHealthBars_DotData = {
    ForClass = function() return definitions end,
    Get = function(key) for _, value in ipairs(definitions) do if value.key == key then return value end end end,
}
ApogeePartyHealthBars_PlayerContext = { GetSnapshot = function()
    return { classToken = "WARLOCK", raceToken = "Orc", level = 70, form = 0, stealthed = false }
end }
ApogeePartyHealthBars_PlayerSpells = { IsKnownSpell = function(id) return id ~= 10 end }
local auraSnapshot = { playerBySpellId = {} }
local invalidations = 0
ApogeePartyHealthBars_Auras = {
    GetUnitHarmfulAuraSnapshot = function() return auraSnapshot end,
    InvalidateUnitAuraCache = function() invalidations = invalidations + 1 end,
}
local realCooldown = {}
ApogeePartyHealthBars_ActionCooldowns = {
    IsRealCooldownActive = function(id) return realCooldown[id] == true end,
}
local shown = {}
ApogeePartyHealthBars_DotHud = {
    Initialize = function() end,
    SetSuggestions = function(value) shown = value end,
}
ApogeePartyHealthBars_ClientCapabilities = { IsFeatureAvailable = function() return true end }

local now, timers = 100, {}
function GetTime() return now end
function UnitExists(unit) return unit == "target" end
function UnitCanAttack() return true end
function UnitIsDeadOrGhost() return false end
function UnitIsPlayer() return false end
C_Spell = {
    GetSpellTexture = function(id) return id + 1000 end,
    IsSpellUsable = function() return true, false end,
    IsSpellInRange = function() return true end,
}
C_Timer = { After = function(delay, callback) timers[#timers + 1] = { delay, callback } end }

dofile("ApogeePartyHealthBars_DotTracker.lua")
local T = ApogeePartyHealthBars_DotTracker
T.Initialize()
assert(#shown == 2 and shown[1].spellId == 11 and shown[2].key == "curseA",
    "missing DoTs did not resolve highest ranks or collapse exclusive families")

auraSnapshot.playerBySpellId[21] = { spellId = 21, duration = 18, expirationTime = 112 }
T.Refresh(false)
assert(#shown == 1 and shown[1].key == "curseA" and #timers > 0 and timers[#timers][1] == 9,
    "healthy aura did not defer until its threshold crossing")
now = 109
timers[#timers][2]()
assert(#shown == 2 and shown[1].key == "first" and shown[1].aura.spellId == 21,
    "threshold wake-up did not expose the expiring aura")

realCooldown[11] = true
T.Refresh(false)
assert(shown[1].key == "curseA" and #shown == 1,
    "real cooldown did not hide an otherwise due suggestion")
realCooldown[11] = nil
T.SetEnabled("curseA", false)
assert(#shown == 2 and shown[2].key == "curseB",
    "disabled exclusive priority did not fall through to the next usable member")
T.AdjustThreshold("first", 1)
assert(T.GetThreshold("first") == 4 and T.HasThresholdOverride("first"),
    "per-spell threshold override did not persist")
T.ResetThreshold("first")
assert(T.GetThreshold("first") == 3 and not T.HasThresholdOverride("first"),
    "threshold reset did not restore inheritance")
T.Refresh(true)
assert(invalidations > 0, "explicit refresh did not invalidate the target aura cache")

print("PASS context-aware DoT tracker")

