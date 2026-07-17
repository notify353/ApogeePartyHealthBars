ApogeePartyHealthBars_C = {
    BINDING_SLOTS = {
        { key = "1", label = "Left Click" },
    },
}
ApogeePartyHealthBars_S = {
    configMode = true,
    selectedBindingKey = "1",
    selectedShortcutSlot = nil,
    focusedKeySlot = nil,
    selectedKeySlot = nil,
    selectedKeyLayout = nil,
    selectedWheelSlot = nil,
    selectedWheelLayout = nil,
    configTab = "healing",
    spellbookHooked = false,
    containerItemsHooked = false,
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
ApogeePartyHealthBars_WheelMacros = {
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
ApogeePartyHealthBars_KeyActions = {
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
}

local spellButton = { scripts = {} }
function spellButton:GetName() return "SpellButton1" end
function spellButton:GetParent() return nil end
function spellButton:HookScript(script, callback) self.scripts[script] = callback end
SpellButton1 = spellButton

local inCombat = false
local shiftDown = false
function InCombatLockdown() return inCombat end
function IsShiftKeyDown() return shiftDown end
local containerHook
function ContainerFrameItemButton_OnModifiedClick() end
function hooksecurefunc(name, callback)
    assert(name == "ContainerFrameItemButton_OnModifiedClick")
    containerHook = callback
end
C_Container = { GetContainerItemID = function(bag, slot)
    assert(bag == 0 and slot == 4)
    return 1251
end }
local bagParent = { GetID = function() return 0 end }
local itemButton = {
    GetParent = function() return bagParent end,
    GetID = function() return 4 end,
}
StackSplitFrame = {
    shown = true,
    IsShown = function(self) return self.shown end,
    Hide = function(self) self.shown = false end,
}

dofile("ApogeePartyHealthBars_BindingController.lua")
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
    RefreshBindPanel = function() refreshes = refreshes + 1 end,
    ForceRefresh = function() refreshes = refreshes + 1 end,
    Print = function() end,
    SyncVisualTicker = function() end,
    GetSpellFromSpellButton = function() return 2061, "Flash Heal" end,
    GetConfigUI = function()
        return {
            RefreshShortcutPanel = function(slot) refreshedShortcutSlot = slot end,
            RefreshKeyPanel = function(slot) refreshedKeySlot = slot end,
            RefreshWheelPanel = function(slot) refreshedWheelSlot = slot end,
        }
    end,
})

assert(type(controller.HookSpellbook) == "function", "spellbook post-hook was not exposed")
assert(type(controller.HookContainerItems) == "function", "bag-item post-hook was not exposed")
assert(controller.OpenSpellbook == nil, "binding controller directly opens the Blizzard spellbook")
assert(controller.HookSpellbook(), "spellbook button was not found")
assert(type(spellButton.scripts.OnClick) == "function", "secure OnClick post-hook was not installed")
assert(spellButton.scripts.PreClick == nil, "taint-prone PreClick hook was installed")
assert(controller.HookContainerItems() and type(containerHook) == "function",
    "container item modified-click post-hook was not installed")

spellButton.scripts.OnClick(spellButton)
assert(bindings["1"] == nil, "ordinary spell click changed a binding")
shiftDown = true
spellButton.scripts.OnClick(spellButton)
assert(bindings["1"] and bindings["1"].kind == "spell"
    and bindings["1"].spellId == 2061 and bindings["1"].spellName == "Flash Heal",
    "secure post-hook did not assign a click binding")
assert(refreshes == 2, "binding assignment did not refresh its settings and frames")

ApogeePartyHealthBars_S.selectedBindingKey = nil
ApogeePartyHealthBars_S.selectedShortcutSlot = 3
ApogeePartyHealthBars_S.configTab = "shortcuts"
spellButton.scripts.OnClick(spellButton)
assert(assignedShortcutSpell and assignedShortcutSpell.slot == 3
    and assignedShortcutSpell.spellId == 2061 and assignedShortcutSpell.spellName == "Flash Heal",
    "secure post-hook did not assign a Shortcut spell")
assert(refreshedShortcutSlot == 3, "Shortcuts refresh did not receive the actual replacement slot")
assignedShortcutSpell = nil
spellButton.scripts.OnClick(spellButton)
assert(assignedShortcutSpell and assignedShortcutSpell.slot == nil,
    "Shortcuts tab did not allow smart assignment without an armed row")
assert(refreshedShortcutSlot == 1, "Shortcuts refresh did not receive the actual appended slot")

containerHook(itemButton)
assert(assignedShortcutItem and assignedShortcutItem.slot == nil
    and assignedShortcutItem.itemId == 1251 and assignedShortcutItem.itemName == "Linen Bandage",
    "bag post-hook did not assign an item Shortcut")
assert(refreshedShortcutSlot == 2, "Shortcuts refresh did not receive the item slot")
assert(not StackSplitFrame.shown, "Shortcut item assignment left Blizzard's Shift-click split dialog open")

