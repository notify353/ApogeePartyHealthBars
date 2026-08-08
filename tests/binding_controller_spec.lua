ApogeePartyHealthBars_C = {
    BINDING_SLOTS = {
        { key = "1", label = "Left Click" },
        { key = "2", label = "Right Click" },
    },
}
ApogeePartyHealthBars_S = {
    selectedKeyLayout = nil,
    selectedWheelLayout = nil,
}

local assignedShortcutSpell, assignedShortcutItem
ApogeePartyHealthBars_ShortcutBar = {
    AssignSpell = function(slot, spellId, spellName)
        assignedShortcutSpell = { slot = slot, spellId = spellId, spellName = spellName }
        return true, nil, slot or 1
    end,
    AssignItem = function(slot, itemId, itemName)
        assignedShortcutItem = { slot = slot, itemId = itemId, itemName = itemName }
        return true, nil, slot or 2
    end,
}
local assignedWheelSpell, assignedWheelItem
ApogeePartyHealthBars_MouseWheelActions = {
    GetActiveLayoutKey = function() return "base" end,
    IsKnownLayout = function(layout) return layout == "base" end,
    AssignSpell = function(layout, slot, spellId, spellName)
        assignedWheelSpell = { layout = layout, slot = slot, spellId = spellId, spellName = spellName }
        return true, nil, slot or "ctrlUp"
    end,
    AssignItem = function(layout, slot, itemId, itemName)
        assignedWheelItem = { layout = layout, slot = slot, itemId = itemId, itemName = itemName }
        return true, nil, slot or "normalDown"
    end,
}
local assignedKeySpell, assignedKeyItem
ApogeePartyHealthBars_KeyboardActions = {
    GetActiveLayoutKey = function() return "base" end,
    IsKnownLayout = function(layout) return layout == "base" end,
    AssignSpell = function(layout, slot, spellId, spellName)
        assignedKeySpell = { layout = layout, slot = slot, spellId = spellId, spellName = spellName }
        return true, nil, slot or "key1"
    end,
    AssignItem = function(layout, slot, itemId, itemName)
        assignedKeyItem = { layout = layout, slot = slot, itemId = itemId, itemName = itemName }
        return true, nil, slot or "keyG"
    end,
}
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(itemId) if itemId == 1251 then return "Linen Bandage" end end,
    GetCount = function(itemId) return itemId == 1251 and 1 or 0 end,
}

local inCombat = false
function InCombatLockdown() return inCombat end
local cursorInfo, clearedCursorCount = nil, 0
local shiftDown = false
function GetCursorInfo()
    if not cursorInfo then return nil end
    return cursorInfo[1], cursorInfo[2], cursorInfo[3], cursorInfo[4]
end
function IsShiftKeyDown() return shiftDown end
function ClearCursor()
    cursorInfo = nil
    clearedCursorCount = clearedCursorCount + 1
end

dofile("Actions/BindingController.lua")
local controller = ApogeePartyHealthBars_BindingController
local bindings = {}
local refreshes = 0
local refreshedShortcutSlot, refreshedKeySlot, refreshedWheelSlot
controller.Initialize({
    AssignBindingSpell = function(slot, spellId, spellName)
        bindings[slot] = { kind = "spell", spellId = spellId, spellName = spellName }
        return true, nil, bindings[slot]
    end,
    AssignBindingItem = function(slot, itemId, itemName)
        bindings[slot] = { kind = "item", itemId = itemId, itemName = itemName }
        return true, nil, bindings[slot]
    end,
    ClearBindingAction = function(slot) bindings[slot] = nil; return true end,
    MoveBindingAction = function(slot, direction)
        local other = slot == "1" and direction == 1 and "2"
            or slot == "2" and direction == -1 and "1"
        if not other then return false, "boundary" end
        bindings[slot], bindings[other] = bindings[other], bindings[slot]
        return true, "moved"
    end,
    RefreshPartyFrameClicksPage = function() refreshes = refreshes + 1 end,
    ForceRefresh = function() refreshes = refreshes + 1 end,
    Print = function() end,
    SyncVisualTicker = function() end,
    GetSpellFromCursor = function(slot, bookType, spellId, preserveRank)
        assert(slot == 7 and bookType == "spell" and spellId == 133)
        return 133, preserveRank and "Fireball(Rank 1)" or "Fireball"
    end,
    GetSettingsUI = function()
        return {
            RefreshShortcutPanel = function(slot) refreshedShortcutSlot = slot end,
            RefreshKeyboardPage = function(slot) refreshedKeySlot = slot end,
            RefreshMouseWheelPage = function(slot) refreshedWheelSlot = slot end,
        }
    end,
})

assert(controller.HookSpellbook == nil and controller.HookContainerItems == nil,
    "binding controller still exposes modified-click hooks")

