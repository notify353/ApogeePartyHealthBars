local Catalog = ApogeePartyHealthBars_DungeonGuideCatalog

local mobs = {}
local function mob(key, id, name, marker, priority, live, rationale, abilities, response, creatureType, cc, exceptions, boss, encounterKey, primaryBoss, autoMarkRank)
    mobs[key] = {
        npcIds = { id }, name = name, marker = marker, priority = priority,
        autoMarkRank = marker ~= "none" and (autoMarkRank or priority) or nil,
        liveReason = live, rationale = rationale, abilities = abilities or {},
        response = response, creatureType = creatureType, cc = cc,
        exceptions = exceptions or {}, boss = boss == true,
        encounterKey = encounterKey, primaryBoss = primaryBoss,
    }
end

-- Graveyard
mob("scryer", 4293, "Scarlet Scryer", "skull", 10, "ranged caster; interrupt and close",
    "Its ranged casting creates loose threat and avoidable damage, so remove it before cleanup enemies.", {}, "Interrupt, line-of-sight, or pull it into melee.", "Humanoid", "Polymorph, Sap, Fear, or other humanoid control works.")
mob("anguishedDead", 6426, "Anguished Dead", "skull", 20, "dangerous undead; burn first",
    "This is the dangerous undead anchor in mixed Graveyard pulls.", {}, "Focus it while controlling the rest of the pull.", "Undead", "Shackle Undead and Turn Undead work.")
mob("torturer", 4306, "Scarlet Torturer", "cross", 30, "control after Skull; stop casts",
    "Immolate adds avoidable damage while the dangerous undead or caster remains active.", { "Immolate" }, "Interrupt or dispel Immolate, then kill after the Skull target.", "Humanoid", "Polymorph, Sap, Fear, and stuns work.")
mob("hauntingPhantasm", 6427, "Haunting Phantasm", "none", 40, "cleanup spirit",
    "It is lower priority than the marked Graveyard threats.", {}, "Hold threat and clean up after priority targets.", "Undead", "Shackle Undead and Turn Undead are useful alternatives.")
mob("illusionaryPhantasm", 6493, "Illusionary Phantasm", "none", 50, "direct-hit cleanup; avoid relying on AoE",
    "It is cleanup, but direct attacks are more dependable than area damage.", {}, "Assign direct hits after priority enemies are controlled.", "Undead", "Use undead control if a direct-hit cleanup is delayed.")
