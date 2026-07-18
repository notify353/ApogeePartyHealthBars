ApogeePartyHealthBars_S = { charSv = {} }
ApogeePartyHealthBars_WheelData = {
    SLOTS = {
        { id = "normalUp" },
        { id = "normalDown" },
    },
    DISPLAY_ORDER = { "normalUp", "normalDown" },
}
ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key) return key or "none" end,
}

local forms = {}
local activeForm = 0
local stealthed = false
local activeSpecGroup = 1
local class = "MAGE"
local knownSpells = {}
local specializationApi = {
    GetActiveSpecGroup = function(isInspect, isPet)
        assert(isInspect == false and isPet == false, "active spec lookup used unexpected flags")
        return activeSpecGroup
    end,
}
C_SpecializationInfo = nil
function UnitClass() return class, class end
function GetNumShapeshiftForms() return #forms end
function GetShapeshiftForm() return activeForm end
function IsStealthed() return stealthed end
function GetShapeshiftFormInfo(index)
    local form = forms[index]
    return form and form.texture, index == activeForm, true, form and form.spellId
end
function GetSpellInfo(spellId)
    for _, form in ipairs(forms) do
        if form.spellId == spellId then return form.name end
    end
    local names = {
        [768] = "Cat Form",
        [5215] = "Prowl",
        [15473] = "Shadowform",
        [1784] = "Stealth",
        [2645] = "Ghost Wolf",
    }
    return names[spellId]
end
C_SpellBook = { IsSpellKnown = function(spellId) return knownSpells[spellId] == true end }

dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_BoundActionLayouts.lua")
dofile("ApogeePartyHealthBars_WheelLayouts.lua")
local layouts = ApogeePartyHealthBars_WheelLayouts

ApogeePartyHealthBars_S.charSv.wheelMacros = {
    schemaVersion = 2,
    enabled = false,
    layouts = { base = { slots = { normalUp = { macroText = "/cast Legacy Wheel Spell" } } } },
}
layouts.Initialize()
local saved = ApogeePartyHealthBars_S.charSv.wheelMacros
assert(saved.schemaVersion == layouts.SCHEMA_VERSION and saved.enabled == nil
    and saved.slots == nil and saved.layouts == nil,
    "native Wheel schema retained obsolete single-layout data")
assert(saved.profiles["1"] and saved.profiles["2"] == nil
    and layouts.GetActiveSpecKey() == "1",
    "Wheel did not fall back to the first talent-group profile")
C_SpecializationInfo = specializationApi
assert(not layouts.HasStates() and #layouts.GetLayouts() == 1,
    "a character with no reported forms exposed state configuration")
assert(layouts.GetActiveKey() == "base", "no-form character did not resolve Base")

layouts.SetSlot("base", "normalUp", {
    spellName = "Base Spell", macroText = "/cast Base Spell", soundKey = "none",
})
local baseUp = layouts.GetSlot("base", "normalUp")
forms = {
    { spellId = 2457, name = "Battle Stance", texture = 132349 },
    { spellId = 71, name = "Defensive Stance", texture = 132341 },
}
class = "WARRIOR"
activeForm = 1
assert(layouts.RefreshActiveContext(), "new forms did not change the layout registry")
assert(layouts.HasStates() and #layouts.GetLayouts() == 2
    and not layouts.HasBaseLayout() and not layouts.IsKnownLayout("base"),
    "Warrior state registry exposed a nonexistent Base layout")
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Base Spell"
    and layouts.GetSlot("spell:71", "normalUp") == nil,
    "populated hidden Base was not preserved without keeping later states nonempty")
layouts.GetSlot("spell:2457", "normalUp").macroText = "/cast Battle Spell"
assert(layouts.GetSlot("base", "normalUp").macroText == "/cast Base Spell",
    "state layout did not remain independent from Base")

activeSpecGroup = 2
assert(layouts.RefreshActiveContext(),
    "talent-group change with an identical form registry was not detected")
assert(layouts.GetActiveSpecKey() == "2" and saved.profiles["2"],
    "second talent-group profile was not created when first activated")
assert(layouts.GetSlot("spell:2457", "normalUp") == nil,
    "second talent-group profile copied the first profile instead of starting empty")
