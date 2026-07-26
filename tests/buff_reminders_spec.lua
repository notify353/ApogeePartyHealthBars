ApogeePartyHealthBars_C = {
    MAX_ROWS = 2,
    PARTY_BUFF_ICON_TEXTURE = "party-fallback",
    PARTY_BUFF_TRACKS = { "primary", "spirit" },
    SELF_BUFF_ICON_TEXTURE = "self-fallback",
    PARTY_BUFF_DEFINITIONS = {
        { canonical = "Fortitude", track = "primary" },
        {
            canonical = "Divine Spirit",
            track = "spirit",
            eligibleClasses = { PRIEST = true, MAGE = true, DRUID = true },
        },
    },
    SELF_BUFF_FAMILIES = {},
    SELF_BUFF_SPELL_DEFINITIONS = {
        {
            canonical = "Inner Fire",
            icon = "self-icon",
            auraIds = { [200] = true },
            auraNames = { ["Inner Fire"] = true },
        },
    },
}

local Effects = {
    ResolveFirstKnown = function(definitions)
        local spirit = definitions[1] and definitions[1].canonical == "Divine Spirit"
        return {
            known = true,
            spellName = spirit and "Divine Spirit" or "Power Word: Fortitude",
            icon = spirit and "spirit-icon" or "party-icon",
            auraIds = spirit and { [300] = true } or { [100] = true },
            auraNames = spirit and { ["Divine Spirit"] = true }
                or { ["Power Word: Fortitude"] = true },
            definition = definitions[1],
        }
    end,
    ForEachDefinition = function(definitions, callback)
        for _, definition in ipairs(definitions or {}) do
            callback(definition, true, definition.canonical)
        end
    end,
}

local snapshots = {
    player = { auras = {} },
    party1 = { auras = {} },
    enemy = { auras = {} },
}
local configuredMatchers
local Auras = {
    ConfigureBuffMatchers = function(matchers, selfIds, selfNames)
        configuredMatchers = {
            matchers = matchers,
            selfIds = selfIds,
            selfNames = selfNames,
        }
    end,
    GetUnitAuraSnapshot = function(unitId)
        return snapshots[unitId] or { auras = {} }
    end,
    SnapshotHasAura = function(snapshot, auraIds, auraNames)
        for _, aura in ipairs(snapshot.auras or {}) do
            if auraIds and auraIds[aura.spellId] then return true end
            if auraNames and auraNames[aura.name] then return true end
        end
        return false
    end,
}

local existing = { player = true, party1 = true, enemy = true }
local connected = { player = true, party1 = true, enemy = true }
local dead = {}
local assist = { player = true, party1 = true, enemy = false }
local enemy = { player = false, party1 = false, enemy = true }
local factions = { player = "Alliance", party1 = "Horde", enemy = "Horde" }
local classes = { player = "PRIEST", party1 = "MAGE", enemy = "WARRIOR" }
local featureEnabled = { partyBuffEnabled = true, selfBuffEnabled = true }
local configMode = false
local inCombat = false

function UnitClass(unitId)
    local classToken = classes[unitId or "player"] or "PRIEST"
    return classToken, classToken
end
function UnitExists(unitId) return existing[unitId] == true end
function UnitIsDeadOrGhost(unitId) return dead[unitId] == true end
function UnitIsConnected(unitId) return connected[unitId] == true end
function UnitCanAssist(_, unitId) return assist[unitId] == true end
function UnitIsEnemy(_, unitId) return enemy[unitId] == true end
function UnitIsPlayer(unitId) return existing[unitId] == true end
function UnitFactionGroup(unitId) return factions[unitId] end
function InCombatLockdown() return inCombat end

local function Icon()
    local icon = {}
    function icon:SetTexture(texture) self.texture = texture end
    return icon
end

local surfaces = {
    { partyBuffIcons = { Icon(), Icon() } }, { partyBuffIcons = { Icon(), Icon() } },
    { partyBuffIcons = { Icon(), Icon() } }, { partyBuffIcons = { Icon(), Icon() } },
}
local selfBuffTexture
local characterSaved = { selfBuffSelections = {} }
local secureRefreshes, layoutRequests = 0, 0

dofile("ApogeePartyHealthBars_UnitAPI.lua")
dofile("ApogeePartyHealthBars_BuffReminders.lua")
local reminders = ApogeePartyHealthBars_BuffReminders

local valid, validationError = pcall(reminders.Initialize, {})
assert(not valid and tostring(validationError):find("Auras", 1, true),
    "BuffReminders accepted incomplete dependencies")

