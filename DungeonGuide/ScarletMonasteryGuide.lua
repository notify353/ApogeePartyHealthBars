local Catalog = ApogeePartyHealthBars_DungeonGuideCatalog

local mobs = {}
local function mob(key, id, name, marker, priority, live, rationale, abilities, response, creatureType, cc, exceptions, boss)
    mobs[key] = {
        npcIds = { id }, name = name, marker = marker, priority = priority,
        liveReason = live, rationale = rationale, abilities = abilities or {},
        response = response, creatureType = creatureType, cc = cc,
        exceptions = exceptions or {}, boss = boss == true,
    }
end

-- Graveyard
mob("scryer", 4293, "Scarlet Scryer", "skull", 10, "ranged caster; interrupt and close",
    "Its ranged magic creates loose threat and avoidable damage, so remove it before cleanup enemies.", { "Ranged shadow magic" }, "Interrupt, line-of-sight, or pull it into melee.", "Humanoid", "Polymorph, Sap, Fear, or other humanoid control works.")
mob("anguishedDead", 6426, "Anguished Dead", "skull", 20, "dangerous undead; burn first",
    "This is the dangerous undead anchor in mixed Graveyard pulls.", { "Heavy undead pressure" }, "Focus it while controlling the rest of the pull.", "Undead", "Shackle Undead, Turn Undead, and undead-specific control work.")
mob("torturer", 4306, "Scarlet Torturer", "cross", 30, "control after Skull; stop casts",
    "It is the next meaningful humanoid threat after the Skull target.", { "Painful control and damage" }, "Interrupt or stun dangerous casts, then kill second.", "Humanoid", "Polymorph, Sap, Fear, and stuns work.")
mob("hauntingPhantasm", 6427, "Haunting Phantasm", "none", 40, "cleanup spirit",
    "It is lower priority than the marked Graveyard threats.", { "Spirit attacks" }, "Hold threat and clean up after priority targets.", "Undead", "Shackle Undead and Turn Undead are useful alternatives.")
mob("illusionaryPhantasm", 6493, "Illusionary Phantasm", "none", 50, "direct-hit cleanup; avoid relying on AoE",
    "It is cleanup, but direct attacks are more dependable than area damage.", { "Phantasmal defenses" }, "Assign direct hits after priority enemies are controlled.", "Undead", "Use undead control if a direct-hit cleanup is delayed.")
