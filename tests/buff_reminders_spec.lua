ApogeePartyHealthBars_C = {
    MAX_ROWS = 2,
    PARTY_BUFF_ICON_TEXTURE = "party-fallback",
    SELF_BUFF_ICON_TEXTURE = "self-fallback",
    PARTY_BUFF_DEFINITIONS = { { canonical = "Fortitude" } },
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
    ResolveFirstKnown = function()
        return {
            known = true,
            spellName = "Power Word: Fortitude",
            icon = "party-icon",
            auraIds = { [100] = true },
            auraNames = { ["Power Word: Fortitude"] = true },
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
    ConfigureBuffMatchers = function(...)
        configuredMatchers = { ... }
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
local featureEnabled = { partyBuffEnabled = true, selfBuffEnabled = true }
local configMode = false
local inCombat = false

function UnitClass() return "Priest", "PRIEST" end
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
    { partyBuffIcon = Icon() }, { partyBuffIcon = Icon() },
    { partyBuffIcon = Icon() }, { partyBuffIcon = Icon() },
}
local selfBuffTexture
local characterSaved = { selfBuffSelections = {} }
local secureRefreshes, layoutRequests = 0, 0

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
assert(reminders.GetPartyCastSpellName() == "Power Word: Fortitude"
        and reminders.GetSelfCastSpellName() == "Inner Fire",
    "secure cast names changed")
for _, surface in ipairs(surfaces) do
    assert(surface.partyBuffIcon.texture == "party-icon",
        "resolved party reminder texture was not propagated")
end
assert(selfBuffTexture == "self-icon", "resolved self reminder texture was not delegated")
assert(configuredMatchers[1][100] and configuredMatchers[2]["Power Word: Fortitude"]
        and configuredMatchers[3][200] and configuredMatchers[4]["Inner Fire"],
    "resolved aura matchers were not forwarded")

assert(reminders.ShouldShowPartyIcon("party1"),
    "missing party buff did not show its reminder")
snapshots.party1.auras = { { spellId = 100, name = "Power Word: Fortitude" } }
assert(not reminders.ShouldShowPartyIcon("party1"),
    "active party buff left its reminder visible")

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
assert(not reminders.ShouldShowPartyIcon("party1")
        and not reminders.ShouldShowSelfIcon("player"),
    "buff reminders remained visible in combat")
inCombat = false
configMode = true
assert(not reminders.ShouldShowPartyIcon("party1")
        and not reminders.ShouldShowSelfIcon("player"),
    "buff reminders remained visible in configuration mode")
configMode = false

featureEnabled.partyBuffEnabled = false
featureEnabled.selfBuffEnabled = false
assert(not reminders.ShouldShowPartyIcon("party1")
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