reminders.Initialize({
    Auras = Auras,
    Effects = Effects,
    GetSurfaces = function() return surfaces end,
    IsSavedFeatureEnabled = function(key) return featureEnabled[key] ~= false end,
    IsConfigMode = function() return configMode end,
    GetCharacterSavedVariables = function() return characterSaved end,
    ApplyAllSelfBuffBindings = function() secureRefreshes = secureRefreshes + 1 end,
    RequestLayoutUpdate = function() layoutRequests = layoutRequests + 1 end,
    SetSelfBuffIconTexture = function(texture) selfBuffTexture = texture end,
})
reminders.RefreshKnownSpells()

assert(reminders.IsPartyKnown() and reminders.IsSelfKnown() and reminders.HasKnownReminder(),
    "known reminder state was not resolved")
assert(reminders.GetPartyCastSpellName(1) == "Power Word: Fortitude"
        and reminders.GetPartyCastSpellName(2) == "Divine Spirit"
        and reminders.GetSelfCastSpellName() == "Inner Fire",
    "secure cast names changed")
for _, surface in ipairs(surfaces) do
    assert(surface.partyBuffIcons[1].texture == "party-icon"
            and surface.partyBuffIcons[2].texture == "spirit-icon",
        "resolved party reminder textures were not propagated")
end
assert(selfBuffTexture == "self-icon", "resolved self reminder texture was not delegated")
assert(configuredMatchers.matchers[1].auraIds[100]
        and configuredMatchers.matchers[1].auraNames["Power Word: Fortitude"]
        and configuredMatchers.matchers[2].auraIds[300]
        and configuredMatchers.matchers[2].auraNames["Divine Spirit"]
        and configuredMatchers.selfIds[200] and configuredMatchers.selfNames["Inner Fire"],
    "resolved aura matchers were not forwarded")

assert(reminders.ShouldShowPartyIcon("party1", 1)
        and reminders.ShouldShowPartyIcon("party1", 2),
    "missing party buff did not show its reminder")
snapshots.party1.auras = { { spellId = 100, name = "Power Word: Fortitude" } }
assert(not reminders.ShouldShowPartyIcon("party1", 1)
        and reminders.ShouldShowPartyIcon("party1", 2),
    "party reminders did not track Fortitude and Spirit independently")
snapshots.party1.auras[2] = { spellId = 300, name = "Divine Spirit" }
assert(not reminders.ShouldShowPartyIcon("party1", 2),
    "active Divine Spirit left its reminder visible")
assert(not reminders.ShouldShowPartyIcon("enemy", 2),
    "Divine Spirit reminder appeared for an ineligible class")

assert(reminders.ShouldShowSelfIcon("player"),
    "missing self buff did not show its reminder")
snapshots.player.auras = { { spellId = 200, name = "Inner Fire" } }
assert(not reminders.ShouldShowSelfIcon("player"),
    "active self buff left its reminder visible")
assert(not reminders.ShouldShowSelfIcon("party1"),
    "self-buff reminder appeared on a party row")

inCombat = true
snapshots.party1.auras = {}
snapshots.player.auras = {}
assert(reminders.ShouldShowPartyIcon("party1", 1) == nil
        and reminders.ShouldShowPartyIcon("party1", 2) == nil
        and reminders.ShouldShowSelfIcon("player") == nil,
    "combat did not freeze buff reminder visibility")
inCombat = false
configMode = true
assert(not reminders.ShouldShowPartyIcon("party1", 1)
        and not reminders.ShouldShowPartyIcon("party1", 2)
        and not reminders.ShouldShowSelfIcon("player"),
    "buff reminders remained visible in configuration mode")
configMode = false

featureEnabled.partyBuffEnabled = false
featureEnabled.selfBuffEnabled = false
assert(not reminders.ShouldShowPartyIcon("party1", 1)
        and not reminders.ShouldShowPartyIcon("party1", 2)
        and not reminders.ShouldShowSelfIcon("player"),
    "disabled reminders remained visible")
featureEnabled.partyBuffEnabled = true
featureEnabled.selfBuffEnabled = true

assert(reminders.CanHealUnit("party1"), "healable party member was rejected")
connected.party1 = false
assert(not reminders.CanHealUnit("party1"), "offline party member remained healable")
connected.party1 = true
dead.party1 = true
assert(not reminders.CanHealUnit("party1"), "dead party member remained healable")
dead.party1 = nil
assert(not reminders.CanHealUnit("enemy"), "enemy unit became healable")
assert(reminders.IsOppositeFactionPlayer("party1"),
    "opposite-faction player was not recognized")
factions.party1 = "Alliance"
assert(not reminders.IsOppositeFactionPlayer("party1"),
    "same-faction player was marked opposite")

assert(not reminders.SetSelfPreference("missing"),
    "non-family self buff accepted a preference")
assert(secureRefreshes == 0 and layoutRequests == 0,
    "rejected preference mutated secure or layout state")

print("PASS buff reminders")
