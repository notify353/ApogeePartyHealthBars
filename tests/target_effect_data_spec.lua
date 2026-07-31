ApogeePartyHealthBars_TargetEffectData = nil
dofile("Reminders/TargetEffects/TargetEffectData.lua")

local Data = ApogeePartyHealthBars_TargetEffectData

local expected = {
    WARRIOR = { "battleShout", "demoralizingShout", "thunderClap", "sunderArmor" },
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

print("PASS maintained DoT and debuff catalog")