ApogeePartyHealthBars_S.selectedShortcutSlot = nil
ApogeePartyHealthBars_S.selectedWheelSlot = "shiftUp"
ApogeePartyHealthBars_S.selectedWheelLayout = "removed-layout"
ApogeePartyHealthBars_S.configTab = "wheel"
spellButton.scripts.OnClick(spellButton)
assert(assignedWheelSpell and assignedWheelSpell.layout == "base" and assignedWheelSpell.slot == "shiftUp"
    and assignedWheelSpell.spellId == 2061 and assignedWheelSpell.spellName == "Flash Heal",
    "secure post-hook did not assign a wheel spell")
assert(refreshedWheelSlot == "shiftUp", "Wheel refresh did not receive the actual replacement gesture")
assignedWheelSpell = nil
spellButton.scripts.OnClick(spellButton)
assert(assignedWheelSpell and assignedWheelSpell.layout == "base" and assignedWheelSpell.slot == nil,
    "Wheel tab did not allow smart assignment without an armed row")
assert(refreshedWheelSlot == "ctrlUp", "Wheel refresh did not receive the actual first-empty gesture")
StackSplitFrame.shown = true
containerHook(itemButton)
assert(assignedWheelItem and assignedWheelItem.layout == "base" and assignedWheelItem.slot == nil
    and assignedWheelItem.itemId == 1251,
    "bag post-hook did not assign a Wheel item")
assert(refreshedWheelSlot == "normalDown", "Wheel refresh did not receive the item gesture")
assert(not StackSplitFrame.shown, "Wheel item assignment left Blizzard's Shift-click split dialog open")

ApogeePartyHealthBars_S.selectedWheelSlot = nil
ApogeePartyHealthBars_S.selectedKeySlot = "keyF"
ApogeePartyHealthBars_S.selectedKeyLayout = "removed-layout"
ApogeePartyHealthBars_S.configTab = "keys"
spellButton.scripts.OnClick(spellButton)
assert(assignedKeySpell and assignedKeySpell.layout == "base" and assignedKeySpell.slot == "keyF"
    and assignedKeySpell.spellId == 2061 and assignedKeySpell.spellName == "Flash Heal",
    "secure post-hook did not assign a Keys spell")
assert(ApogeePartyHealthBars_S.focusedKeySlot == "keyF"
    and ApogeePartyHealthBars_S.selectedKeySlot == nil and refreshedKeySlot == "keyF",
    "Keys assignment did not retain focus and clear its replacement arm")
assignedKeySpell = nil
spellButton.scripts.OnClick(spellButton)
assert(assignedKeySpell and assignedKeySpell.layout == "base" and assignedKeySpell.slot == nil,
    "Keys tab did not allow smart assignment without an armed tile")
assert(ApogeePartyHealthBars_S.focusedKeySlot == "key1" and refreshedKeySlot == "key1",
    "Keys smart assignment did not focus its actual first-empty key")
StackSplitFrame.shown = true
containerHook(itemButton)
assert(assignedKeyItem and assignedKeyItem.layout == "base" and assignedKeyItem.slot == nil
    and assignedKeyItem.itemId == 1251,
    "bag post-hook did not assign a Keys item")
assert(ApogeePartyHealthBars_S.focusedKeySlot == "keyG" and refreshedKeySlot == "keyG",
    "Keys item assignment did not focus its actual key")
assert(not StackSplitFrame.shown, "Keys item assignment left Blizzard's Shift-click split dialog open")

ApogeePartyHealthBars_S.configTab = "healing"
ApogeePartyHealthBars_S.selectedBindingKey = "1"
assignedShortcutItem, assignedKeyItem, assignedWheelItem = nil, nil, nil
StackSplitFrame.shown = true
containerHook(itemButton)
assert(bindings["1"] and bindings["1"].kind == "item"
    and bindings["1"].itemId == 1251 and bindings["1"].itemName == "Linen Bandage",
    "Healing did not accept a usable bag item")
assert(assignedShortcutItem == nil and assignedKeyItem == nil and assignedWheelItem == nil,
    "Healing item assignment leaked into another action feature")
assert(not StackSplitFrame.shown, "Healing item assignment left Blizzard's Shift-click split dialog open")
assert(refreshes == 4, "Healing item assignment did not refresh its settings and secure frames")

ApogeePartyHealthBars_S.selectedBindingKey = nil
bindings["1"] = nil
containerHook(itemButton)
assert(bindings["1"] == nil, "Healing assigned an item without an armed click row")

ApogeePartyHealthBars_S.configTab = "general"
ApogeePartyHealthBars_S.selectedBindingKey = "1"
spellButton.scripts.OnClick(spellButton)
containerHook(itemButton)
assert(bindings["1"] == nil,
    "a stale Healing selection assigned an action from a non-action settings tab")

inCombat = true
ApogeePartyHealthBars_S.configTab = "shortcuts"
assignedShortcutSpell, assignedShortcutItem = nil, nil
spellButton.scripts.OnClick(spellButton)
containerHook(itemButton)
assert(assignedShortcutSpell == nil and assignedShortcutItem == nil,
    "Shortcut assignment ran in combat")

print("PASS shortcut Shift-click routing and taint guard")
