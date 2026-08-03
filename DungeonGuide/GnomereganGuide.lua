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

-- Dungeon-wide alarm patrol
mob("mobileAlertSystem", 7849, "Mobile Alert System", "skull", 10,
    "alarm patrol; destroy immediately",
    "If it finishes warning nearby machines, a controlled pull can become an unmanageable reinforcement wave.",
    { "Intruder alert", "Calls reinforcements" },
    "Switch to it immediately and destroy it before returning to the original target.",
    "Mechanical", "Ordinary humanoid and beast control does not work; use damage or a verified engineering effect.")

-- Hall of Gears and Trogg Caves
mob("irradiatedPillager", 6329, "Irradiated Pillager", "skull", 20,
    "dangerous irradiated trogg; remove first",
    "Its disease and group pressure make it the most dangerous routine trogg in the irradiated halls.",
    { "Irradiated disease", "Heavy melee pressure" },
    "Focus it first and remove its disease when the group can dispel it.",
    "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work when an early kill is not practical.")
mob("caverndeepReaver", 6211, "Caverndeep Reaver", "cross", 30,
    "heavy trogg; kill after Skull",
    "It is a durable melee threat that becomes dangerous while the tank is also containing event waves or patrols.",
    { "Heavy melee attacks" },
    "Face it away, mitigate its attacks, and kill it after the primary threat.",
    "Humanoid", "Normal humanoid control works; disarm, stun, root, or fear it when the pull is crowded.")
mob("caverndeepBurrower", 6206, "Caverndeep Burrower", "moon", 40,
    "control one extra elite trogg",
    "Moon removes one elite body from the large trogg pulls that make the opening route difficult to stabilize.",
    { "Trogg melee attacks" },
    "Control one when several elites arrive together; otherwise tank it behind the marked kill targets.",
    "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work.",
    { "Do not Moon the only active trogg or break reliable control with area damage." })
mob("irradiatedHorror", 6220, "Irradiated Horror", "cross", 50,
    "durable elemental; kill after Skull",
    "Its sustained elemental pressure is more important than the slimes around it but lacks an urgent cast to stop.",
    { "Irradiated elemental attacks" },
    "Keep it on the tank and kill it after the primary trogg or alarm threat.",
    "Elemental", "Ordinary humanoid control does not work; Banish and verified elemental control may work.")
mob("corrosiveLurker", 6219, "Corrosive Lurker", "none", 60,
    "corrosive cleanup; keep off the healer",
    "It is lower priority than alarms and elite troggs, but loose threat can still pressure the group.",
    { "Corrosive attacks" },
    "Establish threat and clean it up after marked enemies.",
    "Elemental", "Ordinary humanoid control does not work; use elemental control only when verified.")
mob("irradiatedSlime", 6218, "Irradiated Slime", "none", 70,
    "slow cleanup slime",
    "It is routine cleanup and should not distract the group from alarms, troggs, or patrol positioning.",
    { "Irradiated slime attacks" },
    "Tank and clean it up late without pulling additional enemies from the lower floor.",
    "Elemental", "Ordinary humanoid control does not work; slows and kiting are safer than assuming immunity rules.")
mob("grubbis", 7361, "Grubbis", "circle", 100,
    "event boss; finish the cave waves first",
    "The event and collapsing side tunnels are the danger; the boss itself is an obvious single target.",
    { "Heavy melee attacks", "Spawns with Chomper" },
    "Leave each cave before Emi detonates it, finish incoming troggs, then tank Grubbis normally.",
    "Humanoid", "Boss control is unreliable; use mitigation and stuns only when accepted.", {}, true)
mob("chomper", 6215, "Chomper", "circle", 110,
    "Grubbis companion; control threat",
    "Circle identifies Chomper as the boss-event companion while the group chooses which melee target to finish first.",
    { "Beast melee attacks" },
    "Pick it up with Grubbis and finish it after the chosen focus target.",
    "Beast", "Hibernate, Scare Beast, roots, and slows may work; boss-event restrictions can apply.", {}, true)
mob("viscousFallout", 7079, "Viscous Fallout", "circle", 120,
    "boss; clear the irradiated floor first",
    "Nearby slimes and lurkers are more likely to complicate the fight than the single elemental boss.",
    { "Poisonous elemental attacks" },
    "Clear its surrounding floor, keep it on the tank, and avoid adding nearby packs.",
    "Elemental", "Boss control is unreliable; use steady damage and cleanse poison when available.", {}, true)

