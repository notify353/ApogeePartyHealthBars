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

-- Primary threats
mob("frostSpectre", 8585, "Frost Spectre", "skull", 5,
    "Amnennar summon; switch immediately",
    "Amnennar summons spectres in waves, and leaving them active compounds party damage during the boss fight.",
    {},
    "Pick up each wave, focus the spectres, then return to Amnennar when the group is stable.",
    "Undead", "Shackle Undead can hold one spectre while the group kills the others.")
mob("deathsHeadGeomancer", 7335, "Death's Head Geomancer", "skull", 10,
    "dangerous area caster; interrupt and kill first",
    "Flame Spike and Fireball punish stacked groups, while Slow can keep players inside dangerous ground effects.",
    { "Flame Spike", "Fireball", "Slow" },
    "Pull around a corner, interrupt Flame Spike and Fireball, and kill it before the durable withered enemies.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")
mob("skeletalSummoner", 7342, "Skeletal Summoner", "skull", 20,
    "summons reinforcements; interrupt and kill first",
    "Summoned skeletons turn the final platform guard pack into an attrition fight while curses weaken the party.",
    { "Summon Skeletons", "Lightning Bolt", "Curse of Weakness" },
    "Interrupt the summon, focus the Summoner, then stabilize the Captain and Centurions already in the pull.",
    "Undead", "Shackle Undead, Turn Undead, stuns, interrupts, and silences work; ordinary humanoid control does not.")
mob("frozenSoul", 7352, "Frozen Soul", "skull", 30,
    "area silence threatens the healer; kill first",
    "A ten-second Silence can lock out the healer and casters while nearby ghouls continue applying diseases.",
    { "Silence" },
    "Keep it beside the tank and away from the healer, interrupt when possible, and focus it before melee cleanup.",
    "Undead", "Shackle Undead, Turn Undead, stuns, and interrupts work; ordinary humanoid control does not.")

-- Secondary threats and control
mob("witheredSpearhide", 7332, "Withered Spearhide", "cross", 40,
    "ranged diseases and low-health Enrage; kill second",
    "Disease Shot reduces Strength and Agility, Infected Spine increases damage taken, and Enrage makes the finish dangerous.",
    { "Disease Shot", "Infected Spine", "Enrage" },
    "Line-of-sight it into melee, cleanse diseases, and save a stun or burst damage for its final quarter health.",
    "Undead", "Shackle Undead, Turn Undead, roots, and stuns work; ordinary humanoid control does not.")
mob("skeletalFrostweaver", 7341, "Skeletal Frostweaver", "cross", 50,
    "ranged frost caster; interrupt after Skull",
    "Repeated Frostbolts add avoidable ranged pressure and slow targets during patrol-heavy pulls on the spiral.",
    { "Frostbolt" },
    "Use line of sight to stack it with the tank, interrupt casts, and kill it after the primary threat.",
    "Undead", "Shackle Undead, Turn Undead, interrupts, and stuns work; ordinary humanoid control does not.")
mob("freezingSpirit", 7353, "Freezing Spirit", "cross", 60,
    "Frost Nova can split the group; kill second",
    "Frost Nova can pin a player beside a patrol or leave the tank separated from healing on the narrow spiral.",
    { "Frost Nova", "Chilling Touch" },
    "Stack near the tank before the root, dispel or break movement effects, and kill it after the Skull target.",
    "Undead", "Shackle Undead, Turn Undead, stuns, and interrupts work; ordinary humanoid control does not.")
mob("thornEaterGhoul", 7348, "Thorn Eater Ghoul", "cross", 70,
    "disease and armor pressure; kill after casters",
    "Ghoul Rot reduces chance to hit while Sunder Armor and Ravenous Claw increase pressure on the tank.",
    { "Ghoul Rot", "Sunder Armor", "Ravenous Claw" },
    "Keep it on the tank, cleanse Ghoul Rot promptly, and kill it after silence and caster threats are handled.",
    "Undead", "Shackle Undead, Turn Undead, stuns, and roots work; ordinary humanoid control does not.")
