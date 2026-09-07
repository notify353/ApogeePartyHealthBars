local function handsOnlyIgnored()
    local ignored = {}
    for slot = 1, 19 do ignored[slot] = slot ~= 16 and slot ~= 17 end
    return ignored
end

local sets = {
    [7] = {
        name = "Shield",
        icon = 132110,
        ignored = handsOnlyIgnored(),
        numItems = 2,
        numEquipped = 1,
        numLost = 1,
    },
    [8] = {
        name = "Raid Gear",
        icon = 132111,
        ignored = {},
        numItems = 19,
        numEquipped = 19,
        numLost = 0,
    },
}
local ignoredForSave, calls = {}, {}
local inCombat, locked = false, false
local inventoryTextures = { [16] = 130016, [17] = 130017 }
local scheduled = {}

local function copyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

C_Timer = {
    After = function(_, callback) scheduled[#scheduled + 1] = callback end,
}

ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(key) return key == "weaponSets" end,
    GetFeatureReason = function() return nil end,
}
InCombatLockdown = function() return inCombat end
GetInventoryItemTexture = function(_, slot) return inventoryTextures[slot] end
MAX_EQUIPMENT_SETS_PER_PLAYER = 10
C_EquipmentSet = {
    CanUseEquipmentSets = function() return true end,
    GetEquipmentSetIDs = function()
        local ids = { 7, 8 }
        if sets[9] then ids[#ids + 1] = 9 end
        return ids
    end,
    GetNumEquipmentSets = function() return sets[9] and 3 or 2 end,
    GetEquipmentSetInfo = function(id)
        local set = sets[id]
        return set.name, set.icon, id, false, set.numItems, set.numEquipped,
            set.numItems - set.numLost, set.numLost, 0
    end,
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
        -- Reproduce the client behavior that exposed the original bug: the
        -- set becomes visible before ignored-slot staging is consumed.
        sets[9] = {
            name = name, icon = icon, ignored = {}, numItems = 19,
            numEquipped = 19, numLost = 0,
        }
        calls[#calls + 1] = "create:" .. name .. ":" .. tostring(icon)
    end,
    SaveEquipmentSet = function(id, icon)
        sets[id].ignored = copyTable(ignoredForSave)
        sets[id].icon = icon
        sets[id].numItems = 2
        calls[#calls + 1] = "save:" .. id .. ":" .. tostring(icon)
    end,
    DeleteEquipmentSet = function(id) calls[#calls + 1] = "delete:" .. id end,
    UseEquipmentSet = function(id)
        calls[#calls + 1] = "equip:" .. id
        return true
    end,
    EquipmentSetContainsLockedItems = function() return locked end,
}

dofile("Actions/WeaponSets.lua")
local weapons = ApogeePartyHealthBars_WeaponSets

assert(weapons.IsSupported(), "native weapon-set capability was not exposed")
assert(weapons.GetAutomaticIcon() == 130016,
    "automatic weapon-set icon did not prefer Main Hand")
inventoryTextures[16] = nil
assert(weapons.GetAutomaticIcon() == 130017,
    "automatic weapon-set icon did not fall back to Off Hand")
inventoryTextures[17] = nil
assert(weapons.GetAutomaticIcon() == "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP",
    "automatic weapon-set icon did not fall back to the generic icon")
inventoryTextures[16] = 130016
inventoryTextures[17] = 130017

local listed = weapons.List()
assert(#listed == 1 and listed[1].name == "Shield" and listed[1].numLost == 1,
    "non-hand native equipment sets were not filtered out")
assert(weapons.Resolve(" shield ") == nil and weapons.Resolve("shield") ~= nil,
    "weapon-set name resolution did not preserve the supported normalization policy")
local options = weapons.GetOptions("Missing")
assert(options[1].label == "No weapon set"
        and options[#options].label == "Missing (unavailable)",
    "weapon-set options did not expose the expected empty and unavailable states")

local entry = {
    kind = "spell",
    spellName = "Shield Bash",
    macroText = "/cast Shield Bash",
    weaponSetName = "Shield",
}
assert(weapons.Compose(entry, entry.macroText)
        == "/equipset Shield\n/cast Shield Bash",
    "weapon set was not composed as one unconditional secure prefix")
assert(not weapons.Compose(entry, entry.macroText):find("equipslot", 1, true),
    "weapon macro unexpectedly emitted slot-specific equipment commands")

sets[7].ignored[18] = false
assert(weapons.Resolve("Shield") == nil
        and weapons.Compose(entry, entry.macroText) == entry.macroText,
    "an externally broadened equipment set was allowed to swap through an action")
sets[7].ignored[18] = true

local attached = { macroText = "/cast Heal" }
assert(weapons.SetEntryWeaponSet(attached, "Shield")
        and attached.weaponSetName == "Shield",
    "explicit action weapon set was not stored")
assert(weapons.SetEntryWeaponSet(attached, weapons.NONE_KEY)
        and attached.weaponSetName == nil,
    "No weapon set did not restore the default action")

local tooLong = { macroText = string.rep("x", 240) }
local lengthOk = weapons.SetEntryWeaponSet(tooLong, "Shield")
assert(not lengthOk and tooLong.weaponSetName == nil,
    "combined weapon-set runtime byte limit was not enforced transactionally")
assert(weapons.ComposeRuntime({ weaponSetName = "Shield" }, string.rep("x", 250))
        == string.rep("x", 250),
    "an oversized weapon-set prefix did not fall back to the original action")

assert(not weapons.ValidateName("Raid Gear"),
    "a hidden native equipment set name was incorrectly available for reuse")
assert(weapons.Convert(8) and weapons.Resolve("Raid Gear") ~= nil,
    "explicit conversion did not recover an incompatible native set")
table.remove(scheduled, 1)()
assert(weapons.Create("Healing"), "capturing equipped weapons failed")
local callText = table.concat(calls, ",")
assert(callText:find("ignore:18", 1, true)
        and not ignoredForSave[16] and not ignoredForSave[17]
        and callText:find("create:Healing:130016", 1, true),
    "capture did not stage exactly Main Hand and Off Hand with an automatic icon")
assert(weapons.Resolve("Healing") == nil and #scheduled == 1,
    "newly published incompatible set did not wait for native finalization")
table.remove(scheduled, 1)()
assert(weapons.Resolve("Healing") ~= nil,
    "newly created set was not repaired after native finalization")
table.remove(scheduled, 1)()
assert(next(ignoredForSave) == nil, "ignored-slot staging leaked after capture")

assert(weapons.Update(7), "weapon-set update failed")
assert(table.concat(calls, ","):find("save:7:130016", 1, true),
    "weapon-set update did not use the automatic icon")
table.remove(scheduled, 1)()
assert(weapons.Equip(7), "weapon-set equip failed")
locked = true
assert(not weapons.Update(7), "a locked weapon set was updated")
locked = false
inCombat = true
assert(not weapons.Create("Combat") and not weapons.Equip(7),
    "weapon-set management was allowed during combat")
inCombat = false
assert(weapons.Delete(7), "weapon-set deletion failed")

print("PASS native Main Hand and Off Hand weapon sets")
