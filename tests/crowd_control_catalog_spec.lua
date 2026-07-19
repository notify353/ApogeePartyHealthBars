dofile("ApogeePartyHealthBars_CrowdControl.lua")
local CC = ApogeePartyHealthBars_CrowdControl

-- This expectation is deliberately independent of CC.DEFINITIONS so deleting a
-- class or spell fails instead of shrinking both the input and expected count.
local expectedByClass = {
    DRUID = {
        "Hibernate", "Cyclone", "Entangling Roots", "Bash", "Maim", "Pounce",
        "Feral Charge", "Nature's Grasp",
    },
    HUNTER = {
        "Freezing Trap", "Scare Beast", "Wyvern Sting", "Scatter Shot", "Intimidation",
        "Counterattack", "Frost Trap", "Concussive Shot", "Wing Clip", "Silencing Shot",
    },
    MAGE = {
        "Polymorph", "Frost Nova", "Dragon's Breath", "Freeze", "Blast Wave",
        "Cone of Cold", "Slow", "Counterspell",
    },
    PALADIN = { "Repentance", "Turn Evil", "Hammer of Justice", "Avenger's Shield" },
    PRIEST = { "Shackle Undead", "Mind Control", "Psychic Scream", "Silence" },
    ROGUE = {
        "Sap", "Blind", "Gouge", "Cheap Shot", "Kidney Shot", "Garrote", "Kick", "Riposte",
    },
    SHAMAN = { "Earthbind Totem", "Frost Shock", "Earth Shock" },
    WARLOCK = {
        "Banish", "Fear", "Seduction", "Enslave Demon", "Howl of Terror", "Death Coil",
        "Shadowfury", "Inferno", "Curse of Exhaustion", "Spell Lock", "Intercept",
    },
    WARRIOR = {
        "Intimidating Shout", "Concussion Blow", "Charge", "Intercept", "Hamstring",
        "Piercing Howl", "Disarm", "Pummel", "Shield Bash",
    },
}

local configuredOnly = {
    HUNTER = { ["Frost Trap"] = true, ["Concussive Shot"] = true, ["Wing Clip"] = true },
    MAGE = { ["Blast Wave"] = true, ["Cone of Cold"] = true, Slow = true },
    PALADIN = { ["Avenger's Shield"] = true },
    ROGUE = { Riposte = true },
    SHAMAN = { ["Frost Shock"] = true },
    WARLOCK = { ["Curse of Exhaustion"] = true },
    WARRIOR = { Hamstring = true, ["Piercing Howl"] = true, Disarm = true },
}

local expectedInterrupts = {
    DRUID = { ["Feral Charge"] = true },
    HUNTER = { ["Silencing Shot"] = true },
    MAGE = { Counterspell = true },
    PRIEST = { Silence = true },
    ROGUE = { Garrote = true, Kick = true },
    SHAMAN = { ["Earth Shock"] = true },
    WARLOCK = { ["Spell Lock"] = true },
    WARRIOR = { Pummel = true, ["Shield Bash"] = true },
}

local nonTargetActivation = {
    ["DRUID:Nature's Grasp"] = CC.ACTIVATION.SELF,
    ["HUNTER:Freezing Trap"] = CC.ACTIVATION.TRAP,
    ["HUNTER:Frost Trap"] = CC.ACTIVATION.TRAP,
    ["MAGE:Frost Nova"] = CC.ACTIVATION.SELF_AOE,
    ["MAGE:Dragon's Breath"] = CC.ACTIVATION.SELF_AOE,
    ["MAGE:Freeze"] = CC.ACTIVATION.GROUND,
    ["MAGE:Blast Wave"] = CC.ACTIVATION.SELF_AOE,
    ["MAGE:Cone of Cold"] = CC.ACTIVATION.SELF_AOE,
    ["PRIEST:Psychic Scream"] = CC.ACTIVATION.SELF_AOE,
    ["SHAMAN:Earthbind Totem"] = CC.ACTIVATION.TOTEM,
    ["WARLOCK:Seduction"] = CC.ACTIVATION.PET_TARGET,
    ["WARLOCK:Howl of Terror"] = CC.ACTIVATION.SELF_AOE,
    ["WARLOCK:Shadowfury"] = CC.ACTIVATION.GROUND,
    ["WARLOCK:Inferno"] = CC.ACTIVATION.GROUND,
    ["WARLOCK:Spell Lock"] = CC.ACTIVATION.PET_TARGET,
    ["WARLOCK:Intercept"] = CC.ACTIVATION.PET_TARGET,
    ["WARRIOR:Intimidating Shout"] = CC.ACTIVATION.SELF_AOE,
    ["WARRIOR:Piercing Howl"] = CC.ACTIVATION.SELF_AOE,
}

