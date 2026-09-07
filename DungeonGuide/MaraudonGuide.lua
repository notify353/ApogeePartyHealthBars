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

-- Primary and secondary pull threats
mob("corruptor", 12217, "Corruptor", "skull", 10,
    "ranged corruption caster; kill first",
    "Its ranged corruption effects add poison pressure while durable Putridus demons occupy the tank.",
    { "Noxious Catalyst", "Corruption" },
    "Line-of-sight it into the cleared path, interrupt when possible, and remove it before the elite demons.",
    "Demon", "Banish, Fear, stuns, silences, and other demon control work.")
mob("poisonSprite", 12216, "Poison Sprite", "cross", 20,
    "ranged poison attacker; kill after Corruptor",
    "Poison Bolt adds avoidable ranged damage, but the Corruptor's multiple effects are the safer first focus.",
    { "Poison Bolt" },
    "Stack it with line of sight, interrupt Poison Bolt, cleanse poison, and kill it after the Corruptor.",
    "Elemental", "Banish, stuns, silences, and other elemental control work.")
mob("deeprotTangler", 13142, "Deeprot Tangler", "skull", 30,
    "roots a target then changes victims; kill first",
    "Entangling Roots can pin the tank or a rescuer while the Tangler moves onto a vulnerable party member.",
    { "Entangling Roots" },
    "Interrupt or dispel Roots, keep it on the tank, and focus it before a Stomper in mixed pulls.",
    "Elemental", "Banish, stuns, interrupts, and other elemental control work.")
mob("deeprotStomper", 13141, "Deeprot Stomper", "cross", 40,
    "area stun interrupts recovery; kill second",
    "War Stomp can interrupt nearby healing, but it is more predictable than a Tangler leaving the tank.",
    { "War Stomp" },
    "Keep non-tanks at range, recover after War Stomp, and kill it after the Tangler.",
    "Elemental", "Banish, roots, slows, stuns, and other elemental control work.")
mob("barbedLasher", 12219, "Barbed Lasher", "skull", 50,
    "Thorn Volley knocks down the party; kill first",
    "Thrash and Thorn Volley make the Lasher the lethal anchor in pulls with several Constrictor Vines.",
    { "Thorn Volley", "Thrash", "Entangling Roots" },
    "Control a Vine, keep ranged players beyond Thorn Volley, and focus the Lasher before the remaining plants.",
    "Elemental", "Freezing Trap, Banish, roots, stuns, and other elemental control work.")
mob("constrictorVine", 12220, "Constrictor Vine", "cross", 60,
    "roots then attacks another target; kill second",
    "Entangling Roots can separate the tank from the pull, but the Lasher's knockdown and extra attacks are more urgent.",
    { "Entangling Roots" },
    "Interrupt or dispel Roots, control one Vine when possible, and focus it after the Barbed Lasher.",
    "Elemental", "Freezing Trap, Banish, roots, stuns, and other elemental control work.")
mob("noxxiousEssence", 13736, "Noxxious Essence", "skull", 70,
    "quest-spawn elite; focus it for plant credit",
    "The elite Essence is the required target when a Filled Cerulean Vial triggers the Vyletongue Corruption event.",
    { "Noxious Catalyst", "Corruption" },
    "Let the tank collect the spawn, focus the Essence, then clear its smaller Scions before using another plant.",
    "Elemental", "Banish, stuns, silences, and other elemental control work.",
    { "This enemy appears only when a player uses the quest vial on a corrupted plant." })
mob("spewedLarva", 13533, "Spewed Larva", "cross", 80,
    "fast elite from the Larva Spewer; stop the source",
    "The elite larva keeps returning while the nearby Larva Spewer remains active and can join the Noxxion pull.",
    { "Noxious Catalyst" },
    "Have a player click the Larva Spewer until it stops, focus the active elite, and clear the pool before Noxxion.",
    "Beast", "Hibernate, Polymorph, Fear, roots, stuns, and other beast control work.")