mob("splinterboneCaptain", 7345, "Splinterbone Captain", "cross", 80,
    "final-guard knockdown threat; isolate and kill second",
    "Backhand can knock down the tank while the Summoner and multiple Centurions add damage at Amnennar's platform.",
    { "Backhand" },
    "Kill the Summoner first, keep the Captain controlled or tanked, then focus it before the Centurions.",
    "Undead", "Shackle Undead, Turn Undead, stuns, and roots work; ordinary humanoid control does not.")
mob("tombReaver", 7351, "Tomb Reaver", "cross", 90,
    "elite gong wave; focus one at a time",
    "The second gong summons four elite Reavers, making uncontrolled split damage much harder to heal than the first wave.",
    {},
    "Let the tank gather both sides, control one when needed, and focus each Reaver before ringing the gong again.",
    "Undead", "Shackle Undead, Turn Undead, roots, and stuns work; ordinary humanoid control does not.")
mob("battleBoarHorror", 7334, "Battle Boar Horror", "cross", 95,
    "fast patrol or defense add; intercept it",
    "Its fast movement can put it on Belnistrasz or the healer before the tank has secured the event wave.",
    {},
    "Intercept it in cleared space and keep it off Belnistrasz before returning to a caster target.",
    "Undead", "Shackle Undead, Turn Undead, roots, and stuns work.")
mob("deathsHeadNecromancer", 7337, "Death's Head Necromancer", "none", 100,
    "control one caster in mixed packs",
    "Controlling one Necromancer removes Shadow Bolt and Cripple pressure while the group stabilizes a mixed pack.",
    { "Shadow Bolt", "Cripple" },
    "Keep it controlled away from area damage, kill the Skull target, then interrupt and finish the Necromancer.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.",
    { "Skip control when it is the only caster or the pull is already stable." })

-- Routine enemies
mob("tombFiend", 7349, "Tomb Fiend", "none", 110,
    "first gong wave; routine area-damage cleanup",
    "The first gong releases many non-elite spiders, but none should distract the party from keeping them grouped.",
    {},
    "Stack on one side, let the tank gather both entrances, and use controlled area damage without chasing stragglers.",
    "Undead", "Shackle or roots can stop a straggler, but these are normally area-damage cleanup.")
mob("splinterboneSkeleton", 7343, "Splinterbone Skeleton", "none", 120,
    "fragile skeleton; group for area cleanup",
    "Large numbers surround Mordresh, but each skeleton is fragile and less important than controlling the boss pull.",
    {},
    "Gather them before using area damage, protect the healer from loose bodies, and keep Mordresh interrupted.",
    "Undead", "Shackle Undead and Turn Undead work, though controlled area damage is usually faster.")
mob("splinterboneWarrior", 7344, "Splinterbone Warrior", "none", 130,
    "routine spiral melee cleanup",
    "Sunder Armor adds tank pressure but is less urgent than silence, summons, frost casters, or disease threats.",
    { "Sunder Armor" },
    "Keep it on the tank and clean it up after marked enemies, watching for nearby spiral patrols.",
    "Undead", "Shackle Undead, Turn Undead, roots, and stuns work; ordinary humanoid control does not.")
mob("splinterboneCenturion", 7346, "Splinterbone Centurion", "none", 140,
    "Amnennar guard; control or clean up late",
    "The Centurions add bodies to the final guard pack but are less urgent than the Summoner and Captain.",
    {},
    "Control one when needed, kill the Summoner and Captain first, then clean up the Centurions.",
    "Undead", "Shackle Undead, Turn Undead, roots, and stuns work.")

-- Bosses
mob("tutenkash", 7355, "Tuten'kash", "circle", 200,
    "gong-event boss; face away and remove poison or curse",
    "Web Spray can catch the party while Virulent Poison and the long Curse of Tuten'kash slow recovery after the event.",
    { "Web Spray", "Virulent Poison", "Curse of Tuten'kash" },
    "Face the boss away, cleanse poison and curse when available, and verify every wave is dead before using the gong.",
    "Undead", "Boss control is unreliable; use positioning, dispels, and mitigation.", {}, true)
mob("plaguemaw", 7356, "Plaguemaw the Rotting", "circle", 210,
    "optional event boss; keep it off Belnistrasz",
    "Plaguemaw ends a five-minute defense with Putrid Stench and Withered Touch while Belnistrasz must remain alive.",
    { "Putrid Stench", "Withered Touch" },
    "Pick it up immediately, face it away from Belnistrasz, and finish remaining adds before focusing the boss.",
    "Humanoid", "Boss control is unreliable; protect the escorted NPC and use mitigation.", {}, true)
