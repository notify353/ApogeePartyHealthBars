ApogeePartyHealthBars_TargetEffectData = nil
dofile("Reminders/TargetEffects/TargetEffectData.lua")

local Data = ApogeePartyHealthBars_TargetEffectData

local expected = {
    WARRIOR = { "battleShout", "demoralizingShout", "thunderClap", "sunderArmor", "disarm" },
    DRUID = { "demoralizingRoar", "faerieFire", "faerieFireFeral" },
    HUNTER = { "huntersMark", "scorpidSting" },
    ROGUE = { "exposeArmor" },
    WARLOCK = {
        "curseOfWeakness", "curseOfRecklessness", "curseOfElements",
        "curseOfShadow", "curseOfTongues",
    },
    PALADIN = {
        "judgementOfLight", "judgementOfWisdom",
        "judgementOfCrusader", "judgementOfJustice",
    },
    SHAMAN = { "stormstrike" },
}

for classToken, keys in pairs(expected) do
    local forClass = {}
    for _, definition in ipairs(Data.ForClass(classToken)) do
        forClass[definition.key] = definition
    end
    for _, key in ipairs(keys) do
        local definition = forClass[key]
        assert(definition and definition.maintainedDebuff
                and definition.ownerPolicy == "any"
                and #definition.castIds > 0 and #definition.auraIds > 0,
            classToken .. " maintained-debuff catalog is missing " .. key)
    end
end

local attackPower = Data.GetCoverageGroup("attackPowerReduction")
local attackPowerKeys = {}
for _, definition in ipairs(attackPower) do attackPowerKeys[definition.key] = true end
assert(#attackPower == 3 and attackPowerKeys.demoralizingShout
        and attackPowerKeys.demoralizingRoar and attackPowerKeys.curseOfWeakness,
    "attack-power-reduction equivalents are incomplete")

assert(#Data.GetCoverageGroup("majorArmorReduction") == 0
        and not Data.Get("sunderArmor").coverageGroup
        and not Data.Get("exposeArmor").coverageGroup
        and not Data.Get("faerieFire").coverageGroup
        and not Data.Get("curseOfRecklessness").coverageGroup,
    "armor debuffs with stacking or unobservable strength were treated as substitutes")

for _, key in ipairs(expected.PALADIN) do
    assert(Data.Get(key).actionSpellId == 20271
            and Data.Get(key).exclusiveGroup == "judgement"
            and next(Data.Get(key).requiredPlayerAuraIdSet),
        key .. " did not require its active seal with the generic Judgement action")
end

assert(Data.Get("curseOfWeakness").exclusiveGroup == "curse"
        and Data.Get("faerieFire").exclusiveGroup == "faerieFire"
        and Data.Get("faerieFireFeral").exclusiveGroup == "faerieFire",
    "maintained alternatives are missing exclusive selection groups")
assert(Data.Get("demoralizingShout").casterCentered
        and Data.Get("thunderClap").casterCentered
        and Data.Get("demoralizingRoar").casterCentered,
    "caster-centered debuffs require target-independent range handling")
assert(Data.Get("battleShout").auraUnit == "player"
        and Data.Get("battleShout").casterCentered,
    "Battle Shout must track the player's helpful aura without a hostile target")
local disarm = Data.Get("disarm")
assert(disarm.castIds[1] == 676 and #disarm.castIds == 1
        and disarm.auraIds[1] == 676 and #disarm.auraIds == 1
        and disarm.ownerPolicy == "any"
        and disarm.defaultPriority > Data.Get("sunderArmor").defaultPriority,
    "Disarm did not use its cast/aura ID or follow existing Warrior maintained effects")

local threatSlotRepresentatives = {
    WARRIOR = { 7386, 1160, 6343, 772 },
    DRUID = { 770, 99, 33745, 8921 },
    HUNTER = { 1130, 1978, 3043, 19386 },
    MAGE = { 11366 },
    PALADIN = { 20185 },
    PRIEST = { 589, 2944, 14914 },
    ROGUE = { 8647, 1943, 703 },
    SHAMAN = { 17364, 8050 },
    WARLOCK = { 980, 172, 348, 18265 },
}
for classToken, spellIds in pairs(threatSlotRepresentatives) do
    assert(Data.GetThreatDebuffSlotCount(classToken) == #spellIds,
        classToken .. " Threat Control reserved-column count changed")
    for slot, spellId in ipairs(spellIds) do
        assert(Data.GetThreatDebuffSlot(classToken, spellId) == slot,
            classToken .. " Threat Control debuff column changed at " .. slot)
    end
end
assert(Data.GetThreatDebuffSlot("WARRIOR", 25225) == 1,
    "Warrior Sunder Armor ranks did not share the first Threat Control column")
assert(Data.GetThreatDebuffSlot("DRUID", 770) == 1
        and Data.GetThreatDebuffSlot("DRUID", 16857) == 1
        and Data.GetThreatDebuffSlot("WARLOCK", 702) == 1
        and Data.GetThreatDebuffSlot("WARLOCK", 1490) == 1
        and Data.GetThreatDebuffSlot("PALADIN", 20185) == 1
        and Data.GetThreatDebuffSlot("PALADIN", 20186) == 1,
    "Threat Control mutually exclusive debuff variants did not share a column")
for classToken in pairs(threatSlotRepresentatives) do
    assert(Data.GetThreatDebuffSlotCount(classToken) <= 4,
        classToken .. " reserves more than four Threat Control debuff columns")
end
assert(Data.GetThreatDebuffSlot("WARRIOR", 999999) == nil
        and Data.GetThreatDebuffSlotCount("UNKNOWN") == 0,
    "unknown Threat Control debuffs or classes received reserved columns")

print("PASS maintained DoT and debuff catalog")