cursorInfo = { "spell", 7, "spell", 133 }
assert(controller.AssignCursor("keyboard", "keyR", "base")
    and assignedKeySpell.layout == "base" and assignedKeySpell.slot == "keyR"
    and assignedKeySpell.spellId == 133 and assignedKeySpell.spellName == "Fireball",
    "ordinary spell cursor did not assign the highest-rank name to Keys")
assert(refreshedKeySlot == "keyR",
    "Keys spell drop did not refresh its destination")
assert(clearedCursorCount == 1 and cursorInfo == nil,
    "successful spell drop did not clear the cursor")

shiftDown = 1
cursorInfo = { "spell", 7, "spell", 133 }
assert(controller.AssignCursor("keyboard", "keyG", "base")
    and assignedKeySpell.spellId == 133
    and assignedKeySpell.spellName == "Fireball(Rank 1)",
    "Shift-drop did not preserve the selected spell rank")
shiftDown = false

cursorInfo = { "item", 1251 }
assert(controller.AssignCursor("keyboard", "keyG", "removed-layout")
    and assignedKeyItem.layout == "base" and assignedKeyItem.slot == "keyG"
    and assignedKeyItem.itemId == 1251 and refreshedKeySlot == "keyG",
    "item cursor did not assign to Keys with an active-layout fallback")

cursorInfo = { "item", 1251 }
assert(controller.AssignCursor("mouseWheel", "ctrlDown", "base")
    and assignedWheelItem.layout == "base" and assignedWheelItem.slot == "ctrlDown"
    and assignedWheelItem.itemId == 1251,
    "item cursor did not assign directly to a Wheel destination")
assert(refreshedWheelSlot == "ctrlDown", "Wheel item drop did not refresh its destination")

cursorInfo = { "spell", 7, "spell", 133 }
assert(controller.AssignCursor("shortcuts", nil)
    and assignedShortcutSpell.slot == nil and assignedShortcutSpell.spellId == 133,
    "spell cursor did not use the empty Shortcut destination")
assert(refreshedShortcutSlot == 1, "Shortcut drop did not refresh its assigned slot")

cursorInfo = { "item", 1251 }
assert(controller.AssignCursor("shortcuts", 2)
    and assignedShortcutItem.slot == 2 and assignedShortcutItem.itemId == 1251,
    "item cursor did not replace a Shortcut destination")

cursorInfo = { "spell", 7, "spell", 133 }
assert(controller.AssignCursor("partyFrameClicks", "2")
    and bindings["2"] and bindings["2"].kind == "spell" and bindings["2"].spellId == 133,
    "spell cursor did not assign directly to a Healing click row")

cursorInfo = { "item", 1251 }
assert(controller.AssignCursor("partyFrameClicks", "1")
    and bindings["1"] and bindings["1"].kind == "item" and bindings["1"].itemId == 1251,
    "item cursor did not assign directly to a Healing click row")
assert(refreshes == 4, "Healing cursor assignments did not refresh settings and secure frames")
assert(controller.MoveBinding("1", 1)
        and bindings["1"].kind == "spell" and bindings["2"].kind == "item"
        and refreshes == 6,
    "Healing movement did not swap bindings and refresh secure frames")
assert(controller.ClearBinding("2") and bindings["2"] == nil and refreshes == 8,
    "Healing clearing did not refresh settings and secure frames")

local beforeRejectedDrop = clearedCursorCount
local getCount = ApogeePartyHealthBars_ShortcutItems.GetCount
ApogeePartyHealthBars_ShortcutItems.GetCount = function() return 0 end
cursorInfo = { "item", 1251 }
assert(not controller.AssignCursor("shortcuts", 1)
    and clearedCursorCount == beforeRejectedDrop and cursorInfo ~= nil,
    "bank-only item cursor was assigned or consumed")
ApogeePartyHealthBars_ShortcutItems.GetCount = getCount

cursorInfo = { "macro", 3 }
assert(not controller.AssignCursor("shortcuts", 1)
    and clearedCursorCount == beforeRejectedDrop and cursorInfo ~= nil,
    "unsupported cursor payload was consumed")

local assignKeySpell = ApogeePartyHealthBars_KeyboardActions.AssignSpell
ApogeePartyHealthBars_KeyboardActions.AssignSpell = function()
    return false, "that key position is unavailable."
end
cursorInfo = { "spell", 7, "spell", 133 }
assert(not controller.AssignCursor("keyboard", "keyQ", "base")
    and clearedCursorCount == beforeRejectedDrop and cursorInfo ~= nil,
    "destination-rejected cursor payload was consumed")
ApogeePartyHealthBars_KeyboardActions.AssignSpell = assignKeySpell

inCombat = true
cursorInfo = { "spell", 7, "spell", 133 }
assert(not controller.AssignCursor("keyboard", "keyQ", "base")
    and clearedCursorCount == beforeRejectedDrop and cursorInfo ~= nil,
    "combat cursor drop changed an action or consumed the cursor")

print("PASS cursor-drop action routing")
