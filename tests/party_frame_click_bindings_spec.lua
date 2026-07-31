local modifiers = {
    "", "alt-", "ctrl-", "ctrl-alt-", "shift-",
    "shift-alt-", "shift-ctrl-", "shift-ctrl-alt-",
}
local bindingSlots = {}
for _, modifier in ipairs(modifiers) do
    for button = 1, 5 do
        bindingSlots[#bindingSlots + 1] = {
            key = modifier .. button,
            label = modifier .. button,
        }
    end
end

ApogeePartyHealthBars_C = { MAX_ROWS = 1, BINDING_SLOTS = bindingSlots }
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
    ["shift-1"] = { kind = "spell", spellId = 2054, spellName = "Heal(Rank 1)" },
    ["shift-2"] = { kind = "item", itemId = 1251, itemName = "Linen Bandage" },
    ["4"] = { kind = "spell", spellId = 139, spellName = "Renew(Rank 12)" },
    ["ctrl-5"] = { kind = "spell", spellId = 2061, spellName = "Flash Heal(Rank 7)" },
}
local primary = { unitId = "party1", btn = frame(), castBtn = frame(false), visible = true }
local target = { unitId = "party1target", btn = frame(), castBtn = frame(false), visible = true }
local targetOfTarget = {
    unitId = "party1targettarget", btn = frame(), castBtn = frame(false), visible = true,
}
local row = { btn = primary.btn, surfaces = { primary, target, targetOfTarget } }