mob("ladyFaltheress", 14686, "Lady Falther'ess", "circle", 220,
    "Scourge Invasion boss; prepare before opening her pen",
    "Her friendly disguise becomes a banshee with Dominate Mind, a severe miss curse, and area shadow damage.",
    { "Dominate Mind", "Banshee Curse", "Ribbon of Souls", "Banshee Shriek" },
    "Clear the pens, open her cage only when ready, remove the curse, and stabilize any mind-controlled player.",
    "Undead", "Boss control is unreliable; interrupts, curse removal, and recovery tools matter most.",
    { "She appears in the Murder Pens only during the Scourge Invasion event." }, true)
mob("mordreshFireEye", 7357, "Mordresh Fire Eye", "circle", 230,
    "bone-pile boss; control skeletons and interrupt fire",
    "Mordresh links with a crowd of fragile skeletons and casts Fireball and Fire Nova while they surround the group.",
    { "Fireball", "Fire Nova" },
    "Gather and area down the skeletons, keep healing threat protected, and maintain interrupts on Mordresh.",
    "Undead", "Boss control is unreliable; interrupt the boss and use undead control on loose adds.", {}, true)
mob("glutton", 8567, "Glutton", "circle", 240,
    "patrolling boss; isolate before low-health Enrage",
    "Glutton can join another pull, leaves Disease Cloud around the group, and becomes most dangerous near death.",
    { "Disease Cloud", "Enrage" },
    "Pull into cleared ground, move out of disease clouds, and save defensive cooldowns and burst for Enrage.",
    "Undead", "Boss control is unreliable; use movement and mitigation.", {}, true)
mob("ragglesnout", 7354, "Ragglesnout", "circle", 250,
    "rare boss; interrupt healing and recover from mind control",
    "Dominate Mind can remove the tank or healer while Heal, Shadow Bolt, and Shadow Word: Pain extend the fight.",
    { "Dominate Mind", "Heal", "Shadow Bolt", "Shadow Word: Pain" },
    "Clear nearby spiral packs, interrupt Heal first, and cover the role of any mind-controlled party member.",
    "Humanoid", "Boss control is unreliable; interrupts and recovery tools are dependable.",
    { "Check the huts along the lower spiral; a Splinterbone Warrior may occupy the rare's place." }, true)
mob("amnennar", 7358, "Amnennar the Coldbringer", "circle", 260,
    "final boss; prevent knockback and manage Frost Spectres",
    "Amnennar can knock the tank from the platform, root the party, and summon Frost Spectres at health thresholds.",
    { "Amnennar's Wrath", "Frost Nova", "Frostbolt", "Summon Frost Spectres" },
    "Tank with the hut behind the tank, interrupt Frostbolt, gather spectres, and burn the boss when healing is stable.",
    "Undead", "Boss control is unreliable; use interrupts, positioning, and mitigation.", {}, true)

local function overviewMap()
    return {
        texture = "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\DungeonGuide\\RazorfenDowns.png",
        width = 2048, height = 2048,
        caption = "Gold route — dashed alternate — orange optional; numbers show boss order",
        description = "Complete Razorfen Downs overview through the gong chamber, Murder Pens and Idol event, Bone Pile, Glutton route, rare spawn sites, and Spiral of Thorns to Amnennar.",
    }
end