mob("sentry", 4283, "Scarlet Sentry", "none", 60, "cleanup melee",
    "It is a routine melee body and should not distract from casters or dangerous undead.", {}, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("unfetteredSpirit", 4308, "Unfettered Spirit", "none", 70, "cleanup spirit",
    "It is a lower-priority spirit in mixed pulls.", {}, "Tank and clean up late.", "Undead", "Shackle Undead and Turn Undead work.")
mob("vishas", 3983, "Interrogator Vishas", "circle", 80, "boss; face away and cleanse Immolate",
    "Circle identifies the boss; his damage-over-time effect is the only mechanic that needs special handling.", { "Immolate" }, "Tank him with his add controlled or dead and dispel Immolate when available.", "Humanoid", "Use humanoid control on his accompanying Scarlet rather than relying on boss control.", {}, true)
mob("thalnos", 4543, "Bloodmage Thalnos", "circle", 90, "boss caster; interrupt and spread from AoE",
    "The fight is about limiting his close-range fire and shadow magic, not target ambiguity.", { "Shadow Bolt", "Flame Spike", "Fire Nova" }, "Interrupt Shadow Bolt; ranged players spread and stay outside close-range fire effects.", "Undead", "Boss control is unreliable; use interrupts.", {}, true)
mob("azshir", 6490, "Azshir the Sleepless", "circle", 100, "rare boss; interrupt and guard against fear",
    "Circle identifies the rare while preventing fear from reaching uncleared mobs remains the main concern.", { "Terrify", "Soul Siphon", "Call of the Grave" }, "Clear nearby mobs, interrupt when possible, and keep feared players away from extra pulls.", "Undead", "Boss immunities may apply; use interrupts.", {}, true)
mob("fallenChampion", 6488, "Fallen Champion", "circle", 110, "rare boss; face Cleave away",
    "This rare is a single durable melee target whose frontal cleave punishes loose facing.", { "Cleave", "Berserker Stance" }, "Face away and keep the party behind it.", "Undead", "Boss immunities may apply; use undead control only if accepted.", {}, true)
mob("ironspine", 6489, "Ironspine", "circle", 120, "rare boss; spread for Poison Cloud",
    "This rare is a single encounter whose area poison, rather than target order, threatens the party.", { "Poison Cloud", "Curse of Weakness" }, "Spread, move from Poison Cloud, and remove poison or curse when available.", "Undead", "Boss control is generally unreliable.", {}, true)

-- Library
mob("adept", 4296, "Scarlet Adept", "cross", 20, "healer; interrupt after the mana burner",
    "Heal extends the pull, but an active Diviner can remove the healer's mana and is the safer first kill for an ordinary PUG.", { "Heal" }, "Interrupt Heal while the group burns a Diviner, then kill the Adept second.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.", { "Without a Diviner, treat the Adept as the first kill." })
mob("diviner", 4291, "Scarlet Diviner", "skull", 10, "Mana Burn threatens the healer; kill first",
    "Mana Burn can remove the healer's resources faster than a Library healer can restore enemy health.", { "Mana Burn", "Fireball" }, "Interrupt Mana Burn first, line-of-sight the Diviner into melee, and focus it before healers.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.", { "If the healer has no mana bar, an uncontrolled healer may become the first kill." })
mob("chaplain", 4299, "Scarlet Chaplain", "cross", 30, "support caster; purge and kill second",
    "Renew and Power Word: Shield prolong the pull, but they are less immediately dangerous than Mana Burn.", { "Renew", "Power Word: Shield", "Inner Fire" }, "Purge Renew or the shield when practical and kill the Chaplain after the Diviner.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.", { "Without a Diviner, treat the Chaplain as the first kill." })
mob("beastmaster", 4288, "Scarlet Beastmaster", "cross", 40, "hound handler; kill after Skull",
    "Removing the handler after the primary caster stabilizes hound packs.", {}, "Kill second and keep hounds controlled.", "Humanoid", "Normal humanoid control works.")
mob("monk", 4540, "Scarlet Monk", "cross", 50, "dangerous melee; control or kill second",
    "Kick can lock out a healer or caster while its melee pressure stays on the tank.", { "Kick" }, "Keep it away from the healer, then stun, disarm, or kill after Skull.", "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work.")
mob("trackingHound", 4304, "Scarlet Tracking Hound", "none", 60, "control one extra hound",
    "Controlling one body reduces a hound-heavy pull while the group kills the handler.", {}, "Control one when the pack is large; otherwise tank and cleave.", "Beast", "Hibernate, Scare Beast, roots, and slows work.", { "Do not control a lone hound or a pack the group can safely cleave." })
mob("gallant", 4287, "Scarlet Gallant", "none", 70, "cleanup melee",
    "It is a routine melee target behind healers, casters, handlers, and Monks.", {}, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("loksey", 3974, "Houndmaster Loksey", "circle", 80, "boss; control and kill hounds first",
    "His three elite hounds create the opening danger, while Battle Shout and low-health Bloodlust raise melee pressure.", { "Battle Shout", "Bloodlust" }, "Control one hound if needed, kill the uncontrolled hounds, then finish Loksey.", "Humanoid", "Use beast control on a hound rather than relying on boss control.", { "Skull the first uncontrolled hound when the group needs an explicit focus." }, true)
mob("doan", 6487, "Arcanist Doan", "circle", 90, "boss caster; interrupt, then retreat for blast",
    "Polymorph and Silence disrupt the party before his close-range Arcane Explosion and Detonation.", { "Polymorph", "Silence", "Arcane Explosion", "Detonation" }, "Spread around the room, interrupt when possible, and retreat before Detonation.", "Humanoid", "Boss control is unreliable; use interrupts and dispel Polymorph when available.", {}, true)

-- Armory
mob("protector", 4292, "Scarlet Protector", "skull", 10, "healer; interrupt and remove first",
    "Its healing makes the rest of the pack harder to kill.", { "Heal" }, "Interrupt Heal and focus first.", "Humanoid", "Normal humanoid control works.")
mob("evoker", 4289, "Scarlet Evoker", "skull", 20, "ranged caster; interrupt",
    "Its ranged spell pressure and awkward positioning make it the next first-kill choice.", {}, "Interrupt or line-of-sight into the tank.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("conjuror", 4297, "Scarlet Conjuror", "cross", 30, "caster and pet owner; kill second",
    "Removing the caster limits magic pressure while its elemental can be tanked as cleanup.", {}, "Interrupt and kill after Skull; keep threat on the Fire Elemental.", "Humanoid", "Normal humanoid control works.")
mob("myrmidon", 4295, "Scarlet Myrmidon", "cross", 40, "dangerous melee; kill second",
    "It is the highest routine melee threat after support and caster enemies.", {}, "Use mitigation or control and kill after Skull.", "Humanoid", "Disarm, Polymorph, Sap, Fear, roots, and stuns work.")
mob("defender", 4298, "Scarlet Defender", "none", 50, "armored cleanup",
    "Its durability is less urgent than support, magic, or dangerous melee.", {}, "Hold threat and kill late.", "Humanoid", "Normal humanoid control works.")
mob("guardsman", 4290, "Scarlet Guardsman", "none", 60, "cleanup melee",
    "It is routine melee cleanup.", {}, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("soldier", 4286, "Scarlet Soldier", "none", 70, "cleanup melee",
    "It is routine melee cleanup.", {}, "Tank normally and kill late.", "Humanoid", "Normal humanoid control works.")
mob("fireElemental", 575, "Fire Elemental", "none", 80, "pet cleanup; hold threat",
    "The Conjuror is the priority; its elemental remains after the owner falls.", {}, "Pick it up and clean it after marked enemies.", "Elemental", "Banish works when the group needs the pet removed temporarily.")
mob("trainee", 6575, "Scarlet Trainee", "none", 90, "low-priority cleanup",
    "Trainees are low-pressure bodies compared with Armory elites.", {}, "Tank and cleave late.", "Humanoid", "Normal humanoid control works.")
mob("herod", 3975, "Herod", "circle", 100, "boss; face away and avoid Whirlwind",
    "Circle identifies the boss while safe positioning remains more important than a kill-order marker.", { "Whirlwind", "Enrage" }, "Face away, move out during Whirlwind, and pick up trainees afterward.", "Humanoid", "Boss control is unreliable.", {}, true)

-- Cathedral
mob("abbot", 4303, "Scarlet Abbot", "skull", 10, "healer; interrupt and kill first",
    "Heal and Renew can reset a dangerous Cathedral pull.", { "Heal", "Renew" }, "Interrupt Heal, purge Renew when practical, and burn first.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("wizard", 4300, "Scarlet Wizard", "skull", 20, "dangerous caster; interrupt",
    "Arcane Explosion punishes stacking while Fire Shield adds avoidable damage.", { "Arcane Explosion", "Fire Shield" }, "Interrupt or line-of-sight it into melee and purge Fire Shield when practical.", "Humanoid", "Normal humanoid control works.")
mob("sorcerer", 4294, "Scarlet Sorcerer", "cross", 40, "caster; control or kill second",
    "It is the next caster threat after the primary Skull target.", {}, "Interrupt and kill second, or assign control when the pull has another priority caster.", "Humanoid", "Polymorph, Sap, Fear, silence, and stuns work.")
mob("champion", 4302, "Scarlet Champion", "cross", 50, "dangerous melee; face away",
    "Holy Strike creates sharper tank damage than routine Scarlet melee.", { "Holy Strike" }, "Face away, mitigate, and kill after healers and casters.", "Humanoid", "Disarm and normal humanoid control work.")
mob("centurion", 4301, "Scarlet Centurion", "cross", 60, "dangerous melee; kill second",
    "Battle Shout strengthens nearby melee enemies in tightly packed Cathedral pulls.", { "Battle Shout" }, "Purge the shout when practical and kill after the primary healer or caster.", "Humanoid", "Disarm and normal humanoid control work.")
mob("whitemane", 3977, "High Inquisitor Whitemane", "skull", 80, "after resurrection: interrupt and focus healing",
    "Deep Sleep leads into Scarlet Resurrection; afterward Heal and Power Word: Shield make her the decisive focus.", { "Holy Smite", "Heal", "Deep Sleep", "Power Word: Shield", "Scarlet Resurrection" }, "After the forced sleep and resurrection, pick up Mograine, interrupt Heal, and focus Whitemane.", "Humanoid", "Boss control is unreliable; save interrupts for Heal.", { "Before the resurrection sequence, she is inactive; Skull matters only after she joins the fight." }, true, "mograineWhitemane", false)
mob("mograine", 3976, "Scarlet Commander Mograine", "circle", 90, "initial boss; face away through both phases",
    "Hammer of Justice can stun the tank, while Divine Shield and Lay on Hands can prolong either phase.", { "Retribution Aura", "Hammer of Justice", "Crusader Strike", "Lay on Hands", "Divine Shield" }, "Face him away, heal through the tank stun, then pick him up immediately after Whitemane resurrects him.", "Humanoid", "Boss control is unreliable; use mitigation and dispels when available.", { "Clear the chapel before engaging and keep both bosses positioned safely after the resurrection." }, true, "mograineWhitemane", true)
mob("fairbanks", 4542, "High Inquisitor Fairbanks", "circle", 100, "hidden boss; interrupt healing",
    "Curse of Blood increases physical damage taken, while Fear, Sleep, Heal, and Power Word: Shield prolong the fight.", { "Curse of Blood", "Fear", "Sleep", "Heal", "Power Word: Shield" }, "Clear the room, remove Curse of Blood, interrupt Heal, and purge the shield when practical.", "Undead", "Boss control is unreliable; use interrupts and curse removal.", {}, true)

Catalog.RegisterGuide({
    key = "scarletMonastery", name = "Scarlet Monastery", instanceIds = { 189 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        { key = "graveyard", name = "Graveyard", route = {
            "Enter through the far-left portal, clear the torture room around Vishas, then continue into the graveyard without leaving runners behind.",
            "Check each isolated Unfettered Spirit spawn while crossing the graveyard; it can be replaced by Azshir, Fallen Champion, or Ironspine.",
            "Clear the crypt approach before Bloodmage Thalnos so fear or close-range magic cannot chain another undead pack.",
        }, entries = { "scryer", "anguishedDead", "torturer", "hauntingPhantasm", "illusionaryPhantasm", "sentry", "unfetteredSpirit", "vishas", "thalnos", "azshir", "fallenChampion", "ironspine" }, rules = {
            { title = "Undead control", guidance = "Shackle or Turn one dangerous undead when the pull is larger than the group can safely stabilize." },
            { title = "Rare bosses", guidance = "Circle identifies each Graveyard rare; treat the encounter as a single-target mechanics check rather than a kill-order problem." },
        } },
        { key = "library", name = "Library", route = {
            "Enter through the far-right portal and pull ranged Scarlet packs around corners; stop every low-health runner before it reaches the next room.",
            "Clear Loksey's side room for his optional encounter, then return to the main hall and continue through the Athenaeum.",
            "Spread around Doan, retreat before Detonation, then loot the Scarlet Key from the strongbox behind him for Armory and Cathedral.",
        }, entries = { "diviner", "adept", "chaplain", "beastmaster", "monk", "trackingHound", "gallant", "loksey", "doan" }, rules = {
            { title = "Mana burner plus healer", guidance = "Skull and interrupt the Diviner first, then kill the Cross healer. If Mana Burn cannot affect the healer, reverse the order or control one caster." },
            { title = "Loksey's hounds", guidance = "Control one Tracking Hound when needed, establish threat on the others, kill the uncontrolled hounds, then finish Loksey. Skip control when the group can safely cleave." },
        } },
        { key = "armory", name = "Armory", route = {
            "Use the Scarlet Key on the right locked door, then pull the long corridor in small groups toward cleared ground.",
            "Line-of-sight Evokers and Conjurors around corners and stop runners before they reach the next formation or patrol.",
            "Clear Herod's complete hall, fight him away from the doorway, avoid Whirlwind, then gather the non-elite Trainees after he dies.",
        }, entries = { "protector", "evoker", "conjuror", "myrmidon", "defender", "guardsman", "soldier", "fireElemental", "trainee", "herod" }, rules = {
            { title = "Caster pull", guidance = "Line-of-sight Evokers and Conjurors. Keep elemental pets on the tank while the group removes their owner." },
            { title = "Runner exception", guidance = "A fleeing humanoid near another pack becomes the immediate control target even when its baseline entry says cleanup." },
        } },
        { key = "cathedral", name = "Cathedral", route = {
            "Use the Scarlet Key on the left locked door, enter together, and keep the doorway behind the group as safe reset space.",
            "Clear straight to the lower fountain, then take one side toward the stairs: left by default or right when patrol timing is safer. Skip the unused half.",
            "Repeat the one-side clear at the upper fountain, pulling every caster and runner back onto cleared ground and stopping runners before they reach another pack.",
            "At the chapel threshold, line-of-sight packs to the outside hold point. Once stable, enter and clear the full nave, both aisles, and every side room.",
            "Take the optional Fairbanks detour before the altar via the torch in the right-side room. Then kill Mograine and focus Whitemane's healing after she resurrects him.",
        }, entries = { "abbot", "wizard", "chaplain", "sorcerer", "myrmidon", "champion", "monk", "defender", "centurion", "whitemane", "mograine", "fairbanks" }, rules = {
            { title = "Extra healer or caster", guidance = "Assign crowd control to an additional Abbot, Chaplain, Wizard, or Sorcerer when the pull contains more priority casters than the group can interrupt." },
            { title = "Chapel safety", guidance = "Clear the chapel before engaging Mograine; the resurrection encounter can otherwise chain nearby Scarlet packs." },
            { title = "Resurrection phase", guidance = "After Whitemane resurrects Mograine, focus and interrupt Whitemane's healing while the tank faces Mograine away." },
        } },
    },
})
