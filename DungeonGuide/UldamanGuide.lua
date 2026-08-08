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
mob("shadowforgeDarkcaster", 4848, "Shadowforge Darkcaster", "skull", 10,
    "Spell Bomb punishes every cast; kill first",
    "Spell Bomb damages its target whenever they cast, while Shadow Bolt Volley adds party-wide pressure in the deep halls.",
    { "Spell Bomb", "Shadow Bolt", "Shadow Bolt Volley" },
    "Interrupt the Darkcaster, and if Spell Bomb lands, stop casting until it expires; do not heal through repeated triggers.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("stonevaultOracle", 4852, "Stonevault Oracle", "skull", 20,
    "heals and drops dangerous totems; kill first",
    "Healing Wave extends runner-heavy pulls, while Healing Ward and Lava Spout Totem add healing or area fire until destroyed.",
    { "Healing Wave", "Healing Ward", "Lava Spout Totem", "Lightning Shield" },
    "Pull it around a corner, destroy Lava Spout and Healing Wards, interrupt Healing Wave, and prevent its low-health escape.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, interrupts, and other humanoid control work.")
mob("stonevaultFlameweaver", 7321, "Stonevault Flameweaver", "skull", 30,
    "deep-hall fire caster and runner; kill first",
    "Flame Spike threatens a stacked group, while Fireball and Flame Shield add pressure in the narrow approach to the final halls.",
    { "Flame Spike", "Fireball", "Flame Shield" },
    "Line-of-sight it into the cleared room, interrupt Flame Spike first, move from lingering fire, and snare it before it flees.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("shadowforgeGeologist", 7030, "Shadowforge Geologist", "skull", 40,
    "Flame Spike makes Galgann's pull lethal; kill first",
    "Two Geologists accompany Galgann, and their area fire combines with his Fire Nova and fire-vulnerability effects.",
    { "Flame Spike", "Fireball" },
    "Control one when possible, focus the other before Galgann, interrupt Flame Spike, and move immediately from ground fire.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("obsidianShard", 7209, "Obsidian Shard", "skull", 50,
    "Sentinel add; switch immediately",
    "Obsidian Sentinel releases Shards at health thresholds, adding loose targets and healer pressure until they are removed.",
    {},
    "Let the tank collect each Shard wave, focus the Shards, then return to the Sentinel after the healer is safe.",
    "Mechanical", "Use roots, slows, or stuns only if they land; direct control on constructs is unreliable.")
mob("earthenHallshaper", 7077, "Earthen Hallshaper", "skull", 60,
    "Archaedas caster add; switch immediately",
    "Archaedas awakens Hallshapers during the fight, and allowing them to accumulate overwhelms the party before later add waves.",
    { "Fireball", "Healing Wave" },
    "Have damage dealers switch to each Hallshaper while the tank holds Archaedas; interrupt healing and fire casts.",
    "Humanoid", "Stuns, interrupts, silences, and humanoid control work, but fast focus fire is safer during Archaedas.")

-- Secondary threats and control
mob("shrikeBat", 4861, "Shrike Bat", "cross", 70,
    "area silence threatens the healer; kill second",
    "Sonic Burst silences nearby players, which can remove healing during wildlife pulls or while another enemy is active.",
    { "Sonic Burst" },
    "Tank it away from the healer and ranged casters, interrupt when possible, and kill it after the primary caster threat.",
    "Beast", "Hibernate, Polymorph, Fear, roots, stuns, and other beast control work.")
mob("stoneSteward", 4860, "Stone Steward", "cross", 80,
    "patrolling construct with knockdown and death burst",
    "Ground Tremor disrupts the party, and Self Destruct punishes melee who remain beside the Steward as it reaches low health.",
    { "Ground Tremor", "Self Destruct" },
    "Separate it from linked Earthen, keep the healer at range, and have non-tanks step away before it dies.",
    "Elemental", "Banish can hold an elemental; other control is unreliable, so isolate it with patrol timing.")
mob("earthenSculptor", 7012, "Earthen Sculptor", "cross", 90,
    "Flame Buffet amplifies incoming fire; kill second",
    "Repeated Flame Buffet increases fire damage taken, making linked Earthen groups dangerous when a caster remains active.",
    { "Flame Buffet", "Flame Shield" },
    "Focus the Hallshaper first, interrupt the Sculptor when possible, and avoid carrying fire vulnerability into the next pull.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("stoneKeeper", 4857, "Stone Keeper", "cross", 100,
    "altar guardian; recover between each activation",
    "Four elite Keepers awaken in sequence, using area knockdowns and a low-health Self Destruct before the final door opens.",
    { "Minor Tremor", "Self Destruct" },
    "Fight each Keeper in the cleared antechamber, step away before it dies, and use the travel gap to restore health and mana.",
    "Elemental", "Banish can pause an elemental, but the event advances by killing each Keeper in sequence.")
