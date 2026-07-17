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

ApogeePartyHealthBars_Auras = {
    GetUnitAuraSnapshot = function()
        local hasSelfBuff = false
        for name in pairs(activeAuraNames) do
            if ApogeePartyHealthBars_S.selfBuffAuraNames
                and ApogeePartyHealthBars_S.selfBuffAuraNames[name] then
                hasSelfBuff = true
                break
            end
        end
        return { auras = {}, selfBuff = hasSelfBuff }
    end,
    SnapshotHasAura = snapshotHasAura,
}
ApogeePartyHealthBars_ShortcutBar = {
    GetHeight = function() return 0 end,
    IsActive = function() return false end,
}
ApogeePartyHealthBars_Threat = {}

local function widget()
    return setmetatable({}, { __index = function() return function() end end })
end

dofile("ApogeePartyHealthBars_EffectsTracker.lua")
local tracker = ApogeePartyHealthBars_EffectsTracker
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
    rows = rows,
    SyncVisualTicker = function() end,
    IsSavedFeatureEnabled = function() return true end,
    GetUnitTargetToken = function() return "target" end,
    ApplyAllPartyBuffBindings = function() end,
    ApplyAllSelfBuffBindings = function() secureRefreshes = secureRefreshes + 1 end,
    RefreshConfigPanel = function() end,
    SyncCastOverlays = function() end,
    LayoutRows = function() end,
    UpdateRowValues = function() end,
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

tracker.InitPlayerSpells()
local options = tracker.GetSelfBuffPreferenceOptions()
assert(ApogeePartyHealthBars_S.selfBuffFamilyKey == "mageArmor")
assert(#options == 3 and options[1].key == "any")
assert(ApogeePartyHealthBars_S.selfBuffCastSpellName == "Mage Armor")
assert(tracker.GetSelfBuffPreferenceKey() == "any")

activeAuraNames = { ["Frost Armor"] = true }
assert(not tracker.ShouldShowSelfBuffIcon("player"), "Any Mage armor rejected an active family aura")

assert(tracker.SetSelfBuffPreference("Mage Armor"))
assert(characterSaved.selfBuffSelections.mageArmor == "Mage Armor")
assert(tracker.GetSelfBuffPreferenceKey() == "Mage Armor")
assert(ApogeePartyHealthBars_S.selfBuffCastSpellName == "Mage Armor")
assert(tracker.ShouldShowSelfBuffIcon("player"), "specific Mage armor accepted the wrong active armor")
assert(secureRefreshes == 1, "preference change did not refresh secure self-buff casting")

activeAuraNames = { ["Mage Armor"] = true }
assert(not tracker.ShouldShowSelfBuffIcon("player"), "selected Mage armor was not recognized")

currentClass = "PALADIN"
spellbook = { "Devotion Aura", "Retribution Aura" }
activeAuraNames = { ["Retribution Aura"] = true }
tracker.InitPlayerSpells()
assert(ApogeePartyHealthBars_S.selfBuffFamilyKey == "paladinAura")
assert(tracker.GetSelfBuffPreferenceKey() == "any")
assert(not tracker.ShouldShowSelfBuffIcon("player"), "Any Paladin aura rejected an active aura")

currentClass = "PRIEST"
spellbook = { "Inner Fire" }
activeAuraNames = { ["Inner Fire"] = true }
tracker.InitPlayerSpells()
assert(ApogeePartyHealthBars_S.selfBuffFamilyKey == nil, "simple Priest buff became a family")
assert(#tracker.GetSelfBuffPreferenceOptions() == 0)
assert(not tracker.ShouldShowSelfBuffIcon("player"), "Inner Fire fallback stopped working")

print("PASS self-buff families")
