-- Reviewed class and pet cooldown families for the passive Threat Control lane.
ApogeePartyHealthBars_CooldownData = {}
local D = ApogeePartyHealthBars_CooldownData

local function Def(classToken, key, canonical, category, priority, defaultEnabled, sourceBook)
    return {
        classToken = classToken,
        key = key,
        canonical = canonical,
        pattern = "^" .. canonical:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "$",
        category = category,
        defaultPriority = priority,
        defaultEnabled = defaultEnabled == true,
        sourceBook = sourceBook,
    }
end

D.MAX_SELECTED = 6
D.DEFINITIONS = {
    -- Druid
    Def("DRUID", "feralCharge", "Feral Charge", "interrupt", 1, true),
    Def("DRUID", "barkskin", "Barkskin", "defense", 2, true),
    Def("DRUID", "naturesSwiftness", "Nature's Swiftness", "defense", 3, true),
    Def("DRUID", "challengingRoar", "Challenging Roar", "threat", 4, true),
    Def("DRUID", "bash", "Bash", "control", 5, true),
    Def("DRUID", "frenziedRegeneration", "Frenzied Regeneration", "defense", 6, true),
    Def("DRUID", "innervate", "Innervate", "utility", 20, false),
    Def("DRUID", "rebirth", "Rebirth", "utility", 21, false),

    -- Hunter
    Def("HUNTER", "silencingShot", "Silencing Shot", "interrupt", 1, true),
    Def("HUNTER", "intimidation", "Intimidation", "control", 2, true),
    Def("HUNTER", "deterrence", "Deterrence", "defense", 3, true),
    Def("HUNTER", "feignDeath", "Feign Death", "threat", 4, true),
    Def("HUNTER", "freezingTrap", "Freezing Trap", "control", 5, true),
    Def("HUNTER", "scatterShot", "Scatter Shot", "control", 6, true),
    Def("HUNTER", "bestialWrath", "Bestial Wrath", "offense", 20, false),
    Def("HUNTER", "rapidFire", "Rapid Fire", "offense", 21, false),

    -- Mage
    Def("MAGE", "counterspell", "Counterspell", "interrupt", 1, true),
    Def("MAGE", "iceBlock", "Ice Block", "defense", 2, true),
    Def("MAGE", "coldSnap", "Cold Snap", "defense", 3, true),
    Def("MAGE", "frostNova", "Frost Nova", "control", 4, true),
    Def("MAGE", "dragonsBreath", "Dragon's Breath", "control", 5, true),
    Def("MAGE", "blastWave", "Blast Wave", "control", 6, true),
    Def("MAGE", "presenceOfMind", "Presence of Mind", "offense", 20, false),
    Def("MAGE", "combustion", "Combustion", "offense", 21, false),
    Def("MAGE", "evocation", "Evocation", "utility", 22, false),

    -- Paladin
    Def("PALADIN", "hammerOfJustice", "Hammer of Justice", "control", 1, true),
    Def("PALADIN", "divineShield", "Divine Shield", "defense", 2, true),
    Def("PALADIN", "blessingOfProtection", "Blessing of Protection", "defense", 3, true),
    Def("PALADIN", "layOnHands", "Lay on Hands", "defense", 4, true),
    Def("PALADIN", "righteousDefense", "Righteous Defense", "threat", 5, true),
    Def("PALADIN", "divineProtection", "Divine Protection", "defense", 6, true),
    Def("PALADIN", "divineFavor", "Divine Favor", "utility", 20, false),
    Def("PALADIN", "avengingWrath", "Avenging Wrath", "offense", 21, false),

    -- Priest
    Def("PRIEST", "silence", "Silence", "interrupt", 1, true),
    Def("PRIEST", "painSuppression", "Pain Suppression", "defense", 2, true),
    Def("PRIEST", "desperatePrayer", "Desperate Prayer", "defense", 3, true),
    Def("PRIEST", "psychicScream", "Psychic Scream", "control", 4, true),
    Def("PRIEST", "fearWard", "Fear Ward", "defense", 5, true),
    Def("PRIEST", "innerFocus", "Inner Focus", "utility", 6, true),
    Def("PRIEST", "powerInfusion", "Power Infusion", "offense", 20, false),

    -- Rogue
    Def("ROGUE", "kick", "Kick", "interrupt", 1, true),
    Def("ROGUE", "vanish", "Vanish", "threat", 2, true),
    Def("ROGUE", "evasion", "Evasion", "defense", 3, true),
    Def("ROGUE", "cloakOfShadows", "Cloak of Shadows", "defense", 4, true),
    Def("ROGUE", "blind", "Blind", "control", 5, true),
    Def("ROGUE", "gouge", "Gouge", "control", 6, true),
    Def("ROGUE", "sprint", "Sprint", "mobility", 20, false),
    Def("ROGUE", "adrenalineRush", "Adrenaline Rush", "offense", 21, false),
    Def("ROGUE", "preparation", "Preparation", "utility", 22, false),

    -- Shaman
    Def("SHAMAN", "earthShock", "Earth Shock", "interrupt", 1, true),
    Def("SHAMAN", "naturesSwiftnessShaman", "Nature's Swiftness", "defense", 2, true),
    Def("SHAMAN", "groundingTotem", "Grounding Totem", "defense", 3, true),
    Def("SHAMAN", "stoneclawTotem", "Stoneclaw Totem", "defense", 4, true),
    Def("SHAMAN", "earthbindTotem", "Earthbind Totem", "control", 5, true),
    Def("SHAMAN", "shamanisticRage", "Shamanistic Rage", "defense", 6, true),
    Def("SHAMAN", "manaTideTotem", "Mana Tide Totem", "utility", 20, false),
    Def("SHAMAN", "elementalMastery", "Elemental Mastery", "offense", 21, false),
    Def("SHAMAN", "bloodlust", "Bloodlust", "offense", 22, false),
    Def("SHAMAN", "heroism", "Heroism", "offense", 23, false),

    -- Warlock
    Def("WARLOCK", "spellLock", "Spell Lock", "interrupt", 1, true, "pet"),
    Def("WARLOCK", "deathCoil", "Death Coil", "control", 2, true),
    Def("WARLOCK", "shadowfury", "Shadowfury", "control", 3, true),
    Def("WARLOCK", "howlOfTerror", "Howl of Terror", "control", 4, true),
    Def("WARLOCK", "sacrifice", "Sacrifice", "defense", 5, true, "pet"),
    Def("WARLOCK", "felDomination", "Fel Domination", "defense", 6, true),
    Def("WARLOCK", "amplifyCurse", "Amplify Curse", "utility", 20, false),
    Def("WARLOCK", "inferno", "Inferno", "control", 21, false),

    -- Warrior
    Def("WARRIOR", "pummel", "Pummel", "interrupt", 1, true),
    Def("WARRIOR", "shieldBash", "Shield Bash", "interrupt", 2, true),
    Def("WARRIOR", "shieldWall", "Shield Wall", "defense", 3, true),
    Def("WARRIOR", "lastStand", "Last Stand", "defense", 4, true),
    Def("WARRIOR", "taunt", "Taunt", "threat", 5, true),
    Def("WARRIOR", "challengingShout", "Challenging Shout", "threat", 6, true),
    Def("WARRIOR", "mockingBlow", "Mocking Blow", "threat", 20, false),
    Def("WARRIOR", "intimidatingShout", "Intimidating Shout", "control", 21, false),
    Def("WARRIOR", "retaliation", "Retaliation", "offense", 22, false),
    Def("WARRIOR", "recklessness", "Recklessness", "offense", 23, false),
}

function D.ForClass(classToken)
    local result = {}
    for _, definition in ipairs(D.DEFINITIONS) do
        if definition.classToken == classToken then result[#result + 1] = definition end
    end
    return result
end
