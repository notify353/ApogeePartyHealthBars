dofile("Core/Namespace.lua")
dofile("Reminders/GroupHelperData.lua")
dofile("Reminders/GroupHelperPolicy.lua")
local Data = ApogeePartyHealthBars.Require("Runtime", "GroupHelperData")
local Policy = ApogeePartyHealthBars.Require("Runtime", "GroupHelperPolicy")

Data.ConfigureDrinkAuraNames(function(spellId)
    if spellId == 430 then return "Localized Drink" end
end)
Data.ConfigureBuffDefinitions({
    {
        canonical = "Power Word: Fortitude", icon = "fort-icon",
        auraIds = { [1243] = true }, auraNames = { ["Power Word: Fortitude"] = true },
    },
    {
        canonical = "Arcane Intellect", icon = "int-icon",
        auraIds = { [1459] = true }, auraNames = { ["Arcane Intellect"] = true },
    },
    {
        canonical = "Mark of the Wild", icon = "mark-icon",
        auraIds = { [1126] = true }, auraNames = { ["Mark of the Wild"] = true },
    },
    {
        canonical = "Divine Spirit", icon = "spirit-icon",
        auraIds = { [14752] = true }, auraNames = { ["Divine Spirit"] = true },
    },
    {
        canonical = "Blessing of Might", icon = "might-icon",
        auraIds = { [19740] = true }, auraNames = { ["Blessing of Might"] = true },
    },
})

local function unit(guid, name, mana, maximum, auras, classToken)
    return {
        guid = guid, unitId = guid, name = name,
        manaValue = mana, manaMaximum = maximum, auras = auras or {},
        exists = true, alive = true, connected = true, isPlayer = true,
        classToken = classToken,
    }
end

local context = {
    enabled = true, inInstance = true, instanceType = "party", partyCount = 2,
    inCombat = false, auraAvailable = true, sayAvailable = true,
    playerClassToken = "WARRIOR",
}
local units = {
    unit("tank", "Tank", nil, nil, nil, "WARRIOR"),
    unit("healer", "Healer", 100, 100, {
        { spellId = 430, name = "Localized Drink", icon = 135881,
            duration = 30, expirationTime = 41 },
    }, "PRIEST"),
    unit("mage", "Mage", 74.9, 100, nil, "MAGE"),
}

local function findRow(rows, name)
    for _, row in ipairs(rows or {}) do
        if row.name == name then return row end
    end
    return nil
end

local snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(snapshot.visible and snapshot.sayAvailable and #snapshot.manaRows == 2,
    "eligible dungeon snapshot did not expose independent drink and thirsty states")
local healerRow, mageRow = findRow(snapshot.manaRows, "Healer"),
    findRow(snapshot.manaRows, "Mage")
assert(healerRow and healerRow.percent == 100
        and healerRow.drinkState == "detected"
        and healerRow.drinkAuraSpellId == 430
        and healerRow.drinkAuraIcon == 135881
        and healerRow.drinkAuraDuration == 30
        and healerRow.drinkAuraExpirationTime == 41,
    "recognized drink evidence was not shown at full mana")
assert(mageRow and mageRow.percent == 74
        and mageRow.drinkState == "notDetected",
    "mana just below 75% did not show THIRSTY")
assert(#snapshot.buffIssues == 2
        and snapshot.buffIssues[1].key == "fortitude"
        and snapshot.buffIssues[1].providerGuids[1] == "healer"
        and snapshot.buffIssues[1].missingCount == 3
        and table.concat(snapshot.buffIssues[1].missingNames, ",")
            == "Tank,Healer,Mage"
        and snapshot.buffIssues[2].key == "intellect"
        and snapshot.buffIssues[2].providerGuids[1] == "mage"
        and snapshot.buffIssues[2].missingCount == 2
        and table.concat(snapshot.buffIssues[2].missingNames, ",")
            == "Healer,Mage"
        and snapshot.whisperComposerAvailable == nil,
    "cross-class buff coverage did not identify the responsible providers")
