-- Immutable curated macro content for TBC Anniversary.
ApogeePartyHealthBars_MacroData = {}
local D = ApogeePartyHealthBars_MacroData

D.BRACKETS = { 1, 10, 20, 30, 40, 50, 60, 70 }

local TARGET = "/targetenemy [noexists][dead][help]"
local ATTACK = TARGET .. "\n/startattack"
local function CAST(spellClause)
    return TARGET .. "\n/cast " .. spellClause
end

local classes = {
    DRUID   = { default = 2, builds = { "Balance", "Feral Combat", "Restoration" } },
    HUNTER  = { default = 2, builds = { "Beast Mastery", "Marksmanship", "Survival" } },
    MAGE    = { default = 3, builds = { "Arcane", "Fire", "Frost" } },
    PALADIN = { default = 2, builds = { "Holy", "Protection", "Retribution" } },
    PRIEST  = { default = 3, builds = { "Discipline", "Holy", "Shadow" } },
    ROGUE   = { default = 2, builds = { "Assassination", "Combat", "Subtlety" } },
    SHAMAN  = { default = 2, builds = { "Elemental", "Enhancement", "Restoration" } },
    WARLOCK = { default = 1, builds = { "Affliction", "Demonology", "Destruction" } },
    WARRIOR = { default = 1, builds = { "Arms", "Fury", "Protection" } },
}

local classFallbackIcons = {
    DRUID   = "Interface\\Icons\\Spell_Nature_StarFall",
    HUNTER  = "Interface\\Icons\\Ability_Hunter_SwiftStrike",
    MAGE    = "Interface\\Icons\\Spell_Fire_FlameBolt",
    PALADIN = "Interface\\Icons\\Spell_Holy_HolySmite",
    PRIEST  = "Interface\\Icons\\Spell_Holy_HolySmite",
    ROGUE   = "Interface\\Icons\\Ability_Rogue_Eviscerate",
    SHAMAN  = "Interface\\Icons\\Spell_Nature_Lightning",
    WARLOCK = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    WARRIOR = "Interface\\Icons\\Ability_MeleeDamage",
}