mob("earthenGuardian", 7076, "Earthen Guardian", "cross", 110,
    "Archaedas threshold wave; gather and clear",
    "Archaedas awakens the six Guardians together, creating the first large add spike of the final encounter.",
    { "Whirlwind" },
    "Stack near the tank before the threshold, gather the Guardians quickly, and use controlled area damage before resuming the boss.",
    "Humanoid", "Stuns, roots, and humanoid control work; keep loose Guardians away from the healer.")
mob("vaultWarder", 10120, "Vault Warder", "cross", 120,
    "final Archaedas wave; keep off the healer",
    "The two elite Warders awaken late and can overwhelm the healer while the party is trying to finish Archaedas.",
    { "Trample" },
    "Pick up both Warders immediately, use control or kiting to limit damage, and focus Archaedas once threat is stable.",
    "Elemental", "Banish, roots, slows, and stuns can buy time; do not let a Warder reach the healer.")
mob("jadespineBasilisk", 4863, "Jadespine Basilisk", "none", 130,
    "manual control prevents Crystalline Slumber",
    "Crystalline Slumber removes a party member from the fight and is most dangerous when the Basilisk accompanies Grimlok.",
    { "Crystalline Slumber" },
    "Control it before Grimlok's pull when possible, interrupt the sleep, and kill it after the boss and Geomancer.",
    "Beast", "Hibernate, Polymorph, Fear, roots, and stuns work; keep manual control away from area damage.",
    { "Skip control when the Basilisk is alone and the pull is already stable." })
mob("stonevaultBrawler", 4855, "Stonevault Brawler", "none", 140,
    "durable runner; snare and clean up late",
    "Brawlers flee at low health and Enrage, but caster healing and area damage are more urgent in their mixed packs.",
    { "Enrage" },
    "Keep it on the tank, snare it before low health, and finish it after marked casters without chasing into another group.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")

-- Bosses
mob("ericTheSwift", 6907, "Eric \"The Swift\"", "circle", 200,
    "Lost Dwarves interrupter; protect the healer",
    "Eric moves quickly and uses Intercept to stun a distant target, disrupting control of the three-dwarf encounter.",
    { "Intercept" },
    "Keep the group close, pick Eric up after an Intercept, and focus one dwarf at a time without spreading damage.",
    "Humanoid", "Boss control is unreliable; use stuns, slows, and focused damage.",
    { "Alliance groups meet the Lost Dwarves as friendly quest NPCs; Horde groups fight the trio." }, true)
mob("olaf", 6908, "Olaf", "circle", 210,
    "Lost Dwarves knockdown threat; keep on the tank",
    "Olaf's Shield Slam knocks down its target while Eric and Baelog continue attacking during the linked encounter.",
    { "Shield Slam" },
    "Keep Olaf faced into the tank, recover from the knockdown, and maintain one-target focus across the trio.",
    "Humanoid", "Boss control is unreliable; use stuns and mitigation.",
    { "Alliance groups meet the Lost Dwarves as friendly quest NPCs; Horde groups fight the trio." }, true)
mob("baelog", 6906, "Baelog", "circle", 220,
    "Lost Dwarves ranged boss; finish the trio safely",
    "Baelog attacks from range while Eric and Olaf occupy the tank, making split positioning more dangerous than his own abilities.",
    {},
    "Use line of sight if Baelog stays at range, keep all hostile dwarves on the tank, and finish one target at a time.",
    "Humanoid", "Boss control is unreliable; use line of sight and focused damage.",
    { "Alliance groups meet the Lost Dwarves as friendly quest NPCs; Horde groups fight the trio." }, true)
mob("revelosh", 6910, "Revelosh", "circle", 230,
    "linked caster boss; spread for Chain Lightning",
    "Revelosh arrives with two Rockchewers and can chain lightning through players who remain stacked together.",
    { "Chain Lightning", "Lightning Bolt" },
    "Control or tank the Rockchewers, spread loosely, interrupt lightning casts, and keep the Shaft of Tsol with the medallion holder.",
    "Humanoid", "Boss control is unreliable; control the linked Rockchewers instead.", {}, true)
mob("ironaya", 7228, "Ironaya", "circle", 240,
    "hidden-chamber boss; face away and recover threat",
    "Arcing Smash cleaves the group, War Stomp disrupts nearby players, and Knock Away sheds the tank's threat.",
    { "Arcing Smash", "War Stomp", "Knock Away" },
    "Face her away, keep ranged players back, and save taunt or threat tools to recover immediately after Knock Away.",
    "Giant", "Boss control is unreliable; use positioning, threat recovery, and mitigation.", {}, true)