local evidenced = Policy.BuildSnapshot(context, units,
    { spirit = { healer = true } }, Data)
assert(#evidenced.buffIssues == 3 and evidenced.buffIssues[3].key == "spirit"
        and evidenced.buffIssues[3].missingCount == 2,
    "observed Divine Spirit capability did not enable its eligible coverage check")
units[1].auras = { { spellId = 1243 } }
units[2].auras[#units[2].auras + 1] = { name = "Power Word: Fortitude" }
units[3].auras = { { spellId = 1243 }, { spellId = 1459 } }
local covered = Policy.BuildSnapshot(context, units, nil, Data)
assert(#covered.buffIssues == 1 and covered.buffIssues[1].key == "intellect"
        and covered.buffIssues[1].missingCount == 1,
    "buff coverage did not honor recognized IDs and names or mana-only recipients")
units[1].auras, units[3].auras = {}, {}
local blessingUnits = {
    unit("blessing-tank", "BlessedTank", nil, nil, {
        { name = "Blessing of Wisdom" },
    }, "WARRIOR"),
    unit("paladin", "Lightkeeper", 100, 100, {
        { name = "Greater Blessing of Sanctuary" },
    }, "PALADIN"),
}
local blessingSnapshot = Policy.BuildSnapshot(context, blessingUnits, nil, Data)
local blessingIssue
for _, issue in ipairs(blessingSnapshot.buffIssues) do
    if issue.key == "blessing" then blessingIssue = issue end
end
assert(not blessingIssue,
    "recognized long-duration Paladin blessings were not treated as equivalent coverage")
assert(Data.FindBuffAura({ auras = { { spellId = 27143 } } }, "blessing")
        and Data.FindBuffAura({ auras = { { spellId = 25895 } } }, "blessing")
        and Data.FindBuffAura({ auras = { { spellId = 27169 } } }, "blessing"),
    "Wisdom, Salvation, or Sanctuary aura IDs were absent from blessing coverage")
blessingUnits[1].auras = {}
blessingSnapshot = Policy.BuildSnapshot(context, blessingUnits, nil, Data)
for _, issue in ipairs(blessingSnapshot.buffIssues) do
    if issue.key == "blessing" then blessingIssue = issue end
end
assert(blessingIssue and blessingIssue.missingCount == 1
        and blessingIssue.missingNames[1] == "BlessedTank",
    "Paladin blessing coverage did not identify only the unblessed member")
local spiritUnits = {
    unit("spirit-priest", "Priest", 100, 100, nil, "PRIEST"),
    unit("spirit-warrior", "Warrior", nil, nil, nil, "WARRIOR"),
    unit("spirit-rogue", "Rogue", nil, nil, nil, "ROGUE"),
    unit("spirit-hunter", "Hunter", 100, 100, nil, "HUNTER"),
    unit("spirit-mage", "Mage", 100, 100, nil, "MAGE"),
    unit("spirit-warlock", "Warlock", 100, 100, nil, "WARLOCK"),
    unit("spirit-paladin", "Paladin", 100, 100, nil, "PALADIN"),
    unit("spirit-shaman", "Shaman", 100, 100, nil, "SHAMAN"),
    unit("spirit-druid", "Druid", 100, 100, nil, "DRUID"),
}
local spiritSnapshot = Policy.BuildSnapshot(context, spiritUnits,
    { spirit = { ["spirit-priest"] = true } }, Data)
local spiritIssue
for _, issue in ipairs(spiritSnapshot.buffIssues) do
    if issue.key == "spirit" then spiritIssue = issue end
end
assert(spiritIssue and spiritIssue.missingCount == 7
        and table.concat(spiritIssue.missingNames, ",")
            == "Priest,Hunter,Mage,Warlock,Paladin,Shaman,Druid",
    "Divine Spirit did not include every mana user or exclude non-mana classes")
assert(Policy.GetThirstyManaPercent() == 75
        and Policy.GetReadyManaPercent == nil,
    "policy did not expose only the renamed 75% thirsty threshold")
assert(Policy.IsTankClass("WARRIOR") and Policy.IsTankClass("PALADIN")
        and Policy.IsTankClass("DRUID") and not Policy.IsTankClass("MAGE")
        and not Policy.IsTankClass("PRIEST") and not Policy.IsTankClass(nil),
    "pull-call eligibility did not match supported tank-capable classes")

units[2].manaValue = 75
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(findRow(snapshot.manaRows, "Healer").drinkState == "detected",
    "recognized drinking aura was hidden at exactly 75% mana")
units[2].manaValue = 19
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(findRow(snapshot.manaRows, "Healer").drinkState == "detected",
    "recognized drinking aura was hidden at low mana")
units[2].manaValue = 100

units[3].manaValue = 75
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(not findRow(snapshot.manaRows, "Mage"),
    "THIRSTY remained visible at exactly 75% mana")
units[3].manaValue = 90
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(not findRow(snapshot.manaRows, "Mage"),
    "THIRSTY remained visible above 75% mana")
units[3].manaValue = 74.9

units[2].auras = { { name = "Localized Drink" } }
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(findRow(snapshot.manaRows, "Healer").drinkState == "detected",
    "localized drink aura name was not recognized")
units[2].auras = { { spellId = 999999, name = "Unknown Drink-like Aura" } }
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(not findRow(snapshot.manaRows, "Healer"),
    "unknown aura was promoted to drinking evidence")

context.auraAvailable, context.auraReason = false, "Aura inspection unavailable."
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(findRow(snapshot.manaRows, "Mage").drinkState == "unavailable"
        and snapshot.auraReason == "Aura inspection unavailable.",
    "aura degradation did not show unavailable status below 75%")
units[3].manaValue = 75
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(#snapshot.manaRows == 0,
    "unavailable status remained visible at exactly 75%")
units[3].manaValue = 74.9
context.auraAvailable = true

units[2].manaValue = 19
units[2].alive = false
assert(not findRow(Policy.BuildSnapshot(context, units, nil, Data).manaRows, "Healer"),
    "dead mana user remained visible")
units[2].alive, units[2].connected = true, false
assert(not findRow(Policy.BuildSnapshot(context, units, nil, Data).manaRows, "Healer"),
    "disconnected mana user remained visible")
units[2].connected, units[2].guid = true, nil
assert(not findRow(Policy.BuildSnapshot(context, units, nil, Data).manaRows, "Healer"),
    "GUID-less mana user exposed unstable row state")
units[2].guid = "healer"

context.inCombat = true
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(snapshot.eligible and not snapshot.visible and not snapshot.pullVisible
        and #snapshot.manaRows == 0,
    "combat did not hide helper state while retaining sidecar eligibility")
context.inCombat, context.instanceType = false, "raid"
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(not snapshot.visible and snapshot.pullVisible,
    "raid exclusion incorrectly hid the independent out-of-combat pull call")
context.instanceType, context.partyCount = "party", 1
assert(Policy.BuildSnapshot(context, units, nil, Data).visible,
    "helper rejected an underfilled dungeon party")
context.partyCount = 0
snapshot = Policy.BuildSnapshot(context, units, nil, Data)
assert(not snapshot.visible and snapshot.pullVisible,
    "solo state hid the independent out-of-combat pull call")
context.playerClassToken = "MAGE"
assert(not Policy.BuildSnapshot(context, units, nil, Data).pullVisible,
    "non-tank class retained the out-of-combat pull call")
context.playerClassToken = "WARRIOR"
context.enabled = false
assert(not Policy.BuildSnapshot(context, units, nil, Data).pullVisible,
    "disabled Group Helper retained its pull call")
print("PASS Group Helper policy")