mob("celebrianDryad", 11793, "Celebrian Dryad", "skull", 90,
    "fast ranged patrol with magic dispel; kill first",
    "Fast dryad patrols can add to another pull, and Dispel Magic removes useful protection while Slowing Poison hinders recovery.",
    { "Throw", "Slowing Poison", "Dispel Magic" },
    "Wait for the patrol, pull it into cleared ground, cleanse poison, and focus the Dryad before its companion.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("sisterOfCelebras", 11794, "Sister of Celebras", "cross", 100,
    "ranged dryad patrol; kill after the Dryad",
    "She adds ranged physical pressure to the fast Poison Falls patrol but lacks the Dryad's dispel and slowing poison.",
    { "Throw", "Strike" },
    "Pull the patrol into cleared space, control one member if needed, and kill her after the Celebrian Dryad.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("cavernShambler", 12224, "Cavern Shambler", "skull", 110,
    "regenerates and knocks down nearby players; kill first",
    "Wild Regeneration prolongs the pull while its area knockdown can interrupt the healer and loosen control.",
    { "Wild Regeneration", "Knockdown" },
    "Interrupt Wild Regeneration, keep non-tanks at range, and focus the Shambler before a Lurker.",
    "Elemental", "Banish, stuns, interrupts, and other elemental control work.")
mob("cavernLurker", 12223, "Cavern Lurker", "cross", 120,
    "single-target knockdown; kill second",
    "Its knockdown can interrupt one player, but it lacks the Shambler's area control and self-healing.",
    { "Knockdown" },
    "Keep it on the tank and kill it after the Shambler; the water route is safer than nearby linked slimes.",
    "Elemental", "Banish, roots, stuns, and other elemental control work.")
mob("noxxionSpawn", 13456, "Noxxion's Spawn", "skull", 130,
    "Noxxion split phase; switch immediately",
    "Noxxion remains absent until all five Spawn die, so leaving one alive only extends poison pressure and the phase.",
    {},
    "Gather the five Spawn, use controlled area damage, finish stragglers, and resume Noxxion only after he reforms.",
    "Elemental", "Fear, roots, slows, stuns, and other elemental control work.")
mob("subterraneanDiemetradon", 13323, "Subterranean Diemetradon", "skull", 140,
    "linked beast with area silence; focus one",
    "Linked packs repeatedly silence nearby players, disabling healing, taunts, and interrupts if allowed to surround the group.",
    { "Sonic Burst" },
    "Pull the whole linked pack into clear ground, keep casters at maximum range, and focus one beast at a time.",
    "Beast", "Hibernate, Polymorph, Fear, roots, stuns, and other beast control work.")
mob("theradrimGuardian", 11784, "Theradrim Guardian", "cross", 150,
    "patrolling elemental that splits on death; kill second",
    "Guardian patrols can add unexpectedly and split into Shardlings, but a Diemetradon's silence is the first priority.",
    { "Knockdown" },
    "Pull the patrol into cleared ground, focus it after any Diemetradons, then gather the resulting Shardlings.",
    "Elemental", "Banish, roots, slows, stuns, and other elemental control work.")
mob("primordialBehemoth", 12206, "Primordial Behemoth", "skull", 160,
    "heavy giant; focus one before the tank is overwhelmed",
    "Pairs on the Princess approach combine high armor and damage, while Boulder can pressure a distant party member.",
    { "Trample", "Boulder" },
    "Pull one when possible; if two link, focus the marked giant while the tank controls both and ranged players spread.",
    "Giant", "Boss-like giants resist most control; use slows, stuns if they land, and focused damage.")

-- Routine, positioning, and cleanup targets
mob("putridusSatyr", 11790, "Putridus Satyr", "none", 170,
    "elite melee; control while ranged enemies die",
    "Its Gouge and Putrid Breath matter, but ranged Corruptors and Poison Sprites are the safer first kills in mixed packs.",
    { "Gouge", "Sinister Strike", "Putrid Breath" },
    "Keep it on the tank or control it, face it away, and clean it up after the ranged enemies.",
    "Demon", "Banish, Fear, stuns, and other demon control work.")