mob("obsidianSentinel", 7023, "Obsidian Sentinel", "circle", 250,
    "optional back-door boss; manage Shard waves",
    "The Sentinel releases Obsidian Shards at health thresholds, and leaving them loose compounds damage on the healer.",
    { "Splintered Obsidian", "Summon Obsidian Shard" },
    "Fight in cleared space, switch to every Shard wave, and return to the Sentinel only after the adds are controlled.",
    "Mechanical", "Boss control is unreliable; physical damage and add control provide dependable progress.", {}, true)
mob("ancientStoneKeeper", 7206, "Ancient Stone Keeper", "circle", 260,
    "room boss; clear linked packs and avoid Sand Storms",
    "Sand Storms create moving hazards that heavily slow and silence players, especially endangering the healer.",
    { "Sand Storms" },
    "Clear the room methodically, keep the healer at range, and move out of every storm instead of trying to cast through it.",
    "Elemental", "Boss control is unreliable; movement and room preparation are the safe counters.", {}, true)
mob("galgann", 7291, "Galgann Firehammer", "circle", 270,
    "fire boss with two Geologists; kill adds first",
    "Fire Nova and multiple fire-vulnerability effects become lethal when his Geologists are also casting Flame Spike.",
    { "Flame Shock", "Amplify Flames", "Flame Lash", "Fire Nova" },
    "Control one Geologist, kill the other, remove magic effects when available, and keep ranged players outside Fire Nova.",
    "Humanoid", "Boss control is unreliable; control and interrupt the Geologists instead.", {}, true)
mob("grimlok", 4854, "Grimlok", "circle", 280,
    "four-enemy boss pack; control adds and focus boss",
    "Shrink reduces Strength and Stamina while Chain Bolt punishes stacking, and his three companions begin active.",
    { "Shrink", "Lightning Bolt", "Chain Bolt", "Bloodlust" },
    "Control the Basilisk or Brawler, spread loosely, focus Grimlok, then kill the Geomancer before remaining melee.",
    "Humanoid", "Boss control is unreliable; use humanoid or beast control on his companions.", {}, true)
mob("archaedas", 2748, "Archaedas", "circle", 290,
    "final boss; manage awaken waves and protect healer",
    "Ground Tremor interrupts the party while Hallshapers, six Guardians, and two elite Warders awaken as his health falls.",
    { "Ground Tremor", "Awaken Earthen Guardians", "Awaken Vault Warder" },
    "Kill Hallshapers, gather the Guardian wave, secure both Warders late, and finish Archaedas once healer threat is safe.",
    "Giant", "Boss control is unreliable; control awakened adds and use mitigation on the boss.", {}, true)

local function overviewMap()
    return {
        texture = "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\DungeonGuide\\Uldaman.png",
        width = 2048, height = 2048,
        caption = "Gold route — dashed alternate — orange optional; numbers show boss order",
        description = "Complete Uldaman overview from the front entrance through the keeper halls, Map Chamber and back door, Temple Hall, Stone Vault, Hall of the Crafters, and Archaedas vault.",
    }
end