-- Dormitory and Launch Bay
mob("leprousTechnician", 6222, "Leprous Technician", "skull", 20,
    "ranged technician; close and kill first",
    "Its ranged attacks keep it outside the tank's cluster and can pressure healers while sturdier enemies hold the group.",
    { "Ranged wrench attacks" },
    "Line-of-sight or close the distance, interrupt movement with control, and kill first.",
    "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work.")
mob("leprousDefender", 6223, "Leprous Defender", "moon", 30,
    "control one extra defender",
    "Moon reduces an elite-heavy Launch Bay pull while the group removes its alarm or ranged attacker.",
    { "Defensive melee attacks" },
    "Control one when a pack has multiple elites; otherwise tank it behind Skull and Cross.",
    "Humanoid", "Polymorph, Sap, Fear, roots, disarm, and stuns work.")
mob("mechanizedSentry", 6233, "Mechanized Sentry", "cross", 40,
    "durable machine; kill after Skull",
    "Its elite melee pressure matters after alarms and ranged technicians are removed.",
    { "Mechanical melee attacks" },
    "Keep it on the tank and kill it after the primary threat.",
    "Mechanical", "Ordinary humanoid and beast control does not work; verified engineering effects may work.")
mob("peacekeeper", 6230, "Peacekeeper Security Suit", "cross", 50,
    "heavy machine; face away",
    "This suit is one of the harder-hitting machines in the route and should not remain loose in a mixed pull.",
    { "Heavy mechanical attacks" },
    "Establish threat, face it away, and kill it after the primary target.",
    "Mechanical", "Ordinary humanoid and beast control does not work; use mitigation or verified engineering control.")
mob("mechanoTank", 6225, "Mechano-Tank", "none", 60,
    "armored cleanup machine",
    "Its durability can waste time while alarms and support enemies remain active, so leave it for cleanup.",
    { "Armored mechanical attacks" },
    "Hold threat and kill it after marked enemies.",
    "Mechanical", "Ordinary humanoid and beast control does not work; verified engineering effects may work.")
mob("electrocutioner", 6235, "Electrocutioner 6000", "circle", 100,
    "boss; spread and collect the Workshop Key",
    "The single boss is obvious; spacing limits chained lightning while the key unlocks the alternate entrance.",
    { "Chain Bolt", "Megavolt", "Shock" },
    "Spread enough to limit chained damage, keep it on the tank, and loot the Workshop Key.",
    "Mechanical", "Boss control is unreliable; ordinary humanoid control does not work.", {}, true)

-- Engineering Labs
mob("leprousMachinesmith", 6224, "Leprous Machinesmith", "skull", 20,
    "ranged machinesmith; close and kill first",
    "Its ranged pressure and position can keep the pull spread while stronger machines occupy the tank.",
    { "Ranged wrench attacks" },
    "Line-of-sight or close to it, then kill it before working through the machines.",
    "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work.")
mob("mechanoFlamewalker", 6226, "Mechano-Flamewalker", "cross", 30,
    "fire machine; kill after Skull",
    "Its fire pressure makes it the next priority after alarms and machinesmiths.",
    { "Fire attacks" },
    "Keep it on the tank and kill it second; use fire resistance only when already available.",
    "Mechanical", "Ordinary humanoid and beast control does not work; verified engineering effects may work.")
mob("mechanoFrostwalker", 6227, "Mechano-Frostwalker", "cross", 40,
    "frost machine; kill after Skull",
    "Its frost effects can hinder movement in a room where patrol and ledge positioning already matter.",
    { "Frost attacks", "Movement slowing" },
    "Keep it controlled by the tank and kill it after the primary target.",
    "Mechanical", "Ordinary humanoid and beast control does not work; verified engineering effects may work.")
mob("crowdPummeler", 6229, "Crowd Pummeler 9-60", "circle", 100,
    "boss; put the tank's back to a wall",
    "Circle identifies the boss while its platform knockback makes safe positioning the encounter's main concern.",
    { "Arcing Smash", "Crowd Pummel", "Trample" },
    "Clear patrols, place the tank against a safe wall, and keep the party away from the ledge.",
    "Mechanical", "Boss control is unreliable; ordinary humanoid control does not work.", {}, true)