mob("putridusTrickster", 11791, "Putridus Trickster", "none", 180,
    "durable elite; control or clean up",
    "Thrash and poison pressure are dangerous on the tank, but its correct order depends on which ranged enemies join the pull.",
    { "Thrash", "Poison", "Putrid Breath" },
    "Control it when possible, cleanse poison, and kill it after the ranged threats unless tank damage demands an earlier switch.",
    "Demon", "Banish, Fear, stuns, and other demon control work.")
mob("putridusShadowstalker", 11792, "Putridus Shadowstalker", "none", 190,
    "stealthed patrol; reveal and control manually",
    "Its surprise patrol timing matters more than a fixed kill position, and Evasion can make focused physical damage inefficient.",
    { "Stealth", "Evasion", "Hamstring", "Putrid Breath" },
    "Pause before advancing, reveal the patrol, control it in cleared ground, and avoid chasing through Evasion.",
    "Demon", "Banish, Fear, stuns, and other demon control work.")
mob("vileLarva", 12218, "Vile Larva", "none", 200,
    "linked non-elites; gather for controlled area damage",
    "Linked larva are numerous but fragile, so a single-target mark would distract from gathering and measured area damage.",
    { "Larva Goo" },
    "Pull one linked group at a time, let the tank gather it, and use controlled area damage without reaching the next pack.",
    "Beast", "Roots, slows, and stuns can contain stragglers; area damage is normally more efficient.")
mob("noxxiousScion", 13696, "Noxxious Scion", "none", 210,
    "quest-spawn companion; gather after the Essence",
    "Several non-elite Scions accompany the required Noxxious Essence and are best gathered rather than individually focused.",
    { "Noxious Catalyst" },
    "Let the tank gather the Scions, kill the Essence first, then clear them before activating another quest plant.",
    "Elemental", "Banish, roots, slows, stuns, and other elemental control work.",
    { "This enemy appears only when a player uses the quest vial on a corrupted plant." })
mob("creepingSludge", 12222, "Creeping Sludge", "none", 220,
    "slow, brutal melee pack; kite at range",
    "Linked Sludges hit extremely hard but move slowly, so standing to focus a marked target is less safe than coordinated kiting.",
    { "Poison Shock" },
    "Pull from maximum range, slow and kite the pack through cleared ground, and keep melee players away until targets are low.",
    "Elemental", "Slows and roots support the kite; do not rely on close-range control.")
mob("noxiousSlime", 12221, "Noxious Slime", "none", 230,
    "linked slimes leave poison clouds on death",
    "Killing linked Slimes together can stack their death clouds, so spacing and movement are safer than a universal focus mark.",
    {},
    "Pull the linked group into open ground, spread kills when practical, and move immediately out of every poison cloud.",
    "Elemental", "Use slows and roots for spacing; avoid control that leaves the group inside death clouds.")
mob("deepBorer", 11787, "Deep Borer", "none", 240,
    "linked non-elites; gather and clear",
    "Deep Borers arrive in linked groups on the long waterfall path and are routine area-damage cleanup.",
    {},
    "Gather the linked group on the tank and use measured area damage, or take the safe waterfall jump to bypass the path.",
    "Beast", "Roots, slows, and stuns work; area damage is normally more efficient.")
mob("stolidSnapjaw", 13599, "Stolid Snapjaw", "none", 250,
    "neutral turtle; do not wake with stray damage",
    "The turtles near Celebras and Princess are not part of the pull unless attacked, so marking one would invite an avoidable add.",
    {},
    "Leave neutral turtles alone and keep area damage away from them; gather one only if it is accidentally engaged.",
    "Beast", "Hibernate, Polymorph, Fear, roots, and stuns work after one is engaged.")
mob("corruptForceOfNature", 13743, "Corrupt Force of Nature", "none", 260,
    "Celebras summon; control while burning the boss",
    "Celebras continually replaces fallen treants, so switching damage to each summon prolongs the encounter.",
    {},
    "Keep summons off the healer, control or gather them, burn Celebras, and clear surviving treants after he dies.",
    "Elemental", "Banish, roots, slows, stuns, and other elemental control work.")
