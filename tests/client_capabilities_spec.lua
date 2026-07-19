local function noop() end

CreateFrame = noop
UnitExists = function() return true end
UnitHealth = function() return 1 end
UnitHealthMax = function() return 1 end
InCombatLockdown = function() return false end

GetBuildInfo = function() return "2.5.6", "68775", "Jul 17 2026", 20506 end
WOW_PROJECT_ID = 14
GetAddOnMetadata = function(name, field)
    assert(name == "ApogeePartyHealthBars" and field == "Version")
    return "legacy-version"
end

dofile("ApogeePartyHealthBars_ClientCapabilities.lua")
local capabilities = ApogeePartyHealthBars_ClientCapabilities

assert(capabilities.Has("core"), "required core capability was not detected")
assert(capabilities.GetAddonVersion("ApogeePartyHealthBars") == "legacy-version",
    "legacy addon metadata fallback failed")
local info = capabilities.GetClientInfo()
assert(info.projectId == 14 and info.interface == 20506 and info.build == "68775",
    "client identity was not normalized")

C_AddOns = { GetAddOnMetadata = function() return "modern-version" end }
assert(capabilities.GetAddonVersion("ApogeePartyHealthBars") == "modern-version",
    "modern addon metadata was not preferred")
C_AddOns.GetAddOnMetadata = function() error("expected metadata failure") end
assert(capabilities.GetAddonVersion("ApogeePartyHealthBars") == "legacy-version",
    "failed modern addon metadata did not fall back safely")
C_AddOns, GetAddOnMetadata = nil, nil
assert(capabilities.GetAddonVersion("ApogeePartyHealthBars") == "unknown",
    "missing addon metadata did not fail closed")

assert(not capabilities.IsFeatureAvailable("auraReminders")
        and capabilities.GetFeatureReason("auraReminders"):find("aura", 1, true),
    "missing aura API was not reported")
UnitBuff = function() return nil end
assert(capabilities.IsFeatureAvailable("auraReminders"),
    "legacy aura support was not detected")

assert(not capabilities.IsFeatureAvailable("boundActions"),
    "incomplete binding API was accepted")
GetCurrentBindingSet = function() return 1 end
GetBindingAction = function() return "" end
SetBinding = function() return true end
SaveBindings = noop
assert(not capabilities.IsFeatureAvailable("boundActions"),
    "binding support without binding-set restoration was accepted")
LoadBindings = noop
assert(capabilities.IsFeatureAvailable("boundActions"),
    "complete binding API was not detected")

assert(not capabilities.IsFeatureAvailable("formLayouts"),
    "missing form APIs were accepted")
GetNumShapeshiftForms = function() return 0 end
GetShapeshiftFormInfo = noop
GetShapeshiftForm = function() return 0 end
assert(capabilities.IsFeatureAvailable("formLayouts"),
    "form API family was not detected")

assert(not capabilities.IsFeatureAvailable("profileSharing"),
    "missing profile codec APIs were accepted")
C_EncodingUtil = {
    SerializeCBOR = noop, DeserializeCBOR = noop,
    CompressString = noop, DecompressString = noop,
    EncodeBase64 = noop, DecodeBase64 = noop,
}
Enum = { CompressionMethod = {}, Base64Variant = {} }
assert(not capabilities.IsFeatureAvailable("profileSharing"),
    "profile sharing accepted missing compression or Base64 enum members")
Enum.CompressionMethod.Deflate = 1
Enum.Base64Variant.StandardUrlSafe = 2
assert(capabilities.IsFeatureAvailable("profileSharing"),
    "profile codec API family was not detected")

capabilities.RecordRuntimeFailure("Wheel", "expected failure")
local failures = capabilities.ListRuntimeFailures()
assert(#failures == 1 and failures[1].owner == "Wheel"
        and failures[1].reason == "expected failure",
    "runtime failure diagnostics were not retained")

local unavailable = capabilities.ListUnavailableFeatures()
for index = 2, #unavailable do
    assert(unavailable[index - 1].label <= unavailable[index].label,
        "unavailable features were not returned in stable order")
end

ApogeePartyHealthBars_C = {}
ApogeePartyHealthBars_S = {}
C_UnitAuras, UnitBuff = nil, nil
dofile("ApogeePartyHealthBars_Auras.lua")
local auraSnapshot = ApogeePartyHealthBars_Auras.ScanUnitHelpfulAuras("player")
assert(#auraSnapshot.auras == 0 and not auraSnapshot.partyBuff
        and not auraSnapshot.selfBuff and auraSnapshot.pwShield == nil,
    "missing aura APIs did not return a normalized empty snapshot")

C_SpellBook, GetSpellBookItemInfo, GetSpellBookItemName = nil, nil, nil
dofile("ApogeePartyHealthBars_PlayerSpells.lua")
local spellId, spellName = ApogeePartyHealthBars_PlayerSpells.GetSpellFromCursor(1, nil, nil)
local byId, byName, known = ApogeePartyHealthBars_PlayerSpells.BuildKnownSpellMap()
assert(spellId == nil and spellName == nil and next(byId) == nil
        and next(byName) == nil and #known == 0,
    "missing Spellbook APIs did not return normalized empty results")

C_SpellBook = {
    GetSpellBookItemType = function(slot, bank)
        assert(slot == 1 and bank == 0, "modern Spellbook lookup used unexpected arguments")
        return "SPELL", 9001, 9001
    end,
    IsSpellKnown = function(id) return id == 9001 end,
}
GetSpellInfo = function(id) return id == 9001 and "Modern Spell" or nil end
local modernOk, modernId, modernName = pcall(
    ApogeePartyHealthBars_PlayerSpells.GetSpellFromCursor, 1, nil, nil)
assert(modernOk and modernId == 9001 and modernName == "Modern Spell",
    "modern Spellbook type lookup fell through to missing legacy globals")
assert(ApogeePartyHealthBars_PlayerSpells.IsKnownSpell(9001, "Modern Spell"),
    "modern known-spell lookup did not preserve a configured action")

print("PASS client capability contract")
