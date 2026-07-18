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
local activeSpecGroup = 1
local class = "MAGE"
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
function GetShapeshiftFormInfo(index)
    local form = forms[index]
    return form and form.texture, index == activeForm, true, form and form.spellId
end
function GetSpellInfo(spellId)
    for _, form in ipairs(forms) do
        if form.spellId == spellId then return form.name end
    end
end

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
assert(not layouts.HasStances() and #layouts.GetLayouts() == 1,
    "a character with no reported forms exposed stance configuration")
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
assert(layouts.HasStances() and #layouts.GetLayouts() == 2
    and not layouts.HasBaseLayout() and not layouts.IsKnownLayout("base"),
    "Warrior registry exposed a nonexistent Base layout")
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Base Spell",
    "first Warrior stance did not copy the internal seed")
layouts.GetSlot("spell:2457", "normalUp").macroText = "/cast Battle Spell"
assert(layouts.GetSlot("base", "normalUp").macroText == "/cast Base Spell",
    "stance layout did not remain independent from Base")

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
assert(layouts.GetLayoutKeyForIndex(1) == "spell:71"
    and layouts.GetLayoutKeyForIndex(2) == "spell:2457",
    "reordered forms were not remapped by stable spell ID")
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Battle Spell",
    "reordering forms lost the saved stance layout")

table.remove(forms, 2)
layouts.RefreshActiveContext()
assert(not layouts.IsKnownLayout("spell:2457"),
    "removed form remained visible in the active layout registry")
forms[#forms + 1] = { spellId = 2457, name = "Battle Stance", texture = 132349 }
layouts.RefreshActiveContext()
assert(layouts.GetSlot("spell:2457", "normalUp").macroText == "/cast Battle Spell",
    "relearned form did not restore its dormant saved layout")
assert(layouts.GetStateDriver() == "[stance:1] 1; [stance:2] 2; 1",
    "stance driver was not generated from the live form registry")
class = "DRUID"
layouts.RefreshActiveContext()
assert(layouts.HasBaseLayout() and layouts.IsKnownLayout("base")
    and layouts.GetStateDriver() == "[stance:1] 1; [stance:2] 2; 0",
    "a class with a valid no-form state lost its Base layout")

print("PASS stance-aware wheel layouts")
