ApogeePartyHealthBars_C = {
    MAX_ROWS = 1,
    BINDING_SLOTS = {
        { key = "1", label = "Left Click" },
        { key = "shift-2", label = "Shift + Right Click" },
        { key = "4", label = "Mouse Button 4" },
        { key = "ctrl-5", label = "Ctrl + Mouse Button 5" },
    },
}
ApogeePartyHealthBars_S = { configMode = false }
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(itemId) if itemId == 1251 then return "Linen Bandage", 134436, itemId end end,
    GetCount = function() return 1 end,
}

local secureUpdateRequests = 0
ApogeePartyHealthBars_SecureFrames = {
    RequestSecureUpdate = function() secureUpdateRequests = secureUpdateRequests + 1 end,
    SetMouseEnabled = function(frame, enabled) frame.mouseEnabled = enabled end,
    Show = function(frame) frame.shown = true end,
    Hide = function(frame) frame.shown = false end,
}

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitExists() return true end
function UnitIsConnected() return true end
function GetSpellInfo(spellId) return spellId == 2061 and "Flash Heal(Rank 7)" or nil end

local function frame(shown)
    local value = { shown = shown ~= false, attributes = {}, mutations = 0 }
    function value:IsShown() return self.shown end
    function value:SetAttribute(key, data)
        self.attributes[key] = data
        self.mutations = self.mutations + 1
    end
    return value
end

local bindings = {
    ["1"] = { kind = "spell", spellId = 2061, spellName = "Flash Heal(Rank 7)" },
    ["shift-2"] = { kind = "item", itemId = 1251, itemName = "Linen Bandage" },
    ["4"] = { kind = "spell", spellId = 139, spellName = "Renew(Rank 12)" },
    ["ctrl-5"] = { kind = "spell", spellId = 2061, spellName = "Flash Heal(Rank 7)" },
}
local row = {
    unitId = "party1",
    btn = frame(),
    castBtn = frame(false),
    showTargetPane = true,
    targetBtn = frame(),
    targetCastBtn = frame(false),
}

dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ClickBindings.lua")
local clicks = ApogeePartyHealthBars_ClickBindings
clicks.Initialize({
    rows = { row },
    KeyToActionAttrs = function(slotKey)
        if slotKey == "1" then return "type1", "spell1", "item1" end
        if slotKey == "shift-2" then return "shift-type2", "shift-spell2", "shift-item2" end
        if slotKey == "4" then return "type4", "spell4", "item4" end
        return "ctrl-type5", "ctrl-spell5", "ctrl-item5"
    end,
    GetBindingsTable = function() return bindings end,
    GetBindingAction = ApogeePartyHealthBars_ActionData.Normalize,
    GetUnitTargetToken = function() return "target" end,
})

clicks.ApplyAll()
assert(row.castBtn.attributes.unit == "party1" and row.targetCastBtn.attributes.unit == "target",
    "secure click buttons did not receive their displayed units")
assert(row.castBtn.attributes.type1 == "spell" and row.castBtn.attributes.spell1 == 2061
    and row.castBtn.attributes.type == "spell" and row.castBtn.attributes.spell == 2061,
    "left-click spell attributes were not applied")
assert(row.castBtn.attributes["shift-type2"] == "item"
    and row.castBtn.attributes["shift-item2"] == "item:1251",
    "modified item attributes were not applied")
assert(row.castBtn.attributes.type4 == "spell" and row.castBtn.attributes.spell4 == 139
        and row.castBtn.attributes["ctrl-type5"] == "spell"
        and row.castBtn.attributes["ctrl-spell5"] == 2061,
    "side-button Healing attributes were not applied")
assert(row.castBtn.shown and row.castBtn.mouseEnabled
    and row.targetCastBtn.shown and row.targetCastBtn.mouseEnabled,
    "active secure click overlays were not enabled")

bindings["shift-2"] = { kind = "spell", spellId = 139, spellName = "Renew(Rank 12)" }
clicks.ApplyAll()
assert(row.castBtn.attributes["shift-item2"] == nil
    and row.castBtn.attributes["shift-spell2"] == 139,
    "replacing an item left stale secure item attributes")

bindings["1"] = { kind = "item", itemId = 1251, itemName = "Linen Bandage" }
clicks.ApplyAll()
assert(row.castBtn.attributes.type == "item" and row.castBtn.attributes.item == "item:1251"
    and row.castBtn.attributes.type1 == "item" and row.castBtn.attributes.item1 == "item:1251"
    and row.castBtn.attributes.spell == nil and row.castBtn.attributes.spell1 == nil,
    "replacing the primary spell with an item left stale base spell attributes")

local mutations = row.castBtn.mutations
inCombat = true
clicks.ApplyAll()
assert(secureUpdateRequests == 1 and row.castBtn.mutations == mutations,
    "combat application mutated secure attributes instead of deferring")

inCombat = false
bindings = {}
clicks.ApplyAll()
assert(not row.castBtn.shown and not row.castBtn.mouseEnabled
    and row.castBtn.attributes.type == nil and row.castBtn.attributes.item == nil,
    "clearing all actions left an active secure click overlay")

print("PASS secure Healing spell and item clicks")