mob("theradrimShardling", 11783, "Theradrim Shardling", "none", 270,
    "small elemental; gather for cleanup",
    "Shardlings trail patrols or appear when a Guardian dies, but individual marks do not improve their area-damage cleanup.",
    { "Strike" },
    "Let the tank gather the Shardlings, use controlled area damage, and watch for the next Guardian patrol.",
    "Elemental", "Roots, slows, stuns, and other elemental control work.")
mob("thessalaHydra", 12207, "Thessala Hydra", "none", 280,
    "knockback patrol; position before attacking",
    "Water Jet can interrupt and throw players into another beast, so safe facing and pull location matter more than kill order.",
    { "Thrash", "Water Jet" },
    "Wait for open water, pull away from other patrols, face the Hydra safely, and keep vulnerable players at range.",
    "Beast", "Hibernate, Polymorph, Fear, roots, stuns, and other beast control work.")

-- Bosses and rare
mob("lordVyletongue", 12236, "Lord Vyletongue", "circle", 300,
    "purple-wing boss; stack and follow each Blink",
    "His linked Shadowstalkers add pressure, but killing the mobile boss first removes Multi-Shot and repeated repositioning.",
    { "Shot", "Multi-Shot", "Smoke Bomb", "Blink" },
    "Stack near the tank to deny ranged attacks, follow each Blink or line-of-sight him back, then clean up both guards.",
    "Demon", "Boss control is unreliable; control the linked Shadowstalkers instead.", {}, true)
mob("noxxion", 13282, "Noxxion", "circle", 310,
    "poison boss; clear every split phase",
    "Toxic Volley pressures the whole party, and Noxxion cannot be attacked while divided into five Spawn.",
    { "Toxic Volley", "Uppercut", "Summon Noxxion Spawn" },
    "Fight at the pool edge, cleanse poison, recover from Uppercut, and switch to every Spawn until Noxxion reforms.",
    "Elemental", "Boss control is unreliable; control and quickly clear the Spawn.", {}, true)
mob("razorlash", 12258, "Razorlash", "circle", 320,
    "optional plant boss; face away and heal Puncture",
    "Puncture creates sustained tank damage while Cleave punishes players who stand near the boss's front.",
    { "Cleave", "Puncture" },
    "Face Razorlash away, keep casters at maximum range, and maintain the tank through the Puncture damage-over-time effect.",
    "Elemental", "Boss control is unreliable; use positioning and focused damage.",
    { "Razorlash is optional and can be skipped without blocking progress to Poison Falls." }, true)
mob("meshlok", 12237, "Meshlok the Harvester", "circle", 330,
    "optional rare; keep the healer beyond Earth Shock",
    "Meshlok resembles nearby shamblers, while War Stomp and Earth Shock can interrupt recovery if the group stacks.",
    { "War Stomp", "Earth Shock", "Harvester Strike" },
    "Confirm the rare, pull it from nearby water patrols, face it away, and keep the healer outside its interrupt range.",
    "Elemental", "Boss control is unreliable; use range, mitigation, and focused damage.",
    { "This rare may be replaced by an ordinary Cavern Shambler." }, true)
mob("celebras", 12225, "Celebras the Cursed", "circle", 340,
    "boss caster; burn through renewable treants",
    "Wrath and Twisted Tranquility pressure the party while defeated Corrupt Forces are continually replaced.",
    { "Wrath", "Entangling Roots", "Twisted Tranquility", "Corrupt Force of Nature" },
    "Interrupt Wrath, dispel Roots, control the treants, burn Celebras first, then clear the remaining summons.",
    "Demon", "Boss control is unreliable; Banish, root, slow, or stun the treants instead.", {}, true)
mob("tinkererGizlock", 13601, "Tinkerer Gizlock", "circle", 350,
    "optional goblin boss; avoid the fire cone",
    "Goblin Dragon Gun and Bomb punish a stacked group, while Shoot lets Gizlock pressure players from range.",
    { "Goblin Dragon Gun", "Shoot", "Bomb" },
    "Clear the final patrol, face the Dragon Gun away, spread around Gizlock, and close distance when he tries to shoot.",
    "Humanoid", "Boss control is unreliable; use positioning, slows, and focused damage.",
    { "The eastern Gizlock detour can be skipped when nobody needs the boss." }, true)
