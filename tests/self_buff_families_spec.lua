unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

dofile("ApogeePartyHealthBars_Data.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_Effects.lua")

local currentClass = "MAGE"
local spellbook = { "Mage Armor", "Frost Armor" }
local activeAuraNames = {}

function UnitClass() return currentClass, currentClass end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #spellbook end
function GetSpellBookItemName(slot) return spellbook[slot] end
function UnitExists() return true end
function UnitIsDeadOrGhost() return false end
function UnitIsConnected() return true end
function UnitCanAssist() return true end
function UnitIsEnemy() return false end
function UnitIsPlayer() return true end
function UnitFactionGroup() return "Alliance" end
function InCombatLockdown() return false end
function UnitPowerMax() return 0 end
function UnitPowerType() return 0, "MANA" end
BOOKTYPE_SPELL = "spell"

local function snapshotHasAura(_, _, auraNames)
    for name in pairs(activeAuraNames) do
        if auraNames and auraNames[name] then return true end
    end
    return false
end

local configuredSelfAuraNames
ApogeePartyHealthBars_Auras = {
    GetUnitAuraSnapshot = function() return { auras = {} } end,
    SnapshotHasAura = snapshotHasAura,
    ConfigureBuffMatchers = function(_, _, _, selfNames)
        configuredSelfAuraNames = selfNames
    end,
}

local function widget()
    return setmetatable({}, { __index = function() return function() end end })
end

dofile("ApogeePartyHealthBars_BuffReminders.lua")
local tracker = ApogeePartyHealthBars_BuffReminders
local secureRefreshes = 0
local rows = {}
for i = 1, ApogeePartyHealthBars_C.MAX_ROWS do
    rows[i] = { selfBuffIcon = widget() }
end

ApogeePartyHealthBars_S.RequestLayoutUpdate = function() end
local accountSaved, characterSaved = {}, {}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(accountSaved, characterSaved)
ApogeePartyHealthBars_S.sv = accountSaved
ApogeePartyHealthBars_S.charSv = characterSaved

tracker.Initialize({
    Auras = ApogeePartyHealthBars_Auras,
    Effects = ApogeePartyHealthBars_Effects,
    rows = rows,
    IsSavedFeatureEnabled = function() return true end,
    IsConfigMode = function() return false end,
    GetCharacterSavedVariables = function() return characterSaved end,
    ApplyAllSelfBuffBindings = function() secureRefreshes = secureRefreshes + 1 end,
    RequestLayoutUpdate = function() end,
})

local expectedFamilies = {
    MAGE = "mageArmor",
    PALADIN = "paladinAura",
    HUNTER = "hunterAspect",
    WARLOCK = "warlockArmor",
    SHAMAN = "shamanShield",
}
local seenFamilies = {}
for _, family in ipairs(ApogeePartyHealthBars_C.SELF_BUFF_FAMILIES) do
    assert(expectedFamilies[family.classToken] == family.key, "unexpected self-buff family")
    assert(type(family.anyLabel) == "string" and family.anyLabel ~= "")
    assert(#family.spells >= 2, family.key .. " does not contain a choice")
    seenFamilies[family.classToken] = true
    local seenSpells = {}
    for _, definition in ipairs(family.spells) do
        assert(not seenSpells[definition.canonical], "duplicate family spell")
        assert(definition.auraNames[definition.canonical], "family spell does not match its aura")
        seenSpells[definition.canonical] = true
    end
end
for classToken in pairs(expectedFamilies) do
    assert(seenFamilies[classToken], classToken .. " family is missing")
end

tracker.RefreshKnownSpells()
local options = tracker.GetSelfPreferenceOptions()
assert(#options == 3 and options[1].key == "any")
assert(tracker.GetSelfCastSpellName() == "Mage Armor")
assert(tracker.GetSelfPreferenceKey() == "any")
assert(configuredSelfAuraNames["Mage Armor"] and configuredSelfAuraNames["Frost Armor"],
    "Any Mage armor did not configure the full family aura set")

activeAuraNames = { ["Frost Armor"] = true }
assert(not tracker.ShouldShowSelfIcon("player"), "Any Mage armor rejected an active family aura")

assert(tracker.SetSelfPreference("Mage Armor"))
assert(characterSaved.selfBuffSelections.mageArmor == "Mage Armor")
assert(tracker.GetSelfPreferenceKey() == "Mage Armor")
assert(tracker.GetSelfCastSpellName() == "Mage Armor")
assert(tracker.ShouldShowSelfIcon("player"), "specific Mage armor accepted the wrong active armor")
assert(secureRefreshes == 1, "preference change did not refresh secure self-buff casting")

activeAuraNames = { ["Mage Armor"] = true }
assert(not tracker.ShouldShowSelfIcon("player"), "selected Mage armor was not recognized")

currentClass = "PALADIN"
spellbook = { "Devotion Aura", "Retribution Aura" }
activeAuraNames = { ["Retribution Aura"] = true }
tracker.RefreshKnownSpells()
assert(tracker.GetSelfPreferenceKey() == "any")
assert(not tracker.ShouldShowSelfIcon("player"), "Any Paladin aura rejected an active aura")

currentClass = "PRIEST"
spellbook = { "Inner Fire" }
activeAuraNames = { ["Inner Fire"] = true }
tracker.RefreshKnownSpells()
assert(tracker.GetSelfPreferenceKey() == nil, "simple Priest buff became a family preference")
assert(#tracker.GetSelfPreferenceOptions() == 0)
assert(not tracker.ShouldShowSelfIcon("player"), "Inner Fire fallback stopped working")

print("PASS self-buff families")