local function keyToActionAttrs(slotKey)
    local button = slotKey:match("(%d+)$")
    if not button then return nil, nil, nil end
    local modifiersForSlot = {}
    for modifier in slotKey:sub(1, #slotKey - #button):gmatch("(%a+)-") do
        modifiersForSlot[#modifiersForSlot + 1] = modifier
    end
    table.sort(modifiersForSlot)
    local prefix = #modifiersForSlot > 0
        and (table.concat(modifiersForSlot, "-") .. "-") or ""
    return prefix .. "type" .. button,
        prefix .. "spell" .. button,
        prefix .. "item" .. button
end

dofile("Actions/ActionData.lua")
dofile("Actions/PartyFrameClickBindings.lua")
local clicks = ApogeePartyHealthBars_PartyFrameClickBindings
clicks.Initialize({
    rows = { row },
    KeyToActionAttrs = keyToActionAttrs,
    GetBindingsTable = function() return bindings end,
    GetBindingAction = ApogeePartyHealthBars_ActionData.Normalize,
})

clicks.ApplyAll()
assert(primary.castBtn.attributes.unit == "party1"
        and target.castBtn.attributes.unit == "party1target"
        and targetOfTarget.castBtn.attributes.unit == "party1targettarget",
    "secure click buttons did not receive their displayed units")
assert(primary.castBtn.attributes.type1 == "macro"
    and primary.castBtn.attributes.type == "macro"
    and primary.castBtn.attributes.macrotext1
        == "/cast [mod:shift,nomod:ctrl,nomod:alt,@party1,help,nodead] Heal(Rank 1)\n"
            .. "/cast [nomod,@party1,help,nodead] Flash Heal(Rank 7)"
    and primary.castBtn.attributes.macrotext == primary.castBtn.attributes.macrotext1
    and primary.castBtn.attributes["shift-type1"] == nil,
    "left-click actions did not use the modifier-safe secure macro")
assert(primary.castBtn.attributes["shift-type2"] == "item"
    and primary.castBtn.attributes["shift-item2"] == "item:1251",
    "modified item attributes were not applied")
assert(primary.castBtn.attributes.type4 == "spell" and primary.castBtn.attributes.spell4 == 139
        and primary.castBtn.attributes["ctrl-type5"] == "spell"
        and primary.castBtn.attributes["ctrl-spell5"] == 2061,
    "side-button Healing attributes were not applied")
assert(primary.castBtn.shown and primary.castBtn.mouseEnabled
    and target.castBtn.shown and target.castBtn.mouseEnabled
    and targetOfTarget.castBtn.shown and targetOfTarget.castBtn.mouseEnabled,
    "active secure click overlays were not enabled")

local initialBindings = bindings
local matrixBindings = {}
for index, slot in ipairs(ApogeePartyHealthBars_C.BINDING_SLOTS) do
    if slot.key == "1" then
        matrixBindings[slot.key] = {
            kind = "spell", spellId = 30001, spellName = "Matrix Normal",
        }
    elseif slot.key == "shift-1" then
        matrixBindings[slot.key] = {
            kind = "spell", spellId = 30002, spellName = "Matrix Shift",
        }
    elseif index % 2 == 0 then
        matrixBindings[slot.key] = {
            kind = "item", itemId = 1251, itemName = "Linen Bandage",
        }
    else
        matrixBindings[slot.key] = {
            kind = "spell", spellId = 30000 + index, spellName = "Matrix Spell " .. index,
        }
    end
end

bindings = matrixBindings
clicks.ApplyAll()
assert(primary.castBtn.attributes.macrotext1
        == "/cast [mod:shift,nomod:ctrl,nomod:alt,@party1,help,nodead] Matrix Shift\n"
            .. "/cast [nomod,@party1,help,nodead] Matrix Normal",
    "the full binding matrix changed the modifier-safe Left Click composite")
for _, slot in ipairs(ApogeePartyHealthBars_C.BINDING_SLOTS) do
    if slot.key ~= "1" and slot.key ~= "shift-1" then
        local action = matrixBindings[slot.key]
        local typeAttr, spellAttr, itemAttr = keyToActionAttrs(slot.key)
        if action.kind == "item" then
            assert(primary.castBtn.attributes[typeAttr] == "item"
                    and primary.castBtn.attributes[itemAttr] == "item:1251"
                    and primary.castBtn.attributes[spellAttr] == nil,
                "item binding matrix failed for " .. slot.key)
        else
            assert(primary.castBtn.attributes[typeAttr] == "spell"
                    and primary.castBtn.attributes[spellAttr] == action.spellId
                    and primary.castBtn.attributes[itemAttr] == nil,
                "spell binding matrix failed for " .. slot.key)
        end
    end
end

bindings = initialBindings
clicks.ApplyAll()
assert(primary.castBtn.attributes["alt-type3"] == nil
        and primary.castBtn.attributes["alt-spell3"] == nil
        and primary.castBtn.attributes["alt-item3"] == nil,
    "restoring sparse bindings left stale matrix attributes")

bindings["shift-2"] = { kind = "spell", spellId = 139, spellName = "Renew(Rank 12)" }
clicks.ApplyAll()
assert(primary.castBtn.attributes["shift-item2"] == nil
    and primary.castBtn.attributes["shift-spell2"] == 139,
    "replacing an item left stale secure item attributes")

bindings["1"] = { kind = "item", itemId = 1251, itemName = "Linen Bandage" }
clicks.ApplyAll()
assert(primary.castBtn.attributes.type == "macro"
    and primary.castBtn.attributes.type1 == "macro"
    and primary.castBtn.attributes.macrotext1:find(
        "/use [nomod,@party1,help,nodead] item:1251", 1, true)
    and primary.castBtn.attributes.spell == nil and primary.castBtn.attributes.spell1 == nil,
    "replacing the primary spell with an item left stale base spell attributes")

local mutations = primary.castBtn.mutations
inCombat = true
clicks.ApplyAll()
assert(secureUpdateRequests == 1 and primary.castBtn.mutations == mutations,
    "combat application mutated secure attributes instead of deferring")

inCombat = false
bindings = {}
clicks.ApplyAll()
assert(not primary.castBtn.shown and not primary.castBtn.mouseEnabled
    and primary.castBtn.attributes.type == nil and primary.castBtn.attributes.item == nil,
    "clearing all actions left an active secure click overlay")

print("PASS secure Healing spell and item clicks")