mob("landslide", 12203, "Landslide", "circle", 360,
    "giant boss; brace at a wall and ignore shardlings",
    "Knock Away can scatter the party, while summoned Shardlings stun nearby players but disappear when Landslide dies.",
    { "Trample", "Knock Away", "Summon Theradrim Shardlings" },
    "Fight deep in the alcove with the tank against a wall, spread ranged players, control Shardlings, and burn Landslide.",
    "Giant", "Boss control is unreliable; control the temporary Shardlings instead.", {}, true)
mob("princessTheradras", 12201, "Princess Theradras", "circle", 370,
    "final boss; fight deep and recover lost threat",
    "Repulsive Gaze can remove the tank while Dust Field knocks players across a dangerous cavern and disrupts threat.",
    { "Dust Field", "Repulsive Gaze", "Boulder" },
    "Clear the causeway, fight at the back wall, keep ranged players out, and kite briefly if fear or knockback breaks threat.",
    "Elemental", "Boss control is unreliable; use fear breaks, positioning, mitigation, and threat restraint.", {}, true)
mob("rotgrip", 13596, "Rotgrip", "circle", 380,
    "optional crocolisk boss; keep health above Fatal Bite",
    "Puncture steadily lowers the tank while Fatal Bite can finish a player whose health is allowed to fall.",
    { "Puncture", "Fatal Bite" },
    "Drop into clear water, establish threat before damage, keep the tank healthy through Puncture, and avoid nearby Hydras.",
    "Beast", "Boss control is unreliable; use mitigation and focused healing.",
    { "Rotgrip is an optional cleanup boss in the pool below Princess Theradras." }, true)

mobs.noxxionSpawn.stagingContext = "noxxion"