local expectedPetSpells = {
    ["MAGE:Freeze"] = true,
    ["WARLOCK:Seduction"] = true,
    ["WARLOCK:Spell Lock"] = true,
    ["WARLOCK:Intercept"] = true,
}

local validActivation = {}
for _, value in pairs(CC.ACTIVATION) do validActivation[value] = true end
local validControl = {}
for _, value in pairs(CC.CONTROL) do validControl[value] = true end

local seen = {}
for classToken, expected in pairs(expectedByClass) do
    local definitions = CC.GetDefinitions(classToken)
    assert(#definitions == #expected,
        classToken .. " CC count changed: expected " .. #expected .. ", got " .. #definitions)
    for index, canonical in ipairs(expected) do
        local definition = definitions[index]
        assert(definition.canonical == canonical,
            classToken .. " CC order changed at " .. index .. ": " .. tostring(definition.canonical))
        assert(validActivation[definition.activation], canonical .. " has invalid activation mode")
        assert(validControl[definition.control], canonical .. " has invalid control category")
        assert(type(definition.identitySpellIds) == "table" and #definition.identitySpellIds > 0,
            canonical .. " has no identity spell ID")
        local shouldBeAutomatic = not (configuredOnly[classToken]
            and configuredOnly[classToken][canonical])
        assert(CC.IsAutomatic(definition) == shouldBeAutomatic,
            canonical .. " has the wrong automatic policy")
        local shouldInterrupt = expectedInterrupts[classToken]
            and expectedInterrupts[classToken][canonical] == true
        assert(CC.HasCapability(definition, CC.CONTROL.INTERRUPT) == (shouldInterrupt == true),
            canonical .. " has the wrong interrupt capability")
        local controlLabel = CC.GetControlLabel(definition)
        assert(type(controlLabel) == "string" and controlLabel ~= "",
            canonical .. " has no control label")
        if shouldInterrupt then
            assert(controlLabel:find("Interrupt", 1, true),
                canonical .. " control label omits interrupt capability")
        end
        local key = classToken .. ":" .. canonical
        assert(definition.activation == (nonTargetActivation[key] or CC.ACTIVATION.TARGET),
            canonical .. " has the wrong activation mode")
        assert((definition.sourceBook == "pet") == (expectedPetSpells[key] == true),
            canonical .. " has the wrong spellbook source")
        assert(not seen[key], "duplicate CC definition: " .. key)
        seen[key] = true
    end
end

for _, definition in ipairs(CC.DEFINITIONS) do
    assert(expectedByClass[definition.classToken],
        "CC definition has unsupported class: " .. tostring(definition.classToken))
end

assert(CC.GetMaxAutomaticCount() == 10, "maximum automatic CC allocation changed")
local feralCharge = CC.GetDefinitions("DRUID")[7]
assert(feralCharge.control == CC.CONTROL.ROOT
        and CC.GetControlLabel(feralCharge) == "Root / Interrupt",
    "hybrid interrupt labeling changed")
assert(CC.UsesCurrentTarget(CC.GetDefinitions("PALADIN")[3]),
    "Hammer of Justice should use current-target prediction")
assert(not CC.UsesCurrentTarget(CC.GetDefinitions("PRIEST")[3]),
    "Psychic Scream should not require a current target")

print("PASS structured per-class crowd-control catalog")
