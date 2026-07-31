local sets = {
    [7] = {
        name = "Shield",
        icon = 132110,
        items = { [16] = 1001, [17] = 1002, [18] = 1003 },
        ignored = { [18] = true },
    },
}
local ignoredForSave, calls = {}, {}

ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(key) return key == "equipmentLoadouts" end,
    GetFeatureReason = function() return nil end,
}
InCombatLockdown = function() return false end
GetInventoryItemID = function(_, slot)
    return ({ [16] = 90000001, [17] = 90000002, [18] = 90000003 })[slot]
end
GetInventoryItemTexture = function(_, slot)
    return ({ [1] = 130001, [16] = 130016, [17] = 130017 })[slot]
end
MAX_EQUIPMENT_SETS_PER_PLAYER = 10
C_EquipmentSet = {
    CanUseEquipmentSets = function() return true end,
    GetEquipmentSetIDs = function() return { 7 } end,
    GetNumEquipmentSets = function() return 1 end,
    GetEquipmentSetInfo = function(id)
        local set = sets[id]
        return set.name, set.icon, id, false, 3, 0, 3, 0, 1
    end,
    GetItemIDs = function(id) return sets[id].items end,
    GetIgnoredSlots = function(id) return sets[id].ignored end,
    ClearIgnoredSlotsForSave = function()
        ignoredForSave = {}
        calls[#calls + 1] = "clear"
    end,
    IgnoreSlotForSave = function(slot)
        ignoredForSave[slot] = true
        calls[#calls + 1] = "ignore:" .. slot
    end,
    CreateEquipmentSet = function(name, icon)
        calls[#calls + 1] = "create:" .. name .. ":" .. tostring(icon)
    end,
    SaveEquipmentSet = function(id, icon)
        calls[#calls + 1] = "save:" .. id .. ":" .. tostring(icon)
    end,
    ModifyEquipmentSet = function(id, name)
        sets[id].name = name
        calls[#calls + 1] = "rename:" .. name
    end,
    DeleteEquipmentSet = function(id) calls[#calls + 1] = "delete:" .. id end,
    UseEquipmentSet = function(id)
        calls[#calls + 1] = "equip:" .. id
        return true
    end,
    EquipmentSetContainsLockedItems = function() return false end,
}

dofile("Actions/EquipmentSets.lua")
local equipment = ApogeePartyHealthBars_EquipmentSets

assert(equipment.IsSupported(), "native equipment capability was not exposed")
local iconOptions = equipment.GetEquippedIconOptions()
assert(iconOptions[1].key == "16" and iconOptions[1].texture == 130016,
    "equipped loadout icons did not prefer the main-hand item")
local listed = equipment.List()
assert(#listed == 1 and listed[1].name == "Shield" and listed[1].numIgnored == 1,
    "native equipment sets were not normalized")
local sentinelOptions = equipment.GetOptions("__none")
assert(sentinelOptions[1].key ~= sentinelOptions[2].key,
    "No loadout sentinel collided with a valid native loadout name")

local entry = {
    kind = "spell",
    spellName = "Shield Bash",
    macroText = "/cast Shield Bash",
    equipmentSetName = "Shield",
}
local expected = table.concat({
    "/equipslot [combat] 16 item:1001",
    "/equipslot [combat] 17 item:1002",
    "/equipset [nocombat] Shield",
    "/cast Shield Bash",
}, "\n")
assert(equipment.Compose(entry, entry.macroText) == expected,
    "hybrid equipment/action macro was not composed correctly")
assert(equipment.Compose({
        equipmentSetName = "shield",
    }, "/cast Shield Bash"):find("/equipset [nocombat] Shield", 1, true) ~= nil,
    "case-insensitive loadout reconnection did not use the native canonical name")
local reconnectedOptions = equipment.GetOptions("shield")
assert(#reconnectedOptions == 2 and reconnectedOptions[2].key == "shield",
    "case-insensitive loadout reconnection was incorrectly marked missing")
sets[7].name = " Shield "
assert(equipment.Resolve(" Shield ") ~= nil,
    "native leading or trailing whitespace made a loadout impossible to resolve")
sets[7].name = "Shield"
assert(equipment.Compose({ equipmentSetName = "Missing" }, "/cast Heal") == "/cast Heal",
    "missing loadout blocked the original action")
assert(equipment.ComposeRuntime({
        equipmentSetName = "Shield",
    }, string.rep("x", 240)) == string.rep("x", 240),
    "an externally oversized loadout prefix did not fall back to the original action")

local attached = { macroText = "/cast Heal" }
assert(equipment.SetEntryLoadout(attached, "Shield")
        and attached.equipmentSetName == "Shield",
    "explicit action loadout was not stored")
assert(equipment.SetEntryLoadout(attached, equipment.NONE_KEY)
        and attached.equipmentSetName == nil,
    "No loadout did not restore the default action")

local tooLong = { macroText = string.rep("x", 240) }
local lengthOk = equipment.SetEntryLoadout(tooLong, "Shield")
assert(not lengthOk and tooLong.equipmentSetName == nil,
    "combined runtime byte limit was not enforced transactionally")

local updateProfiles = { { payload = { actions = { shortcuts = {
    { equipmentSetName = "Shield", macroText = string.rep("x", 220) },
} } } } }
local updateOk = equipment.ValidateReferenceUpdate(updateProfiles, "Shield", {
    [16] = true, [17] = true, [18] = true,
})
assert(not updateOk, "updating native weapon items could bypass the runtime byte limit")

local included = {}
for _, slot in ipairs(equipment.SLOTS) do included[slot.id] = true end
included[4] = false
assert(equipment.Create("Healing", included, nil, 130016),
    "capturing current equipment failed")
assert(table.concat(calls, ","):find("ignore:4")
        and table.concat(calls, ","):find("create:Healing:130016"),
    "capturing current gear did not stage ignored slots")
assert(next(ignoredForSave) == nil, "ignored-slot staging leaked after capture")

assert(equipment.Update(7, included, nil, 130017), "native loadout update failed")
assert(table.concat(calls, ","):find("save:7:130017"),
    "native loadout update did not save the selected icon")
assert(equipment.Equip(7), "native loadout equip failed")
assert(equipment.Rename(7, "Tank"), "native loadout rename failed")
assert(equipment.Delete(7), "native loadout delete failed")

print("PASS native equipment loadouts")