Catalog.RegisterGuide({
    key = "razorfenDowns", name = "Razorfen Downs", instanceIds = { 129 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "witheredHallsGong", name = "Withered Halls & Gong", map = overviewMap(),
            route = {
                "Enter Razorfen Downs northeast of the Great Lift, take the eastern passage first, and leave the harder southern undead route for later.",
                "Pull ranged Spearhides and Geomancers around corners, watch the fast Battle Boar Horror patrol, and clear each altar-room group into the hall.",
                "Clear the entire gong chamber before touching the gong; the first ring releases Tomb Fiends and the second releases elite Tomb Reavers.",
                "After every spider is dead, ring a third time for Tuten'kash, then continue through the passage toward the Murder Pens.",
            },
            entries = {
                "deathsHeadGeomancer", "witheredSpearhide", "tombReaver",
                "deathsHeadNecromancer", "tombFiend", "tutenkash",
            },
            rules = {
                { title = "Corner pulls", guidance = "Hide behind tunnel walls so Geomancers, Necromancers, and Spearhides enter the tank's melee group instead of casting beside another pack." },
                { title = "Gong lockout", guidance = "Do not ring again until every spider is dead. If the gong remains inactive, search both room edges and the entrance hall for a straggler." },
            },
        },
        {
            key = "murderPensIdol", name = "Murder Pens & Idol", map = overviewMap(),
            route = {
                "From the gong, clear the main passage and both ambush ramps into the Murder Pens; isolate the wandering Battle Boar Horrors before opening any cage.",
                "Find Belnistrasz in the north pen and pre-clear the complete route back to the idol before starting his optional escort and defense event.",
                "Follow Belnistrasz to the idol, hold the five-minute waves off him, then pick up Plaguemaw immediately when the event boss arrives.",
                "After the event, return to the Murder Pens; during a Scourge Invasion, check the nearby disguised prisoner for Lady Falther'ess before leaving.",
            },
            entries = {
                "deathsHeadGeomancer", "witheredSpearhide", "battleBoarHorror",
                "deathsHeadNecromancer", "plaguemaw", "ladyFaltheress",
            },
            rules = {
                { title = "Belnistrasz defense", guidance = "Pre-clear first, let the escort set the pace, tank every wave away from Belnistrasz, and conserve enough mana and cooldowns for Plaguemaw." },
                { title = "Event-only prisoner", guidance = "Lady Falther'ess appears only during the Scourge Invasion. Her friendly disguise turns hostile when the cage is opened, so clear and recover first." },
            },
        },
        {
            key = "bonePile", name = "Bone Pile & Glutton", map = overviewMap(),
            route = {
                "Return to the Murder Pens after the idol event and take the bridge toward the Bone Pile, clearing patrols away from the next group.",
                "Approach Mordresh carefully and gather the fragile dancing skeletons for controlled area damage while maintaining interrupts on the boss.",
                "Take the eastern passage from the Bone Pile, separating each ghoul-and-caster patrol and cleansing long diseases before the next pull.",
                "Watch for Glutton patrolling the lower spiral approach; isolate him in cleared ground before moving farther toward the huts.",
            },
            entries = {
                "frozenSoul", "skeletalFrostweaver", "thornEaterGhoul",
                "splinterboneSkeleton", "splinterboneWarrior", "mordreshFireEye", "glutton",
            },
            rules = {
                { title = "Mordresh's crowd", guidance = "Do not let the healer collect the skeletons. Establish threat, use measured area damage, and keep a dedicated interrupt on Mordresh's Fireball." },
                { title = "Disease recovery", guidance = "Ghoul Rot and other long diseases can poison several pulls. Cleanse before advancing and avoid standing in Glutton's Disease Cloud." },
            },
        },
        {
            key = "spiralOfThorns", name = "Spiral of Thorns", map = overviewMap(),
            route = {
                "Climb the spiral slowly, pull each group down into cleared space, and wait for patrols; enemies from higher turns can path into the pull.",
                "Check the huts along the lower spiral for rare Ragglesnout, whose placeholder may be an ordinary Splinterbone Warrior.",
                "Before the summit, stop and prepare for the Summoner, Captain, and Centurion guard pack; kill the Summoner before it creates more bodies.",
                "Clear the platform, then tank Amnennar with the hut behind the tank to prevent a fatal knockback and manage each Frost Spectre wave without losing boss interrupts.",
            },
            entries = {
                "frostSpectre", "skeletalSummoner", "frozenSoul", "witheredSpearhide",
                "skeletalFrostweaver", "freezingSpirit", "thornEaterGhoul",
                "splinterboneCaptain", "splinterboneWarrior", "splinterboneCenturion",
                "ragglesnout", "amnennar",
            },
            rules = {
                { title = "Spiral patrols", guidance = "Never skip a group above or below the party. Pulling across turns can send a large train down the spiral and remove safe retreat space." },
                { title = "Amnennar's platform", guidance = "Keep the hut behind the tank, stack close enough to recover from Frost Nova, and decide before the pull whether to gather spectres or burn the boss." },
            },
        },
    },
})
