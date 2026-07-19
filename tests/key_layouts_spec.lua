ApogeePartyHealthBars_S = { charSv = {} }
ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key) return type(key) == "string" and key or "none" end,
}
ApogeePartyHealthBars_ShortcutItems = {}

local featureSupport = { multiSpecLayouts = true, formLayouts = true }
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(featureKey) return featureSupport[featureKey] ~= false end,
}

local activeSpec, formCount = 1, 0
local activeForm = 0
C_SpecializationInfo = {
    GetActiveSpecGroup = function() return activeSpec end,
}
function GetNumShapeshiftForms() return formCount end
function GetShapeshiftForm() return activeForm end
function GetShapeshiftFormInfo(index)
    return "texture" .. index, "Form " .. index, true, index == 1 and 2457 or 71
end
function UnitClass() return "Druid", "DRUID" end
C_Spell = { GetSpellInfo = function(id) return { name = id == 2457 and "Battle Stance" or "Defensive Stance" } end }

dofile("ApogeePartyHealthBars_KeyData.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_BoundActionLayouts.lua")
dofile("ApogeePartyHealthBars_KeyLayouts.lua")

local layouts = ApogeePartyHealthBars_KeyLayouts
local actions = ApogeePartyHealthBars_ActionMacros
assert(layouts.Initialize(), "Keys layouts did not initialize")
assert(layouts.GetActiveSpecKey() == "1" and layouts.GetActiveKey() == "base",
    "Keys did not initialize the base profile")
assert(ApogeePartyHealthBars_S.charSv.keyActions.schemaVersion == 2
    and ApogeePartyHealthBars_S.charSv.keyActions.enabled == nil,
    "Keys did not create a permanent saved root")

local fireball = actions.CreateSpell(133, "Fireball")
assert(layouts.SetSlot("base", "key1", fireball), "Keys base assignment failed")
formCount = 2
assert(layouts.RefreshActiveContext(), "Keys did not discover form-state layouts")
assert(#layouts.GetLayouts() == 3 and layouts.GetSlot("spell:2457", "key1") == nil
    and layouts.GetSlot("spell:71", "key1") == nil,
    "newly discovered Keys forms copied assignments instead of starting empty")
layouts.SetSlot("spell:71", "key1", actions.CreateSpell(116, "Frostbolt"))
activeForm = 2
assert(layouts.GetActiveKey() == "spell:71"
    and layouts.GetSlot(layouts.GetActiveKey(), "key1").spellName == "Frostbolt",
    "Keys state selection did not preserve its independent action")

activeSpec = 2
assert(layouts.RefreshActiveContext(), "Keys talent profile did not change")
assert(layouts.GetActiveSpecKey() == "2" and layouts.GetSlot("base", "key1") == nil,
    "new Keys talent profile did not start empty")
activeSpec = 1
layouts.RefreshActiveContext()
assert(layouts.GetSlot("spell:71", "key1").spellName == "Frostbolt",
    "Keys first talent profile did not persist")

C_SpecializationInfo = nil
GetActiveTalentGroup = function() return 2 end
assert(layouts.RefreshActiveContext() and layouts.GetActiveSpecKey() == "2",
    "legacy talent-group API did not select its independent Keys profile")

featureSupport.multiSpecLayouts = false
featureSupport.formLayouts = false
formCount = 2
GetShapeshiftFormInfo = function() error("unsupported form API was called") end
assert(layouts.RefreshActiveContext() and layouts.GetActiveSpecKey() == "1"
        and layouts.GetActiveKey() == "base" and #layouts.GetLayouts() == 1,
    "unsupported specialization and form APIs did not fall back to Base")

print("PASS per-spec and per-state Keys layouts")