-- Tinkers' Court
mob("darkIronLandMine", 8035, "Dark Iron Land Mine", "skull", 10,
    "armed mine; destroy immediately",
    "A mine has little health but can inflict severe group damage if it arms beside the party.",
    { "High-damage explosion" },
    "Switch to it immediately and destroy it from range when possible.",
    "Mechanical", "Do not crowd-control it; destroy it before detonation.")
mob("walkingBomb", 7915, "Walking Bomb", "skull", 10,
    "walking bomb; destroy or disable its chute",
    "Bombs accumulate during Thermaplugg and can overwhelm the party unless killed or stopped at their dispensers.",
    { "Walking detonation" },
    "Destroy approaching bombs and assign a mobile player to press active dispenser buttons.",
    "Mechanical", "Do not rely on ordinary control; destroy it or disable the dispenser spawning it.")
mob("darkIronAgent", 6212, "Dark Iron Agent", "skull", 20,
    "mine layer; kill first",
    "It creates lethal land mines during already dense final-tunnel pulls, so leaving it active compounds the danger.",
    { "Places Dark Iron Land Mines" },
    "Focus the Agent while a ranged player destroys every mine as soon as it appears.",
    "Humanoid", "Polymorph, Sap, Fear, roots, and stuns work when killing it immediately is unsafe.")
mob("burningServant", 7738, "Burning Servant", "skull", 30,
    "summoned fire add; remove quickly",
    "The Ambassador's summon can create more Embers and turn a controlled rare fight into sustained group damage.",
    { "Summon Embers", "Fire attacks" },
    "Pick it up and kill it quickly, then return to the Ambassador.",
    "Elemental", "Banish and verified elemental control may work; killing it prevents further summons.")
mob("arcaneNullifier", 6232, "Arcane Nullifier X-21", "cross", 40,
    "spell reflector; watch its shield",
    "Its reflective shield can return powerful magic to the caster while other final-tunnel enemies remain active.",
    { "Reflective shield", "Heavy mechanical attacks" },
    "Stop offensive casting while the shield is active and use physical attacks until it fades.",
    "Mechanical", "Ordinary humanoid control does not work; avoid testing spells into its reflective shield.")
mob("mechanizedGuardian", 6234, "Mechanized Guardian", "none", 50,
    "armored cleanup machine",
    "It is dangerous when loose but less urgent than mines, Agents, alarms, or a reflecting Nullifier.",
    { "Heavy mechanical attacks" },
    "Keep it on the tank and clean it up after marked enemies.",
    "Mechanical", "Ordinary humanoid and beast control does not work; verified engineering effects may work.")
mob("darkIronAmbassador", 6228, "Dark Iron Ambassador", "circle", 100,
    "rare boss; interrupt and kill summons",
    "The rare is a single target; its Fireball and summoned servant are the mechanics that require attention.",
    { "Fireball", "Fire Shield", "Summon Burning Servant" },
    "Interrupt Fireball, purge Fire Shield when practical, and kill each Burning Servant.",
    "Humanoid", "Boss control is unreliable; interrupts and stuns may work.", {}, true)
mob("thermaplugg", 7800, "Mekgineer Thermaplugg", "circle", 110,
    "final boss; manage bomb dispensers",
    "The fight is decided by Walking Bomb control and safe knockback positioning, not by identifying the boss.",
    { "Knock Away", "Walking Bomb dispensers" },
    "Fight near the outer wall, keep knockbacks away from uncleared mobs, and close active bomb chutes.",
    "Mechanical", "Boss control is unreliable; ordinary humanoid control does not work.", {}, true)

