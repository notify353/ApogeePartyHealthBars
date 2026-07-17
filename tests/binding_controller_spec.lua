ApogeePartyHealthBars_C = {
    BINDING_SLOTS = {
        { key = "1", label = "Left Click" },
    },
}
ApogeePartyHealthBars_S = {
    configMode = true,
    selectedBindingKey = "1",
    selectedTrackerSlot = nil,
    selectedWheelSlot = nil,
    selectedWheelLayout = nil,
    configTab = "healing",
    spellbookHooked = false,
}

local assignedTrackerSpell
ApogeePartyHealthBars_SpellTracker = {
    AssignSpell = function(slot, spellId, spellName)
        assignedTrackerSpell = { slot = slot, spellId = spellId, spellName = spellName }
        return true, nil, slot or 1
    end,
}
local assignedWheelSpell
ApogeePartyHealthBars_WheelMacros = {
    GetActiveLayoutKey = function() return "base" end,
    IsKnownLayout = function(layout) return layout == "base" end,
    AssignSpell = function(layout, slot, spellId, spellName)
        assignedWheelSpell = { layout = layout, slot = slot, spellId = spellId, spellName = spellName }
        return true, nil, slot or "ctrlUp"
    end,
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

dofile("ApogeePartyHealthBars_BindingController.lua")
local controller = ApogeePartyHealthBars_BindingController
local bindings = {}
local refreshes = 0
local refreshedTrackerSlot, refreshedWheelSlot
controller.Initialize({
    GetBindingsTable = function() return bindings end,
    RefreshBindPanel = function() refreshes = refreshes + 1 end,
    ForceRefresh = function() refreshes = refreshes + 1 end,
    Print = function() end,
    SyncVisualTicker = function() end,
    GetSpellFromSpellButton = function() return 2061, "Flash Heal" end,
    GetConfigUI = function()
        return {
            RefreshSpellPanel = function(slot) refreshedTrackerSlot = slot end,
            RefreshWheelPanel = function(slot) refreshedWheelSlot = slot end,
        }
    end,
})

assert(type(controller.HookSpellbook) == "function", "spellbook post-hook was not exposed")
assert(controller.OpenSpellbook == nil, "binding controller directly opens the Blizzard spellbook")
assert(controller.HookSpellbook(), "spellbook button was not found")
assert(type(spellButton.scripts.OnClick) == "function", "secure OnClick post-hook was not installed")
assert(spellButton.scripts.PreClick == nil, "taint-prone PreClick hook was installed")

spellButton.scripts.OnClick(spellButton)
assert(bindings["1"] == nil, "ordinary spell click changed a binding")
shiftDown = true
spellButton.scripts.OnClick(spellButton)
assert(bindings["1"] and bindings["1"].id == 2061 and bindings["1"].name == "Flash Heal",
    "secure post-hook did not assign a click binding")
assert(refreshes == 2, "binding assignment did not refresh its settings and frames")

ApogeePartyHealthBars_S.selectedBindingKey = nil
ApogeePartyHealthBars_S.selectedTrackerSlot = 3
ApogeePartyHealthBars_S.configTab = "spells"
spellButton.scripts.OnClick(spellButton)
assert(assignedTrackerSpell and assignedTrackerSpell.slot == 3
    and assignedTrackerSpell.spellId == 2061 and assignedTrackerSpell.spellName == "Flash Heal",
    "secure post-hook did not assign a tracker spell")
assert(refreshedTrackerSlot == 3, "Spells refresh did not receive the actual replacement slot")
assignedTrackerSpell = nil
spellButton.scripts.OnClick(spellButton)
assert(assignedTrackerSpell and assignedTrackerSpell.slot == nil,
    "Spells tab did not allow smart assignment without an armed row")
assert(refreshedTrackerSlot == 1, "Spells refresh did not receive the actual appended slot")

ApogeePartyHealthBars_S.selectedTrackerSlot = nil
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

inCombat = true
assignedTrackerSpell = nil
spellButton.scripts.OnClick(spellButton)
assert(assignedTrackerSpell == nil, "spell assignment ran in combat")

print("PASS spellbook taint guard")