mob("sentry", 4283, "Scarlet Sentry", "none", 60, "cleanup melee",
    "It is a routine melee body and should not distract from casters or dangerous undead.", { "Melee attacks" }, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("unfetteredSpirit", 4308, "Unfettered Spirit", "none", 70, "cleanup spirit",
    "It is a lower-priority spirit in mixed pulls.", { "Spirit attacks" }, "Tank and clean up late.", "Undead", "Shackle Undead and Turn Undead work.")
mob("vishas", 3983, "Interrogator Vishas", "none", 80, "boss; face away and cleanse Immolate",
    "A single boss does not need a kill-order mark; the important choice is positioning and his damage-over-time effect.", { "Immolate" }, "Face him away, dispel Immolate when available, and use steady mitigation.", "Humanoid", "Boss control is unreliable; use interrupts and stuns only when permitted.", {}, true)
mob("thalnos", 4543, "Bloodmage Thalnos", "none", 90, "boss caster; interrupt and spread from AoE",
    "The fight is about limiting his close-range fire and shadow magic, not target ambiguity.", { "Shadow Bolt", "Flame Spike", "Fire Nova" }, "Interrupt Shadow Bolt; ranged players spread and stay outside close-range fire effects.", "Humanoid", "Boss control is unreliable; use interrupts.", {}, true)
mob("azshir", 6490, "Azshir the Sleepless", "none", 100, "rare boss; interrupt and guard against fear",
    "This rare is fought alone; preventing fear from reaching uncleared mobs matters more than a marker.", { "Terrify", "Soul Siphon", "Call of the Grave" }, "Clear nearby mobs, interrupt when possible, and keep feared players away from extra pulls.", "Undead", "Boss immunities may apply; use interrupts.", {}, true)
mob("fallenChampion", 6488, "Fallen Champion", "none", 110, "rare boss; face Cleave away",
    "This rare is a single durable melee target whose frontal cleave punishes loose facing.", { "Cleave", "Berserker Stance" }, "Face away and keep the party behind it.", "Undead", "Boss immunities may apply; use undead control only if accepted.", {}, true)
mob("ironspine", 6489, "Ironspine", "none", 120, "rare boss; spread for Poison Cloud",
    "This rare is a single encounter whose area poison, rather than target order, threatens the party.", { "Poison Cloud", "Curse of Weakness" }, "Spread, move from Poison Cloud, and remove poison or curse when available.", "Undead", "Boss control is generally unreliable.", {}, true)

-- Library
mob("adept", 4296, "Scarlet Adept", "skull", 10, "healer; interrupt and kill first",
    "A healer can extend the entire pull, making it the clearest first kill.", { "Healing magic" }, "Interrupt heals and focus immediately.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("diviner", 4291, "Scarlet Diviner", "skull", 20, "caster; interrupt after healer",
    "Its spell damage is the next priority when no higher healer is active.", { "Ranged arcane magic" }, "Interrupt or line-of-sight and focus early.", "Humanoid", "Normal humanoid control works.", { "With a Chaplain, kill or control the Chaplain first." })
mob("chaplain", 4299, "Scarlet Chaplain", "skull", 30, "healer; stop Heal",
    "Its healing is more dangerous than routine damage and can erase progress.", { "Heal", "Holy magic" }, "Interrupt Heal and focus before non-healers.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.", { "With a Diviner, Chaplain is the first Skull and Diviner follows." })
mob("beastmaster", 4288, "Scarlet Beastmaster", "cross", 40, "hound handler; kill after Skull",
    "Removing the handler after the primary caster stabilizes hound packs.", { "Commands hounds", "Melee attacks" }, "Kill second and keep hounds controlled.", "Humanoid", "Normal humanoid control works.")
mob("monk", 4540, "Scarlet Monk", "cross", 50, "dangerous melee; control or kill second",
    "Its melee pressure deserves the second marker after healers and casters.", { "Fast melee attacks" }, "Stun, disarm, kite, or kill after Skull.", "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work.")
mob("trackingHound", 4304, "Scarlet Tracking Hound", "moon", 60, "control one extra hound",
    "Moon removes one body from a hound-heavy pull while the group kills the handler.", { "Fast beast melee" }, "Control one when the pack is large; otherwise tank and cleave.", "Beast", "Hibernate, Scare Beast, roots, and slows work.", { "Do not Moon a lone hound or a pack the group can safely cleave." })
mob("gallant", 4287, "Scarlet Gallant", "none", 70, "cleanup melee",
    "It is a routine melee target behind healers, casters, handlers, and Monks.", { "Melee attacks" }, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("loksey", 3974, "Houndmaster Loksey", "none", 80, "boss; control and kill hounds first",
    "The boss is obvious; controlling his three elite hounds is the meaningful marking decision.", { "Three Tracking Hounds", "Battle Shout", "Low-health Bloodlust" }, "Moon one hound if needed, kill the uncontrolled hounds, then finish Loksey.", "Humanoid", "Control hounds with beast CC; boss control is unreliable.", { "Skull the first uncontrolled hound when the group needs an explicit focus." }, true)
mob("doan", 6487, "Arcanist Doan", "none", 90, "boss caster; interrupt, then retreat for blast",
    "This single-target fight is governed by cast response and positioning.", { "Silence", "Arcane Explosion", "Detonation" }, "Interrupt when possible and retreat for his large explosion.", "Humanoid", "Boss control is unreliable; use interrupts.", {}, true)

-- Armory
mob("protector", 4292, "Scarlet Protector", "skull", 10, "healer; interrupt and remove first",
    "Its healing makes the rest of the pack harder to kill.", { "Heal" }, "Interrupt Heal and focus first.", "Humanoid", "Normal humanoid control works.")
mob("evoker", 4289, "Scarlet Evoker", "skull", 20, "ranged caster; interrupt",
    "Its ranged spell pressure and awkward positioning make it the next first-kill choice.", { "Ranged fire magic" }, "Interrupt or line-of-sight into the tank.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("conjuror", 4297, "Scarlet Conjuror", "cross", 30, "caster and pet owner; kill second",
    "Removing the caster limits magic pressure while its elemental can be tanked as cleanup.", { "Conjuration", "Fire Elemental pet" }, "Interrupt and kill after Skull; keep threat on the pet.", "Humanoid", "Normal humanoid control works.")
mob("myrmidon", 4295, "Scarlet Myrmidon", "cross", 40, "dangerous melee; kill second",
    "It is the highest routine melee threat after support and caster enemies.", { "Heavy melee attacks" }, "Use mitigation or control and kill after Skull.", "Humanoid", "Disarm, Polymorph, Sap, Fear, roots, and stuns work.")
mob("defender", 4298, "Scarlet Defender", "none", 50, "armored cleanup",
    "Its durability is less urgent than support, magic, or dangerous melee.", { "Defensive melee" }, "Hold threat and kill late.", "Humanoid", "Normal humanoid control works.")
mob("guardsman", 4290, "Scarlet Guardsman", "none", 60, "cleanup melee",
    "It is routine melee cleanup.", { "Melee attacks" }, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("soldier", 4286, "Scarlet Soldier", "none", 70, "cleanup melee",
    "It is routine melee cleanup.", { "Melee attacks" }, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("fireElemental", 575, "Fire Elemental", "none", 80, "pet cleanup; hold threat",
    "The Conjuror is the priority; its elemental remains after the owner falls.", { "Fire attacks" }, "Pick it up and clean it after marked enemies.", "Elemental", "Banish and elemental-specific control may work.")
mob("trainee", 6575, "Scarlet Trainee", "none", 90, "low-priority cleanup",
    "Trainees are low-pressure bodies compared with Armory elites.", { "Light melee attacks" }, "Tank and cleave late.", "Humanoid", "Normal humanoid control works.")
mob("herod", 3975, "Herod", "none", 100, "boss; face away and avoid Whirlwind",
    "The single boss needs positioning, not a kill-order marker.", { "Whirlwind", "Enrage" }, "Face away, move out during Whirlwind, and pick up trainees afterward.", "Humanoid", "Boss control is unreliable.", {}, true)

-- Cathedral
mob("abbot", 4303, "Scarlet Abbot", "skull", 10, "healer; interrupt and kill first",
    "Healing can reset a dangerous Cathedral pull.", { "Powerful healing" }, "Interrupt, purge support buffs, and burn first.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("wizard", 4300, "Scarlet Wizard", "skull", 20, "dangerous caster; interrupt",
    "Its ranged magic is a primary threat when no Abbot is active.", { "Ranged magic" }, "Interrupt or line-of-sight and focus early.", "Humanoid", "Normal humanoid control works.")
mob("sorcerer", 4294, "Scarlet Sorcerer", "cross", 40, "caster; control or kill second",
    "It is the next caster threat after the primary Skull target.", { "Ranged magic" }, "Interrupt and kill second, or Moon when the pull has another priority caster.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("champion", 4302, "Scarlet Champion", "cross", 50, "dangerous melee; face away",
    "Its melee pressure deserves the second marker after healers and casters.", { "Heavy melee attacks" }, "Face away, mitigate, and kill second.", "Humanoid", "Disarm and normal humanoid control work.")
mob("centurion", 4301, "Scarlet Centurion", "cross", 60, "dangerous melee; kill second",
    "It is a higher-pressure melee target than routine defenders.", { "Heavy melee attacks" }, "Use control or mitigation and kill after Skull.", "Humanoid", "Disarm and normal humanoid control work.")
mob("whitemane", 3977, "High Inquisitor Whitemane", "skull", 80, "after resurrection: interrupt and kill",
    "After Mograine is resurrected, Whitemane's healing makes her the decisive focus target.", { "Heal", "Resurrection phase" }, "Interrupt healing and focus Whitemane after the resurrection.", "Humanoid", "Boss control is unreliable; interrupts are essential.", { "Before the resurrection sequence, follow the encounter rather than forcing the mark." }, true)
mob("mograine", 3976, "Scarlet Commander Mograine", "none", 90, "initial boss; use Cross only after resurrection",
    "Mograine begins as the only active boss, so a static Cross would be wrong until Whitemane resurrects him.", { "Heavy melee", "Resurrection phase" }, "Initially face him away and follow the encounter; after resurrection, Cross him behind Skull Whitemane.", "Humanoid", "Boss control is unreliable.", { "Clear the chapel before engaging. The Book's resurrection rule supplies the conditional Cross assignment." }, true)
mob("fairbanks", 4542, "High Inquisitor Fairbanks", "none", 100, "hidden boss; interrupt healing",
    "This optional single boss has no competing kill target.", { "Healing and holy magic" }, "Interrupt healing and maintain steady mitigation.", "Humanoid", "Boss control is unreliable; use interrupts.", {}, true)

Catalog.RegisterGuide({
    key = "scarletMonastery", name = "Scarlet Monastery", instanceIds = { 189 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        { key = "graveyard", name = "Graveyard", entries = { "scryer", "anguishedDead", "torturer", "hauntingPhantasm", "illusionaryPhantasm", "sentry", "unfetteredSpirit", "vishas", "thalnos", "azshir", "fallenChampion", "ironspine" }, rules = {
            { title = "Undead control", guidance = "Shackle or Turn one dangerous undead when the pull is larger than the group can safely stabilize." },
            { title = "Rare bosses", guidance = "Treat Graveyard rares as single-target mechanics checks; do not let their No Mark entry imply that they are harmless." },
        } },
        { key = "library", name = "Library", entries = { "adept", "diviner", "chaplain", "beastmaster", "monk", "trackingHound", "gallant", "loksey", "doan" }, rules = {
            { title = "Chaplain plus Diviner", guidance = "Skull and interrupt the Chaplain first, then make the Diviner the next focus. Moon either caster only when reliable CC is safer than a fast kill." },
            { title = "Loksey's hounds", guidance = "Moon one Tracking Hound when needed, establish threat on the others, kill the uncontrolled hounds, then finish Loksey. Skip Moon when the group can safely cleave." },
        } },
        { key = "armory", name = "Armory", entries = { "protector", "evoker", "conjuror", "myrmidon", "defender", "guardsman", "soldier", "fireElemental", "trainee", "herod" }, rules = {
            { title = "Caster pull", guidance = "Line-of-sight Evokers and Conjurors. Keep elemental pets on the tank while the group removes their owner." },
            { title = "Runner exception", guidance = "A fleeing humanoid near another pack becomes the immediate control target even when its baseline entry says cleanup." },
        } },
        { key = "cathedral", name = "Cathedral", entries = { "abbot", "wizard", "chaplain", "sorcerer", "myrmidon", "champion", "monk", "defender", "centurion", "whitemane", "mograine", "fairbanks" }, rules = {
            { title = "Extra healer or caster", guidance = "Moon an additional Abbot, Chaplain, Wizard, or Sorcerer when the pull contains more priority casters than the group can interrupt." },
            { title = "Chapel safety", guidance = "Clear the chapel before engaging Mograine; the resurrection encounter can otherwise chain nearby Scarlet packs." },
            { title = "Resurrection phase", guidance = "After Whitemane resurrects Mograine, Skull Whitemane and Cross Mograine. Interrupt Whitemane's healing while the tank faces Mograine away." },
        } },
    },
})