Catalog.RegisterGuide({
    key = "gnomeregan", name = "Gnomeregan", instanceIds = { 90 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "hallOfGears", name = "Hall of Gears & Trogg Caves",
            route = {
                "Use the front entrance, follow the upper path, and take the left detour to Blastmaster Emi Shortfuse before jumping to the irradiated floor.",
                "During Emi's event, fight outside each side cave and leave when she warns of a blast; the collapse can kill or trap players and hide loot.",
                "After Grubbis and Chomper, backtrack to the overlook, descend to the Hall of Gears, clear around Viscous Fallout, then take the west exit.",
            },
            entries = {
                "mobileAlertSystem", "irradiatedPillager", "caverndeepReaver",
                "caverndeepBurrower", "irradiatedHorror", "corrosiveLurker",
                "irradiatedSlime", "grubbis", "chomper", "viscousFallout",
            },
            rules = {
                { title = "Emi's explosives", guidance = "Never fight or loot inside a cave after Emi announces its blast. Pull event enemies out so the collapse cannot trap the party or their corpses." },
                { title = "Irradiated floor", guidance = "Clear a safe pocket before pulling Viscous Fallout. The lower floor has enough nearby slimes and patrols to turn a simple boss into a wipe." },
            },
        },
        {
            key = "dormitoryLaunchBay", name = "Dormitory & Launch Bay",
            route = {
                "Move through the Dormitory toward the Clean Zone. Alliance groups can pause at its friendly NPCs; Horde groups should expect those NPCs to be hostile.",
                "Pull Launch Bay patrols into cleared space and watch both directions for Mobile Alert Systems before committing to each elite pack.",
                "Climb to the central platform for Electrocutioner 6000; loot the Workshop Key, then continue toward the Engineering Labs branch.",
            },
            entries = {
                "mobileAlertSystem", "leprousTechnician", "leprousDefender",
                "mechanizedSentry", "peacekeeper", "mechanoTank", "electrocutioner",
            },
            rules = {
                { title = "Alarm patrols", guidance = "Wait for a Mobile Alert System to enter cleared ground before attacking it. Starting beside another pack can trigger the warning before the group can destroy it." },
                { title = "Workshop Key", guidance = "Keep the key from Electrocutioner 6000. It opens the alternate entrance near the Engineering Labs for later runs and provides a shorter route." },
            },
        },
        {
            key = "engineeringLabs", name = "Engineering Labs",
            route = {
                "From the Launch Bay junction, take the Engineering Labs branch; the Workshop backdoor enters near this chapter when opened with the key or sufficient Lockpicking.",
                "Use the walls and cleared ramps to avoid linking patrols, and keep watching behind the group for Mobile Alert Systems.",
                "Take the south side passage to Crowd Pummeler 9-60, clear its platform, then backtrack to the main route toward Tinkers' Court.",
            },
            entries = {
                "mobileAlertSystem", "leprousMachinesmith", "mechanoFlamewalker",
                "mechanoFrostwalker", "crowdPummeler",
            },
            rules = {
                { title = "Ranged machinesmiths", guidance = "Pull melee machines back around a corner so Machinesmiths must approach. Fighting in the open leaves the pack spread across patrol paths." },
                { title = "Pummeler platform", guidance = "Clear the ledge and nearby patrol path before engaging. Put the tank against a wall so Crowd Pummel cannot throw anyone to the floor below." },
            },
        },
        {
            key = "tinkersCourt", name = "Tinkers' Court",
            route = {
                "Return from the Engineering Labs to the main passage and descend toward the final tunnel; fight on the upper route instead of dropping into uncleared lower packs.",
                "Clear Dark Iron Agents, mines, Nullifiers, guardians, and the optional Ambassador before opening the final hangar door.",
                "Inside Tinkers' Court, fight Thermaplugg near the outer wall and assign a mobile player to close active bomb dispensers while the group destroys missed bombs.",
            },
            entries = {
                "mobileAlertSystem", "darkIronLandMine", "walkingBomb", "darkIronAgent",
                "burningServant", "arcaneNullifier", "mechanizedGuardian",
                "darkIronAmbassador", "thermaplugg",
            },
            rules = {
                { title = "Mine discipline", guidance = "Assign ranged damage to every Dark Iron Land Mine immediately. Do not stack on a mine or continue attacking its Agent while an armed mine remains beside the group." },
                { title = "Reflective shields", guidance = "Watch Arcane Nullifier X-21 before casting. Pause offensive magic during its reflective shield and let physical attacks carry the target until it fades." },
                { title = "Bomb controls", guidance = "A dispenser's nearby button closes it temporarily. Keep one mobile player on buttons while everyone switches to any Walking Bomb that reaches the group." },
            },
        },
    },
})