layouts.SetSlot("spell:2457", "normalUp", {
    spellName = "Spec Two Battle Spell", macroText = "/cast Spec Two Battle Spell", soundKey = "none",
})
assert(not layouts.RefreshActiveContext(), "duplicate active-context refresh reported a change")

activeSpecGroup = 1
assert(layouts.RefreshActiveContext()
    and layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Battle Spell",
    "returning to the first talent group did not restore its independent layout")
activeSpecGroup = 2
layouts.RefreshActiveContext()
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Spec Two Battle Spell",
    "second talent-group layout did not persist independently")
activeSpecGroup = 1
layouts.RefreshActiveContext()

activeForm = 2
assert(layouts.GetActiveKey() == "spell:71", "active form index resolved the wrong layout")
forms[1], forms[2] = forms[2], forms[1]
layouts.RefreshActiveContext()
assert(layouts.GetLayoutKeyForState(1) == "spell:71"
    and layouts.GetLayoutKeyForState(2) == "spell:2457",
    "reordered forms were not remapped by stable spell ID")
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Battle Spell",
    "reordering forms lost the saved state layout")

table.remove(forms, 2)
layouts.RefreshActiveContext()
assert(not layouts.IsKnownLayout("spell:2457"),
    "removed form remained visible in the active layout registry")
forms[#forms + 1] = { spellId = 2457, name = "Battle Stance", texture = 132349 }
layouts.RefreshActiveContext()
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Battle Spell",
    "relearned form did not restore its dormant saved layout")
assert(layouts.GetStateDriver() == "[form:1] 1; [form:2] 2; 1",
    "form-state driver was not generated from the live registry")

class = "DRUID"
forms = {
    { spellId = 768, name = "Cat Form", texture = 132115 },
    { spellId = 5487, name = "Bear Form", texture = 132276 },
}
knownSpells[5215] = true
activeForm, stealthed = 1, false
layouts.RefreshActiveContext()
local prowlKey = "state:768:5215"
assert(layouts.HasBaseLayout() and layouts.IsKnownLayout(prowlKey)
    and #layouts.GetLayouts() == 4,
    "Druid registry did not expose Base, forms, and Cat/Prowl")
assert(layouts.GetActiveKey() == "spell:768",
    "ordinary Cat Form did not select the Cat layout")
stealthed = true
assert(layouts.GetActiveKey() == prowlKey,
    "Cat stealth did not select the Prowl layout")
assert(layouts.GetSlot(prowlKey, "normalUp") == nil,
    "new Prowl state did not start empty")
assert(layouts.GetStateDriver()
    == "[form:1,stealth] 3; [form:1] 1; [form:2] 2; 0",
    "Prowl condition was not ordered before ordinary Cat Form")
stealthed = false

class, forms, activeForm = "PRIEST", {}, 0
knownSpells[15473] = true
layouts.RefreshActiveContext()
assert(layouts.IsKnownLayout("spell:15473")
    and layouts.GetStateDriver() == "[form:1] 1; 0",
    "learned Shadowform did not receive a fallback form state")
activeForm = 1
assert(layouts.GetActiveKey() == "spell:15473",
    "Shadowform fallback did not become active")

knownSpells[15473] = nil
knownSpells[1784] = true
class, activeForm, stealthed = "ROGUE", 0, false
layouts.RefreshActiveContext()
assert(layouts.IsKnownLayout("spell:1784")
    and layouts.GetStateDriver() == "[stealth] 1; 0",
    "learned Rogue Stealth did not receive a fallback state")
stealthed = true
assert(layouts.GetActiveKey() == "spell:1784",
    "Rogue Stealth fallback did not become active")

knownSpells[1784] = nil
class, forms, activeForm, stealthed = "SHAMAN", {
    { spellId = 2645, name = "Ghost Wolf", texture = 136095 },
}, 1, false
layouts.RefreshActiveContext()
assert(layouts.IsKnownLayout("spell:2645")
    and layouts.GetActiveKey() == "spell:2645",
    "client-reported Ghost Wolf did not receive a native state")

class, forms, activeForm = "HUNTER", {
    { spellId = 13165, name = "Aspect of the Hawk", texture = 132174 },
}, 1
layouts.RefreshActiveContext()
assert(not layouts.HasStates() and #layouts.GetLayouts() == 1
    and layouts.GetActiveKey() == "base",
    "ordinary Hunter aspects were treated as secure class states")

print("PASS native and composite class-state Wheel layouts")
