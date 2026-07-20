ApogeePartyHealthBars_S = { charSv = {} }
ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key) return type(key) == "string" and key or "none" end,
}
ApogeePartyHealthBars_ShortcutItems = {}

local activeSpec, formCount, activeForm = 1, 0, 0
C_SpecializationInfo = { GetActiveSpecGroup = function() return activeSpec end }
function GetNumShapeshiftForms() return formCount end
function GetShapeshiftForm() return activeForm end
function GetShapeshiftFormInfo(index)
    return "texture" .. index, "Form " .. index, true, index == 1 and 2457 or 71
end
function UnitClass() return "Druid", "DRUID" end
C_Spell = { GetSpellInfo = function(id) return { name = id == 2457 and "Battle Stance" or "Defensive Stance" } end }

dofile("ApogeePartyHealthBars_MouseButtonData.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_BoundActionLayouts.lua")

local factory = ApogeePartyHealthBars_BoundActionLayouts
local createdWithoutAcceptedCurrent, missingAcceptedError = pcall(factory.Create, {
    stateKey = "invalidActions",
    slots = {},
    schemaVersion = 2,
})
assert(not createdWithoutAcceptedCurrent
        and tostring(missingAcceptedError):find("must accept their current schema version", 1, true),
    "bound action layouts allowed an omitted current schema acceptance")
local createdWithOnlyLegacyAccepted, legacyOnlyError = pcall(factory.Create, {
    stateKey = "invalidActions",
    slots = {},
    schemaVersion = 2,
    acceptedSchemaVersions = { [1] = true },
})
assert(not createdWithOnlyLegacyAccepted
        and tostring(legacyOnlyError):find("must accept their current schema version", 1, true),
    "bound action layouts allowed acceptance of only legacy schemas")

dofile("ApogeePartyHealthBars_MouseButtonLayouts.lua")

local layouts = ApogeePartyHealthBars_MouseButtonLayouts
local actions = ApogeePartyHealthBars_ActionMacros
assert(layouts.Initialize(), "Buttons layouts did not initialize")
assert(layouts.GetActiveSpecKey() == "1" and layouts.GetActiveKey() == "base",
    "Buttons did not initialize the base profile")
assert(ApogeePartyHealthBars_S.charSv.mouseActions.schemaVersion == 1,
    "Buttons did not create its versioned saved root")

assert(layouts.SetSlot("base", "normal3", actions.CreateSpell(133, "Fireball")),
    "Buttons base assignment failed")
local savedMouseActions = ApogeePartyHealthBars_S.charSv.mouseActions
assert(not layouts.Initialize(),
    "reinitializing unchanged Buttons layouts unexpectedly changed context")
assert(ApogeePartyHealthBars_S.charSv.mouseActions == savedMouseActions
        and layouts.GetSlot("base", "normal3").spellName == "Fireball",
    "reinitializing Buttons layouts discarded saved assignments")
formCount = 2
assert(layouts.RefreshActiveContext(), "Buttons did not discover form-state layouts")
assert(#layouts.GetLayouts() == 3 and layouts.GetSlot("spell:2457", "normal3") == nil,
    "newly discovered Buttons forms did not start empty")
layouts.SetSlot("spell:71", "normal3", actions.CreateSpell(116, "Frostbolt"))
activeForm = 2
assert(layouts.GetActiveKey() == "spell:71"
        and layouts.GetSlot(layouts.GetActiveKey(), "normal3").spellName == "Frostbolt",
    "Buttons state selection did not preserve its independent action")

activeSpec = 2
assert(layouts.RefreshActiveContext() and layouts.GetSlot("base", "normal3") == nil,
    "new Buttons talent profile did not start empty")
activeSpec = 1
layouts.RefreshActiveContext()
assert(layouts.GetSlot("spell:71", "normal3").spellName == "Frostbolt",
    "Buttons first talent profile did not persist")

print("PASS per-spec and per-state Buttons layouts")