Catalog.RegisterGuide({
    key = "maraudon", name = "Maraudon", instanceIds = { 349 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "wickedGrotto", name = "Wicked Grotto",
            route = {
                "At the three-way cavern, follow the purple crystals to the Shadowshard portal; save the central Scepter altar for later inner-wing runs.",
                "Descend the spiral carefully, pulling ranged Corruptors and Poison Sprites into cleared ground and pausing for stealthed Shadowstalker patrols.",
                "Follow the path away from the waterfall, defeat Lord Vyletongue, then exit through purple and re-enter through orange for the quest-friendly full clear.",
            },
            entries = {
                "corruptor", "poisonSprite", "deeprotTangler", "deeprotStomper",
                "putridusSatyr", "putridusTrickster", "putridusShadowstalker",
                "lordVyletongue",
            },
            rules = {
                { title = "Stealth patrols", guidance = "Stop before each bend and pull backward. Shadowstalkers can enter from behind while ranged non-elites keep a mixed pack spread out." },
                { title = "Vyletongue order", guidance = "Two Shadowstalkers are linked to the boss. Stack on Vyletongue and kill him first; control or tank the guards, then clean them up." },
            },
        },
        {
            key = "foulsporeCavern", name = "Foulspore Cavern",
            route = {
                "Return to the three-way cavern, follow the orange crystals, fill any quest vial at the orange pool, and enter the Ambershard portal.",
                "Control the four-elite plant packs, click the Larva Spewer until production stops, and clear the pool before pulling Noxxion to its edge.",
                "Defeat Noxxion and every split phase, take the optional Razorlash cave detour, then continue through the dryad patrol route to Poison Falls.",
            },
            entries = {
                "barbedLasher", "constrictorVine", "noxxiousEssence", "spewedLarva",
                "celebrianDryad", "sisterOfCelebras", "noxxionSpawn", "vileLarva",
                "noxxiousScion", "noxxion", "razorlash",
            },
            rules = {
                { title = "Plant packs", guidance = "Barbed Lashers are the first focus. Control a Constrictor Vine, keep ranged players beyond Thorn Volley, and dispel Entangling Roots." },
                { title = "Larva Spewer", guidance = "The elite Spewed Larva keeps returning until the nearby spewer is shut down. Stop it and clear all larva before Noxxion." },
                { title = "Quest plants", guidance = "Use the Filled Cerulean Vial only after the area is stable. Focus the elite Noxxious Essence, then gather its smaller Scions." },
            },
        },
        {
            key = "poisonFalls", name = "Poison Falls",
            route = {
                "From either wing, favor the water route through Cavern Lurkers and Shamblers instead of the dry-land slime packs; pull every patrol into cleared space.",
                "Check the poisoned water for rare Meshlok, then clear the approach and defeat Celebras while controlling rather than chasing his renewable treants.",
                "After Celebras, complete the Scepter ritual when available; future groups can use its central portal to begin at Earth Song Falls.",
            },
            entries = {
                "celebrianDryad", "sisterOfCelebras", "cavernShambler", "cavernLurker",
                "creepingSludge", "noxiousSlime", "stolidSnapjaw",
                "corruptForceOfNature", "meshlok", "celebras",
            },
            rules = {
                { title = "Sludge kite", guidance = "Creeping Sludges hit brutally but move slowly. Pull at maximum range and kite through cleared ground; melee joins only near death." },
                { title = "Slime clouds", guidance = "Noxious Slimes are linked and leave poison clouds when killed. Avoid stacked deaths and move the group out of every cloud." },
                { title = "Celebras adds", guidance = "Defeated treants are replaced while Celebras lives. Control them, protect the healer, and keep damage on the boss." },
            },
        },
        {
            key = "earthSongFalls", name = "Earth Song Falls",
            route = {
                "Enter from Celebras or the Scepter portal and jump from the waterfall into the deep pool; the long path contains linked Deep Borers.",
                "Move south past the yellow flowers, isolate Hydra and elemental patrols, and keep casters at maximum range from each linked Diemetradon pack.",
                "At the first major ramp, take the eastern descent for optional Tinkerer Gizlock, return to the junction, then climb west toward Landslide.",
            },
            entries = {
                "subterraneanDiemetradon", "theradrimGuardian", "deepBorer",
                "theradrimShardling", "thessalaHydra", "tinkererGizlock",
            },
            rules = {
                { title = "Linked dinosaurs", guidance = "Diemetradons arrive together and repeatedly silence nearby players. Keep healer, casters, and ranged interrupts well back." },
                { title = "Rock patrols", guidance = "Guardians split into Shardlings and patrol widely. Pull backward, gather the fragments, and wait for the route to clear before advancing." },
                { title = "Gizlock branch", guidance = "Clear the final patrol before engaging. Face the Dragon Gun away and spread around the boss so Bomb cannot strike the whole party." },
            },
        },
        {
            key = "zaetarsGrave", name = "Zaetar's Grave",
            route = {
                "Continue uphill, pull Primordial Behemoths one at a time where possible, and watch for returning elemental patrols before entering Landslide's alcove.",
                "Defeat Landslide against the back wall, clear both Behemoths on the causeway, then move the whole group to the back of Princess Theradras's cavern.",
                "After Princess Theradras, speak with Zaetar's Spirit if needed, drop into clear water for Rotgrip, and leave by hearthstone or portal when finished.",
            },
            entries = {
                "primordialBehemoth", "theradrimShardling", "thessalaHydra",
                "landslide", "princessTheradras", "rotgrip",
            },
            rules = {
                { title = "Landslide summons", guidance = "Shardlings stun nearby players but disappear when Landslide dies. Control or gather them and keep focused damage on the boss." },
                { title = "Princess position", guidance = "Fight at the cavern's back, not the causeway. Ranged players avoid Dust Field, and everyone pauses damage when fear or knockback breaks threat." },
                { title = "Neutral turtles", guidance = "Keep area damage away from the watching Snapjaws near Princess. An accidental turtle makes an already mobile fight harder to stabilize." },
            },
        },
    },
})