Catalog.RegisterGuide({
    key = "uldaman", name = "Uldaman", instanceIds = { 70 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "hallOfKeepers", name = "Hall of the Keepers", map = overviewMap(),
            route = {
                "Enter through the front portal, clear both keeper hallways, and pull into cleared tunnels; skipping a side can send runners or pet paths through untouched packs.",
                "Wait for Stonevault Ambusher patrols, reveal Cave Lurkers carefully, and use corners to bring Oracles and ranged troggs onto the tank.",
                "Clear Dig Two before approaching the Lost Dwarves. Alliance groups speak with the trio; Horde groups fight them and then loot the table chest.",
                "Take the Gni'kiv Medallion from the chest, continue to Revelosh, and give the Shaft of Tsol to the same player before returning toward the Map Chamber.",
            },
            entries = {
                "stonevaultOracle", "ericTheSwift", "olaf", "baelog", "revelosh",
            },
            rules = {
                { title = "Runners and corners", guidance = "Snare Stonevault and Shadowforge enemies before low health, and pull ranged enemies around corners so a fleeing target cannot reach the next room." },
                { title = "Lost Dwarves", guidance = "The trio is friendly to Alliance groups and hostile to Horde groups. In either case, loot the table chest for the Gni'kiv Medallion before leaving." },
                { title = "Pet pathing", guidance = "Do not jump the keeper-hall debris with an active pet. Dismiss it or take the cleared route so it does not run through the uncleared opposite hall." },
            },
        },
        {
            key = "mapChamberBackDoor", name = "Map Chamber & Back Door", map = overviewMap(),
            route = {
                "Return from Revelosh with both Staff components, clear the Map Chamber from the stairs, and watch for fast Ambushers and stealthed Cave Lurkers.",
                "Combine the Gni'kiv Medallion and Shaft of Tsol into the Staff of Prehistoria, then place it in the chamber model to release Ironaya.",
                "After Ironaya, clear bats, basilisks, and scorpids from a safe camp room; take the southern scorpid detour only if an Enchanter needs Annora.",
                "Clear the Shadowforge groups toward the rear entrance, isolate linked Earthen from the Stone Steward patrol, and defeat optional Obsidian Sentinel beside the back door.",
            },
            entries = {
                "obsidianShard", "shrikeBat", "stoneSteward", "earthenSculptor",
                "jadespineBasilisk", "ironaya", "obsidianSentinel",
            },
            rules = {
                { title = "Staff ownership", guidance = "One player must hold both components to create the Staff of Prehistoria. Confirm the Staff exists before the group commits to the Map Chamber event." },
                { title = "Annora detour", guidance = "Annora appears after the scorpids in her southern cavern are cleared. Visit only when needed, then return to the established camp and main route." },
                { title = "Ironaya recovery", guidance = "Clear the chamber before using the Staff, face Ironaya away from the party, and reserve taunt or threat tools for her Knock Away threat loss." },
                { title = "Back-door orientation", guidance = "Obsidian Sentinel guards the interior rear entrance. Record the junction before continuing so a later quest or trainer run can use the shortcut." },
            },
        },
        {
            key = "templeStoneVault", name = "Temple Hall & Stone Vault", map = overviewMap(),
            route = {
                "Backtrack from the rear entrance and pull Shadowforge packs into the bat ledge room; never fight Darkcasters and Archaeologists inside the crowded northern room.",
                "Clear to Galgann along the wall, control one Geologist, and kill both fire casters before continuing through the linked Earthen halls.",
                "Time Stone Steward patrols, clear each linked Earthen group in safe space, and fully prepare the Ancient Stone Keeper room before engaging the boss.",
                "Return through the southern connection into the Stone Vault, pull Flameweavers and Maulers back through doorways, then clear Grimlok's entire approach.",
            },
            entries = {
                "shadowforgeDarkcaster", "stonevaultFlameweaver", "shadowforgeGeologist",
                "shrikeBat", "stoneSteward", "earthenSculptor", "jadespineBasilisk",
                "stonevaultBrawler", "ancientStoneKeeper", "galgann", "grimlok",
            },
            rules = {
                { title = "Spell Bomb", guidance = "Treat Spell Bomb as a silence: the affected player stops casting until it expires. Interrupt and kill Darkcasters before other Shadowforge enemies." },
                { title = "Construct deaths", guidance = "Keep the healer at range from Stone Stewards, and have non-tanks step away at low health so Self Destruct cannot punish the whole party." },
                { title = "Keeper room", guidance = "Do not charge through the Ancient Stone Keeper room. Separate linked Earthen and patrolling Stewards in cleared space before engaging the boss." },
                { title = "Grimlok's pack", guidance = "Assign manual control before pulling. Focus Grimlok, then the Geomancer, while keeping the Basilisk or Brawler controlled away from area damage." },
            },
        },
        {
            key = "hallOfCrafters", name = "Hall of the Crafters", map = overviewMap(),
            route = {
                "From Grimlok, clear Flameweavers and Maulers through the eastern tunnel, then use the small room to pull each linked Earthen group from the Hall of the Crafters.",
                "Restore health, mana, and buffs before at least four players activate the central altar; fight the four Stone Keepers one at a time and recover during each travel gap.",
                "Clear every group beyond the opened door, stop before the final altar, and assign Hallshaper switches plus Guardian and Warder pickup responsibilities.",
                "Activate Archaedas only when everyone is ready, manage each awaken wave, then enter the rear vault after the boss dies for the Platinum Discs event.",
            },
            entries = {
                "stonevaultFlameweaver", "earthenHallshaper", "stoneSteward",
                "stoneKeeper", "earthenGuardian", "vaultWarder", "archaedas",
            },
            rules = {
                { title = "Altar sequence", guidance = "At least four players must activate the altar. Retreat to the cleared antechamber, kill each Keeper, step away from Self Destruct, and recover between waves." },
                { title = "Final readiness", guidance = "Do not touch Archaedas's altar until the approach is clear, mana and buffs are restored, and every player knows the add-switch and healer-protection plan." },
                { title = "Archaedas waves", guidance = "Kill periodic Hallshapers, gather the six Guardians at roughly two-thirds health, then secure the two elite Warders near one-third before finishing Archaedas." },
                { title = "Healer protection", guidance = "Awakened adds seek exposed support players. Stack the wave near the tank, use control on loose Warders, and stabilize threat before committing to the boss burn." },
            },
        },
    },
})
