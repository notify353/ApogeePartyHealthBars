ApogeePartyHealthBars_C = {
    BINDING_SLOTS = {
        { key = "1", label = "Left Click" },
        { key = "2", label = "Right Click" },
        { key = "shift-2", label = "Shift + Right Click" },
    },
}
ApogeePartyHealthBars_S = {
    charSv = {
        bindings = {
            ["1"] = 2061,
            ["2"] = { id = 139, name = "Renew(Rank 12)" },
            ["shift-2"] = { kind = "item", itemId = 1251, itemName = "Linen Bandage" },
            obsolete = "Remove Me",
        },
    },
}
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(itemId) if itemId == 1251 then return "Linen Bandage", 134436, itemId end end,
    GetCount = function() return 2 end,
    HasUseEffect = function(itemId) return itemId == 1251 end,
}
function GetSpellInfo(spellId)
    if spellId == 2061 then return "Flash Heal(Rank 7)" end
    if spellId == 139 then return "Renew(Rank 12)" end
end
local inCombat = false
function InCombatLockdown() return inCombat end
function UnitClass() return "Paladin", "PALADIN" end

dofile("ApogeePartyHealthBars_ActionData.lua")
local actions = ApogeePartyHealthBars_ActionData
ApogeePartyHealthBars_Effects = {
    SeedClassBindings = function(bindings, classToken)
        assert(classToken == "PALADIN")
        bindings["1"] = actions.CreateSpell(19750, "Flash of Light(Rank 7)")
        return true, 1
    end,
}
dofile("ApogeePartyHealthBars_BindingStore.lua")
local store = ApogeePartyHealthBars_BindingStore
local state = ApogeePartyHealthBars_S

assert(store.Initialize(), "binding store did not initialize")
assert(state.charSv.bindingSchemaVersion == 1, "binding schema version was not recorded")
assert(state.charSv.bindings["1"].kind == "spell"
    and state.charSv.bindings["1"].spellId == 2061
    and state.charSv.bindings["1"].spellName == "Flash Heal(Rank 7)",
    "legacy numeric binding was not normalized")
assert(state.charSv.bindings["2"].spellName == "Renew(Rank 12)",
    "legacy spell table was not normalized")
assert(state.charSv.bindings["shift-2"].kind == "item"
    and state.charSv.bindings.obsolete == nil, "item binding or unknown-key cleanup failed")
assert(store.GetDisplayName(state.charSv.bindings["1"]) == "Spell: Flash Heal(Rank 7)"
    and store.GetDisplayName(state.charSv.bindings["shift-2"]) == "Item: Linen Bandage",
    "typed Healing display names were not produced")
state.charSv.bindings["shift-2"].itemName = "Old Bandage"
assert(store.GetDisplayName(state.charSv.bindings["shift-2"]) == "Item: Linen Bandage"
    and state.charSv.bindings["shift-2"].itemName == "Linen Bandage",
    "Healing item display did not refresh its localized name")

local typeAttr, spellAttr, itemAttr = store.KeyToActionAttrs("shift-2")
assert(typeAttr == "shift-type2" and spellAttr == "shift-spell2" and itemAttr == "shift-item2",
    "modified secure action attributes were not generated")

local ok, message = store.AssignItem("2", 9999, "Not Usable")
assert(not ok and message == "that item has no usable effect.", "unusable item was accepted")
assert(store.AssignItem("2", 1251, "Linen Bandage"))
assert(state.charSv.bindings["2"].kind == "item" and state.charSv.bindings["2"].itemId == 1251,
    "usable item was not stored")
assert(store.AssignSpell("2", 2061, "Flash Heal(Rank 7)"))
assert(state.charSv.bindings["2"].kind == "spell", "spell did not replace an item binding")

inCombat = true
assert(not store.Clear("2") and state.charSv.bindings["2"] ~= nil,
    "combat clearing changed a Healing binding")
inCombat = false
assert(store.Clear("2") and state.charSv.bindings["2"] == nil,
    "Healing binding was not cleared")

state.charSv.bindings["2"] = 999999
assert(store.Initialize() and state.charSv.bindings["2"] == 999999,
    "temporarily unresolved legacy binding was erased during initialization")

state.charSv.bindings = {}
state.charSv.bindingDefaultsInitialized = nil
state.InitializeClassDefaultBindings()
assert(state.charSv.bindings["1"].spellName == "Flash of Light(Rank 7)"
    and state.charSv.bindingDefaultsInitialized,
    "class default binding did not use the canonical action format")

print("PASS typed Healing binding store")
