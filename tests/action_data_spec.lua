ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(itemId)
        if itemId == 1251 then return "Linen Bandage", 134436, itemId end
    end,
    GetCount = function(itemId) return itemId == 1251 and 4 or 0 end,
}
C_Spell = {
    GetSpellInfo = function(spellId)
        if spellId == 2061 then
            return { name = "Flash Heal", iconID = 135907, spellID = spellId }
        end
    end,
}
function GetSpellInfo(spellId)
    if spellId == 139 then return "Renew", nil, 135953, nil, nil, nil, spellId end
end

dofile("ApogeePartyHealthBars_ActionData.lua")
local actions = ApogeePartyHealthBars_ActionData

local ranked = assert(actions.CreateSpell(2061, "Flash Heal(Rank 7)"))
assert(ranked.kind == "spell" and ranked.spellId == 2061
    and ranked.spellName == "Flash Heal(Rank 7)", "ranked spell identity was not preserved")

local resolved = assert(actions.CreateSpell(139))
assert(resolved.spellName == "Renew", "spell identity was not resolved from its ID")
assert(actions.Normalize("Purify").spellName == "Purify", "legacy string binding was not normalized")
assert(actions.Normalize({ id = 2061, name = "Legacy Flash Heal" }).spellId == 2061,
    "legacy spell table was not normalized")

local item = assert(actions.CreateItem(1251))
assert(item.kind == "item" and item.itemName == "Linen Bandage",
    "item identity was not resolved from its ID")
assert(actions.Normalize({ itemId = 1251, name = "Old Bandage" }).itemName == "Old Bandage",
    "legacy item table was not normalized")

local staleItem = { kind = "item", itemId = 1251, itemName = "Old Bandage" }
local name, icon, itemId, available = actions.ResolveDisplay(staleItem)
assert(name == "Linen Bandage" and icon == 134436 and itemId == 1251 and available,
    "item display identity was not resolved")
assert(staleItem.itemName == "Linen Bandage", "localized item name was not refreshed")

local clone = actions.Clone({
    kind = "spell", spellId = 2061, spellName = "Flash Heal(Rank 7)",
    macroText = "/cast Something Else", soundKey = "toast",
})
assert(clone.kind == "spell" and clone.spellName == "Flash Heal(Rank 7)"
    and clone.macroText == nil and clone.soundKey == nil,
    "action identity clone retained execution-specific fields")
assert(actions.Normalize({}) == nil and actions.CreateItem(0, "Invalid") == nil,
    "invalid action identity was accepted")
assert(actions.Normalize({ kind = "macro", name = "Not a Spell" }) == nil,
    "unknown action kind was interpreted as a spell")

local getInfo, getCount = ApogeePartyHealthBars_ShortcutItems.GetInfo,
    ApogeePartyHealthBars_ShortcutItems.GetCount
ApogeePartyHealthBars_ShortcutItems.GetInfo = nil
ApogeePartyHealthBars_ShortcutItems.GetCount = nil
local cachedItem = assert(actions.CreateItem(1251, "Linen Bandage"))
local cachedName, _, cachedId, cachedAvailable = actions.ResolveDisplay(cachedItem)
assert(cachedName == "Linen Bandage" and cachedId == 1251 and not cachedAvailable,
    "cached item identity depended on optional display helpers")
ApogeePartyHealthBars_ShortcutItems.GetInfo = getInfo
ApogeePartyHealthBars_ShortcutItems.GetCount = getCount

print("PASS shared spell and item action data")