local profiles = {
    DRUID = {
        [1] = { spell = "Wrath", body = CAST("Wrath"), note = "Targets an enemy and opens at range with Wrath." },
        [2] = { minLevel = 10, spell = "Moonfire", body = CAST("[nocombat] Moonfire; [form:1] Maul; Claw"), note = "Pulls with Moonfire, then uses a simple form-appropriate attack." },
        [3] = { spell = "Wrath", body = CAST("Wrath"), note = "Targets an enemy and opens at range with Wrath." },
    },
    HUNTER = {
        [1] = { minLevel = 10, spell = "Auto Shot", body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast !Auto Shot", note = "Sends your pet and starts Auto Shot without toggling it off." },
        [2] = { minLevel = 10, spell = "Auto Shot", body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast !Auto Shot", note = "Sends your pet and starts Auto Shot without toggling it off." },
        [3] = { minLevel = 10, spell = "Auto Shot", body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast !Auto Shot", note = "Sends your pet and starts Auto Shot without toggling it off." },
    },
    MAGE = {
        [1] = { minLevel = 10, spell = "Arcane Missiles", body = CAST("Arcane Missiles"), note = "Targets an enemy and opens with Arcane Missiles." },
        [2] = { spell = "Fireball", body = CAST("Fireball"), note = "Targets an enemy and opens with Fireball." },
        [3] = { minLevel = 10, spell = "Frostbolt", body = CAST("Frostbolt"), note = "Targets an enemy and opens with Frostbolt." },
    },
    PALADIN = {
        [1] = { minLevel = 10, spell = "Judgement", body = ATTACK .. "\n/cast Judgement", note = "Starts attacking and attempts Judgement when a seal is active." },
        [2] = { minLevel = 10, spell = "Judgement", body = ATTACK .. "\n/cast Judgement", note = "Starts attacking and attempts Judgement when a seal is active." },
        [3] = { minLevel = 10, spell = "Judgement", body = ATTACK .. "\n/cast Judgement", note = "Starts attacking and attempts Judgement when a seal is active." },
    },
    PRIEST = {
        [1] = { spell = "Smite", body = CAST("Smite"), note = "Targets an enemy and opens with Smite." },
        [2] = { minLevel = 20, spell = "Holy Fire", body = CAST("[nocombat] Holy Fire; Smite"), note = "Opens with Holy Fire, then falls back to Smite." },
        [3] = { minLevel = 10, spell = "Shadow Word: Pain", body = CAST("[nocombat] Shadow Word: Pain; Mind Blast"), note = "Applies Shadow Word: Pain, then falls back to Mind Blast." },
    },
    ROGUE = {
        [1] = { spell = "Sinister Strike", body = ATTACK .. "\n/cast Sinister Strike", note = "Starts attacking and uses a dependable weapon strike." },
        [2] = { spell = "Sinister Strike", body = ATTACK .. "\n/cast Sinister Strike", note = "Starts attacking and uses a dependable weapon strike." },
        [3] = { spell = "Sinister Strike", body = ATTACK .. "\n/cast Sinister Strike", note = "Starts attacking and uses a dependable weapon strike." },
    },
    SHAMAN = {
        [1] = { spell = "Lightning Bolt", body = CAST("Lightning Bolt"), note = "Targets an enemy and opens at range with Lightning Bolt." },
        [2] = { minLevel = 10, spell = "Earth Shock", body = ATTACK .. "\n/cast Earth Shock", note = "Pulls with Earth Shock and continues using it while attacking." },
        [3] = { spell = "Lightning Bolt", body = CAST("Lightning Bolt"), note = "Targets an enemy and opens at range with Lightning Bolt." },
    },
    WARLOCK = {
        [1] = { minLevel = 10, spell = "Corruption", body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast [nocombat] Corruption; Shadow Bolt", note = "Sends your pet, applies Corruption, then uses Shadow Bolt." },
        [2] = { minLevel = 10, spell = "Shadow Bolt", body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast Shadow Bolt", note = "Sends your pet and opens with Shadow Bolt." },
        [3] = { minLevel = 10, spell = "Shadow Bolt", body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast Shadow Bolt", note = "Sends your pet and opens with Shadow Bolt." },
    },
    WARRIOR = {
        [1] = { minLevel = 10, spell = "Charge", body = ATTACK .. "\n/cast [nocombat] Charge; Heroic Strike", note = "Charges before combat, then falls back to Heroic Strike." },
        [2] = { minLevel = 10, spell = "Charge", body = ATTACK .. "\n/cast [nocombat] Charge; Heroic Strike", note = "Charges before combat, then falls back to Heroic Strike." },
        [3] = { minLevel = 10, spell = "Charge", body = ATTACK .. "\n/cast [nocombat] Charge; Heroic Strike", note = "Charges before combat, then falls back to Heroic Strike." },
    },
}

local baseProfiles = {
    DRUID   = { spell = "Wrath", body = CAST("Wrath"), note = "Targets an enemy and opens with your starting ranged attack." },
    HUNTER  = { spell = "Raptor Strike", body = ATTACK .. "\n/cast Raptor Strike", note = "Targets an enemy, starts attacking, and uses Raptor Strike." },
    MAGE    = { spell = "Fireball", body = CAST("Fireball"), note = "Targets an enemy and opens with your starting ranged attack." },
    PALADIN = { body = ATTACK, note = "Targets an enemy and begins melee auto-attack." },
    PRIEST  = { spell = "Smite", body = CAST("Smite"), note = "Targets an enemy and opens with your starting ranged attack." },
    ROGUE   = { spell = "Sinister Strike", body = ATTACK .. "\n/cast Sinister Strike", note = "Targets an enemy, starts attacking, and uses Sinister Strike." },
    SHAMAN  = { spell = "Lightning Bolt", body = CAST("Lightning Bolt"), note = "Targets an enemy and opens with your starting ranged attack." },
    WARLOCK = { spell = "Shadow Bolt", body = CAST("Shadow Bolt"), note = "Targets an enemy and opens with your starting ranged attack." },
    WARRIOR = { spell = "Heroic Strike", body = ATTACK .. "\n/cast Heroic Strike", note = "Targets an enemy, starts attacking, and queues Heroic Strike." },
}

local entries = {}
for classToken, class in pairs(classes) do
    entries[classToken] = {}
    for treeIndex, buildName in ipairs(class.builds) do
        local p = profiles[classToken][treeIndex]
        local base = baseProfiles[classToken]
        entries[classToken][treeIndex] = {{
            id = classToken:lower() .. "-" .. treeIndex .. "-1",
            classToken = classToken, treeIndex = treeIndex, minLevel = 1,
            title = buildName .. " Starter Opener", explanation = base.note,
            body = base.body,
            requiredSpells = base.spell and { base.spell } or nil,
        }}
        if p.minLevel and (p.body ~= base.body) then
            entries[classToken][treeIndex][2] = {
                id = classToken:lower() .. "-" .. treeIndex .. "-" .. p.minLevel,
                classToken = classToken, treeIndex = treeIndex, minLevel = p.minLevel,
                title = buildName .. " Grinding Opener", explanation = p.note,
                body = p.body, requiredSpells = { p.spell },
            }
        end
    end
end

D.TARGET = TARGET
D.ATTACK = ATTACK
D.Classes = classes
D.ClassFallbackIcons = classFallbackIcons
D.Entries = entries

