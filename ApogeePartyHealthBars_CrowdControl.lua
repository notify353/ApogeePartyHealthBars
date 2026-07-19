-- Structured crowd-control catalog and spell-family recognition.
ApogeePartyHealthBars_CrowdControl = {}
local CC = ApogeePartyHealthBars_CrowdControl

CC.ACTIVATION = {
    TARGET = "target",
    SELF = "self",
    SELF_AOE = "selfAoE",
    TRAP = "trap",
    TOTEM = "totem",
    GROUND = "ground",
    PET_TARGET = "petTarget",
}

CC.CONTROL = {
    HARD = "hard",
    STUN = "stun",
    ROOT = "root",
    MOVEMENT = "movement",
    INTERRUPT = "interrupt",
    DISARM = "disarm",
}

local A = CC.ACTIVATION
local K = CC.CONTROL

-- `automatic` controls the compact target utility lane. Strategic hard control,
-- stuns, roots, interrupts, and silences appear automatically; movement control
-- and disarms are recognized when configured without crowding every character's UI.
CC.DEFINITIONS = {
    -- Druid
    { classToken = "DRUID", canonical = "Hibernate", pattern = "^Hibernate$", identitySpellIds = { 2637 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Beast = true, Dragonkin = true }, creatureLabel = "a Beast or Dragonkin" },
    { classToken = "DRUID", canonical = "Cyclone", pattern = "^Cyclone$", identitySpellIds = { 33786 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "DRUID", canonical = "Entangling Roots", pattern = "^Entangling Roots$", identitySpellIds = { 339 }, control = K.ROOT, activation = A.TARGET, automatic = true },
    { classToken = "DRUID", canonical = "Bash", pattern = "^Bash$", identitySpellIds = { 5211 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "DRUID", canonical = "Maim", pattern = "^Maim$", identitySpellIds = { 22570 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "DRUID", canonical = "Pounce", pattern = "^Pounce$", identitySpellIds = { 9005 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "DRUID", canonical = "Feral Charge", pattern = "^Feral Charge", identitySpellIds = { 16979 }, control = K.ROOT, capabilities = { [K.INTERRUPT] = true }, activation = A.TARGET, automatic = true },
    { classToken = "DRUID", canonical = "Nature's Grasp", pattern = "^Nature's Grasp$", identitySpellIds = { 16689 }, control = K.ROOT, activation = A.SELF, automatic = true },

    -- Hunter
    { classToken = "HUNTER", canonical = "Freezing Trap", pattern = "^Freezing Trap$", identitySpellIds = { 1499 }, control = K.HARD, activation = A.TRAP, automatic = true },
    { classToken = "HUNTER", canonical = "Scare Beast", pattern = "^Scare Beast$", identitySpellIds = { 1513 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Beast = true }, creatureLabel = "a Beast" },
    { classToken = "HUNTER", canonical = "Wyvern Sting", pattern = "^Wyvern Sting$", identitySpellIds = { 19386 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "HUNTER", canonical = "Scatter Shot", pattern = "^Scatter Shot$", identitySpellIds = { 19503 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "HUNTER", canonical = "Intimidation", pattern = "^Intimidation$", identitySpellIds = { 19577 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "HUNTER", canonical = "Counterattack", pattern = "^Counterattack$", identitySpellIds = { 19306 }, control = K.ROOT, activation = A.TARGET, automatic = true },
    { classToken = "HUNTER", canonical = "Frost Trap", pattern = "^Frost Trap$", identitySpellIds = { 13809 }, control = K.MOVEMENT, activation = A.TRAP },
    { classToken = "HUNTER", canonical = "Concussive Shot", pattern = "^Concussive Shot$", identitySpellIds = { 5116 }, control = K.MOVEMENT, activation = A.TARGET },
    { classToken = "HUNTER", canonical = "Wing Clip", pattern = "^Wing Clip$", identitySpellIds = { 2974 }, control = K.MOVEMENT, activation = A.TARGET },
    { classToken = "HUNTER", canonical = "Silencing Shot", pattern = "^Silencing Shot$", identitySpellIds = { 34490 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },

    -- Mage
    { classToken = "MAGE", canonical = "Polymorph", pattern = "^Polymorph", identitySpellIds = { 118, 28271, 28272 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Beast = true, Humanoid = true, Critter = true }, creatureLabel = "a Beast, Humanoid, or Critter" },
    { classToken = "MAGE", canonical = "Frost Nova", pattern = "^Frost Nova$", identitySpellIds = { 122 }, control = K.ROOT, activation = A.SELF_AOE, automatic = true },
    { classToken = "MAGE", canonical = "Dragon's Breath", pattern = "^Dragon's Breath$", identitySpellIds = { 31661 }, control = K.HARD, activation = A.SELF_AOE, automatic = true },
    { classToken = "MAGE", canonical = "Freeze", pattern = "^Freeze$", identitySpellIds = { 33395 }, control = K.ROOT, activation = A.GROUND, sourceBook = "pet", automatic = true },
    { classToken = "MAGE", canonical = "Blast Wave", pattern = "^Blast Wave$", identitySpellIds = { 11113 }, control = K.MOVEMENT, activation = A.SELF_AOE },
    { classToken = "MAGE", canonical = "Cone of Cold", pattern = "^Cone of Cold$", identitySpellIds = { 120 }, control = K.MOVEMENT, activation = A.SELF_AOE },
    { classToken = "MAGE", canonical = "Slow", pattern = "^Slow$", identitySpellIds = { 31589 }, control = K.MOVEMENT, activation = A.TARGET },
    { classToken = "MAGE", canonical = "Counterspell", pattern = "^Counterspell$", identitySpellIds = { 2139 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },

    -- Paladin
    { classToken = "PALADIN", canonical = "Repentance", pattern = "^Repentance$", identitySpellIds = { 20066 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Humanoid = true }, creatureLabel = "a Humanoid" },
    { classToken = "PALADIN", canonical = "Turn Evil", pattern = "^Turn Evil$", identitySpellIds = { 10326 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Demon = true, Undead = true }, creatureLabel = "a Demon or Undead" },
    { classToken = "PALADIN", canonical = "Hammer of Justice", pattern = "^Hammer of Justice$", identitySpellIds = { 853 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "PALADIN", canonical = "Avenger's Shield", pattern = "^Avenger's Shield$", identitySpellIds = { 31935 }, control = K.MOVEMENT, activation = A.TARGET },

    -- Priest
    { classToken = "PRIEST", canonical = "Shackle Undead", pattern = "^Shackle Undead$", identitySpellIds = { 9484 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Undead = true }, creatureLabel = "an Undead" },
    { classToken = "PRIEST", canonical = "Mind Control", pattern = "^Mind Control$", identitySpellIds = { 605 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Humanoid = true }, creatureLabel = "a Humanoid" },
    { classToken = "PRIEST", canonical = "Psychic Scream", pattern = "^Psychic Scream$", identitySpellIds = { 8122 }, control = K.HARD, activation = A.SELF_AOE, automatic = true },
    { classToken = "PRIEST", canonical = "Silence", pattern = "^Silence$", identitySpellIds = { 15487 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },

    -- Rogue
    { classToken = "ROGUE", canonical = "Sap", pattern = "^Sap$", identitySpellIds = { 6770 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Humanoid = true }, creatureLabel = "a Humanoid", requiresOutOfCombat = true },
    { classToken = "ROGUE", canonical = "Blind", pattern = "^Blind$", identitySpellIds = { 2094 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "ROGUE", canonical = "Gouge", pattern = "^Gouge$", identitySpellIds = { 1776 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "ROGUE", canonical = "Cheap Shot", pattern = "^Cheap Shot$", identitySpellIds = { 1833 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "ROGUE", canonical = "Kidney Shot", pattern = "^Kidney Shot$", identitySpellIds = { 408 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "ROGUE", canonical = "Garrote", pattern = "^Garrote$", identitySpellIds = { 703 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },
    { classToken = "ROGUE", canonical = "Kick", pattern = "^Kick$", identitySpellIds = { 1766 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },
    { classToken = "ROGUE", canonical = "Riposte", pattern = "^Riposte$", identitySpellIds = { 14251 }, control = K.DISARM, activation = A.TARGET },

    -- Shaman
    { classToken = "SHAMAN", canonical = "Earthbind Totem", pattern = "^Earthbind Totem$", identitySpellIds = { 2484 }, control = K.MOVEMENT, activation = A.TOTEM, automatic = true },
    { classToken = "SHAMAN", canonical = "Frost Shock", pattern = "^Frost Shock$", identitySpellIds = { 8056 }, control = K.MOVEMENT, activation = A.TARGET },
    { classToken = "SHAMAN", canonical = "Earth Shock", pattern = "^Earth Shock$", identitySpellIds = { 8042 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },

    -- Warlock
    { classToken = "WARLOCK", canonical = "Banish", pattern = "^Banish$", identitySpellIds = { 710 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Demon = true, Elemental = true }, creatureLabel = "a Demon or Elemental" },
    { classToken = "WARLOCK", canonical = "Fear", pattern = "^Fear$", identitySpellIds = { 5782 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "WARLOCK", canonical = "Seduction", pattern = "^Seduction$", identitySpellIds = { 6358 }, control = K.HARD, activation = A.PET_TARGET, sourceBook = "pet", automatic = true, creatureTypes = { Humanoid = true }, creatureLabel = "a Humanoid" },
    { classToken = "WARLOCK", canonical = "Enslave Demon", pattern = "^Enslave Demon$", identitySpellIds = { 1098 }, control = K.HARD, activation = A.TARGET, automatic = true, creatureTypes = { Demon = true }, creatureLabel = "a Demon" },
    { classToken = "WARLOCK", canonical = "Howl of Terror", pattern = "^Howl of Terror$", identitySpellIds = { 5484 }, control = K.HARD, activation = A.SELF_AOE, automatic = true },
    { classToken = "WARLOCK", canonical = "Death Coil", pattern = "^Death Coil$", identitySpellIds = { 6789 }, control = K.HARD, activation = A.TARGET, automatic = true },
    { classToken = "WARLOCK", canonical = "Shadowfury", pattern = "^Shadowfury$", identitySpellIds = { 30283 }, control = K.STUN, activation = A.GROUND, automatic = true },
    { classToken = "WARLOCK", canonical = "Inferno", pattern = "^Inferno$", identitySpellIds = { 1122 }, control = K.STUN, activation = A.GROUND, automatic = true },
    { classToken = "WARLOCK", canonical = "Curse of Exhaustion", pattern = "^Curse of Exhaustion$", identitySpellIds = { 18223 }, control = K.MOVEMENT, activation = A.TARGET },
    { classToken = "WARLOCK", canonical = "Spell Lock", pattern = "^Spell Lock$", identitySpellIds = { 19244 }, control = K.INTERRUPT, activation = A.PET_TARGET, sourceBook = "pet", automatic = true },
    { classToken = "WARLOCK", canonical = "Intercept", pattern = "^Intercept$", identitySpellIds = { 30151 }, control = K.STUN, activation = A.PET_TARGET, sourceBook = "pet", automatic = true },

    -- Warrior
    { classToken = "WARRIOR", canonical = "Intimidating Shout", pattern = "^Intimidating Shout$", identitySpellIds = { 5246 }, control = K.HARD, activation = A.SELF_AOE, automatic = true },
    { classToken = "WARRIOR", canonical = "Concussion Blow", pattern = "^Concussion Blow$", identitySpellIds = { 12809 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "WARRIOR", canonical = "Charge", pattern = "^Charge$", identitySpellIds = { 100 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "WARRIOR", canonical = "Intercept", pattern = "^Intercept$", identitySpellIds = { 20252 }, control = K.STUN, activation = A.TARGET, automatic = true },
    { classToken = "WARRIOR", canonical = "Hamstring", pattern = "^Hamstring$", identitySpellIds = { 1715 }, control = K.MOVEMENT, activation = A.TARGET },
    { classToken = "WARRIOR", canonical = "Piercing Howl", pattern = "^Piercing Howl$", identitySpellIds = { 12323 }, control = K.MOVEMENT, activation = A.SELF_AOE },
    { classToken = "WARRIOR", canonical = "Disarm", pattern = "^Disarm$", identitySpellIds = { 676 }, control = K.DISARM, activation = A.TARGET },
    { classToken = "WARRIOR", canonical = "Pummel", pattern = "^Pummel$", identitySpellIds = { 6552 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },
    { classToken = "WARRIOR", canonical = "Shield Bash", pattern = "^Shield Bash$", identitySpellIds = { 72 }, control = K.INTERRUPT, activation = A.TARGET, automatic = true },
}

local CONTROL_LABELS = {
    [K.HARD] = "Hard control",
    [K.STUN] = "Stun",
    [K.ROOT] = "Root",
    [K.MOVEMENT] = "Movement control",
    [K.INTERRUPT] = "Interrupt",
    [K.DISARM] = "Disarm",
}

function CC.GetDefinitions(classToken)
    local result = {}
    for _, definition in ipairs(CC.DEFINITIONS) do
        if not classToken or definition.classToken == classToken then
            result[#result + 1] = definition
        end
    end
    return result
end

function CC.UsesCurrentTarget(definition)
    return definition and (definition.activation == A.TARGET or definition.activation == A.PET_TARGET)
end

function CC.IsAutomatic(definition)
    return definition and definition.automatic == true
end

function CC.HasCapability(definition, capability)
    if not definition or not capability then return false end
    return (definition.control == capability
        or (definition.capabilities and definition.capabilities[capability] == true)) == true
end

function CC.GetControlLabel(definition)
    if not definition then return nil end
    local labels = { CONTROL_LABELS[definition.control] or tostring(definition.control) }
    if definition.control ~= K.INTERRUPT and CC.HasCapability(definition, K.INTERRUPT) then
        labels[#labels + 1] = CONTROL_LABELS[K.INTERRUPT]
    end
    return table.concat(labels, " / ")
end

function CC.GetMaxAutomaticCount()
    local counts, maximum = {}, 0
    for _, definition in ipairs(CC.DEFINITIONS) do
        if definition.automatic then
            local classToken = definition.classToken
            counts[classToken] = (counts[classToken] or 0) + 1
            if counts[classToken] > maximum then maximum = counts[classToken] end
        end
    end
    return maximum
end
