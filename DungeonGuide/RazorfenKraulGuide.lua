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

-- Summons and totems
mob("earthgrabTotem", 6066, "Earthgrab Totem", "skull", 10,
    "repeated roots can strand the party; destroy now",
    "Repeated roots can hold players beside patrols or keep melee away from the active kill target.",
    { "Earthgrab roots" },
    "Switch immediately and destroy the low-health totem before resuming the pack.",
    "Totem", "Do not crowd-control it; destroy it immediately.")
mob("healingWard", 2992, "Healing Ward V", "skull", 10,
    "healing totem; destroy immediately",
    "Its repeated healing prolongs dangerous caster packs and can erase progress on the marked target.",
    { "Area healing" },
    "Destroy the ward immediately, then return to the healer or primary caster.",
    "Totem", "Do not crowd-control it; destroy it immediately.")
mob("lavaSpoutTotem", 6017, "Lava Spout Totem", "skull", 10,
    "fire totem; move out and destroy immediately",
    "Its repeated area damage rapidly pressures the group when narrow paths limit safe movement.",
    { "Repeated fire pulses" },
    "Move out of its pulse area and destroy the totem before returning to the Seer.",
    "Totem", "Do not crowd-control it; destroy it from range when practical.")
mob("boarSpirit", 6021, "Boar Spirit", "skull", 10,
    "Aggem summon; kill before more accumulate",
    "Aggem can summon several spirits and strengthen them, turning a simple boss into an add swarm.",
    { "Summoned add", "Benefits from Battle Shout" },
    "Kill each spirit as it appears, then return to Aggem before another summon completes.",
    "Beast", "Hibernate, Scare Beast, roots, and slows work when an immediate kill is unsafe.")

-- Priority quilboar and Death's Head casters
mob("razorfenTotemic", 4440, "Razorfen Totemic", "skull", 20,
    "healing and root totems; kill first",
    "It repeatedly creates Healing Wards and Earthgrab Totems that disrupt positioning and extend the pull.",
    { "Healing Ward V", "Earthgrab Totem" },
    "Focus the Totemic while switching immediately to every ward or root totem it drops.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("deathsHeadPriest", 4517, "Death's Head Priest", "skull", 30,
    "direct healer; interrupt and kill first",
    "Heal restores allies while Shadow Bolt adds ranged pressure from outside the tank's melee cluster.",
    { "Heal", "Shadow Bolt", "Power Word: Fortitude" },
    "Line-of-sight the pull, interrupt Heal, and focus the Priest before durable melee enemies.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")
mob("deathsHeadSage", 4518, "Death's Head Sage", "skull", 40,
    "support caster; destroy its wards and kill",
    "Healing and protection totems strengthen an entire pack while the Sage remains at casting range.",
    { "Healing Ward V", "Elemental Protection Totem" },
    "Pull around a corner, destroy every ward, and kill the Sage before working through melee targets.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")
mob("deathsHeadSeer", 4519, "Death's Head Seer", "skull", 50,
    "healing and fire totems; remove first",
    "Healing Ward and Lava Spout Totem combine sustain with dangerous area damage in cramped spaces.",
    { "Healing Ward V", "Lava Spout Totem" },
    "Focus the Seer and immediately destroy every healing or fire totem it creates.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")
mob("wardGuardian", 4427, "Ward Guardian", "skull", 60,
    "Agathelos healer; interrupt and kill first",
    "Two Guardians protect the ward and can heal each other, making split damage ineffective.",
    { "Healing Wave" },
    "Interrupt one Guardian while the group focuses the other, then finish the remaining healer.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")

-- Secondary threats and control targets
mob("deathsHeadAdept", 4516, "Death's Head Adept", "cross", 70,
    "rooting caster; kill after Skull",
    "Chains of Ice can root melee away from a caster pack while Frostbolt keeps the Adept at range.",
    { "Chains of Ice", "Frostbolt" },
    "Line-of-sight it into the tank, interrupt casts, and kill it after the primary support threat.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")
mob("razorfenDustweaver", 4522, "Razorfen Dustweaver", "cross", 80,
    "long incapacitate; kill after Skull",
    "Enveloping Winds can remove the healer for ten seconds and destabilize an otherwise safe pull.",
    { "Enveloping Winds", "Wind Howler companion" },
    "Interrupt or stun its cast, keep backup healing ready, and kill it after the primary threat.",
    "Humanoid", "Polymorph, Sap, Fear, silence, stuns, and other humanoid control work.")
mob("razorfenGroundshaker", 4523, "Razorfen Groundshaker", "cross", 90,
    "area knockdown; avoid fighting two together",
    "Ground Tremor can knock down the party and expose healers or casters to follow-up attacks.",
    { "Ground Tremor", "Earth Shock" },
    "Pull Groundshakers separately, spread when space permits, and kill after the Skull target.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, and other humanoid control work.")
mob("razorfenEarthbreaker", 4525, "Razorfen Earthbreaker", "cross", 100,
    "casting-speed curse; kill after Skull",
    "Mind Tremor can slow the healer's casting for ten minutes and make later bridge pulls much harder.",
    { "Mind Tremor" },
    "Focus after the primary threat and remove the curse promptly when the group can dispel it.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, and other humanoid control work.")
mob("razorfenSpearhide", 4438, "Razorfen Spearhide", "cross", 110,
    "Ramtusk guard; control or kill before boss",
    "Two Spearhides flank Ramtusk and combine heavy melee with damaging area attacks and Thorns.",
    { "Whirling Barrage", "Thorns Aura" },
    "Control one or both when possible; otherwise kill active guards while the tank holds Ramtusk.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("quilguardChampion", 4623, "Quilguard Champion", "cross", 120,
    "armored support; isolate paired patrols",
    "Its armor aura and Sunder Armor strengthen paired bridge patrols and increase tank damage taken.",
    { "Devotion Aura", "Sunder Armor", "Defensive Stance" },
    "Pull paired Champions into cleared space, keep both on the tank, and focus one at a time.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("greaterKraulBat", 4539, "Greater Kraul Bat", "cross", 130,
    "area silence; keep away from casters",
    "Sonic Burst can silence the healer and every nearby caster during the final cavern pulls.",
    { "Sonic Burst" },
    "Tank it away from the healer and ranged casters, then kill it after the primary threat.",
    "Beast", "Hibernate, Scare Beast, roots, slows, and other beast control work.")
mob("razorfenBeastTrainer", 4531, "Razorfen Beast Trainer", "none", 140,
    "control one ranged trainer in a pet pack",
    "Controlling one ranged attacker helps the tank establish threat on its battle boar and nearby enemies.",
    { "Frost Shot", "Shoot", "Tamed Battleboar companion" },
    "Keep it controlled away from area damage, kill urgent support, then clean up the trainer and pet.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.",
    { "Skip control when the pull is small enough to tank safely." })
mob("razorfenDefender", 4442, "Razorfen Defender", "none", 150,
    "durable melee cleanup",
    "Defensive Stance and blocking make it slow to kill but less urgent than healers, totems, or control casters.",
    { "Defensive Stance", "Improved Blocking", "Shield Bash" },
    "Keep it on the tank and clean it up after marked enemies.",
    "Humanoid", "Normal humanoid control works when a large pull needs another target removed.")
mob("kraulBat", 4538, "Kraul Bat", "none", 160,
    "routine bat-cavern cleanup",
    "It is less dangerous than Greater Kraul Bats and should not distract the group from silence positioning.",
    { "Bat melee attacks" },
    "Pull bats singly when practical, keep them off casters, and clean them up after marked threats.",
    "Beast", "Hibernate, Scare Beast, roots, slows, and other beast control work.")

-- Bosses
mob("roogug", 6168, "Roogug", "circle", 200,
    "optional boss; control his linked pack",
    "Roogug arrives with an Adept, Defender, and elemental, making the linked enemies more dangerous than the boss.",
    { "Lightning Bolt", "Summon Earth Rumbler" },
    "Control what the group can, kill the Adept first, interrupt Lightning Bolt, then focus Roogug.",
    "Humanoid", "Boss control is unreliable; use interrupts and mitigation.", {}, true)
mob("aggemThorncurse", 4424, "Aggem Thorncurse", "circle", 210,
    "boss; interrupt healing and kill spirits",
    "Aggem can heal allies and repeatedly summon Boar Spirits that become dangerous if allowed to accumulate.",
    { "Summon Boar Spirit", "Heal", "Battle Shout" },
    "Clear the trainers, interrupt healing, and kill every Boar Spirit before returning to Aggem.",
    "Humanoid", "Boss control is unreliable; interrupts and stuns may work.", {}, true)
mob("deathSpeakerJargba", 4428, "Death Speaker Jargba", "circle", 220,
    "boss; control casters and stop mind control",
    "Jargba's two caster allies and Dominate Mind can remove a party member while Shadow Bolts pressure the group.",
    { "Dominate Mind", "Shadow Bolt", "Two caster allies" },
    "Control at least one ally, interrupt Jargba, and burn the boss before cleaning up controlled casters.",
    "Humanoid", "Boss control is unreliable; control Jargba's humanoid allies instead.", {}, true)
mob("overlordRamtusk", 4420, "Overlord Ramtusk", "circle", 230,
    "boss; control Spearhides and protect the tank",
    "Ramtusk deals heavy melee damage while two Spearhides add area attacks and Thorns retaliation.",
    { "Thunderclap", "Battle Shout", "Two Spearhide guards" },
    "Control the guards when possible, keep Ramtusk on the tank, and finish active Spearhides before cleanup.",
    "Humanoid", "Boss control is unreliable; use humanoid control on the Spearhides.", {}, true)
mob("earthcallerHalmgar", 4842, "Earthcaller Halmgar", "circle", 240,
    "rare boss; destroy totems and control elemental",
    "Halmgar begins in a dense platform pack and uses roots to hold players while he casts from range.",
    { "Earthbind Totem", "Lightning Bolt", "Summon Earth Rumbler" },
    "Clear the platform, destroy every totem, Banish the elemental when available, and interrupt Lightning Bolt.",
    "Humanoid", "Boss control is unreliable; Banish may control the summoned elemental.", {}, true)
mob("blindHunter", 4425, "Blind Hunter", "circle", 250,
    "rare boss; keep its silence away from casters",
    "Sonic Burst can silence the healer and ranged group if the rare is tanked in the middle of the party.",
    { "Sonic Burst", "Ravage" },
    "Tank it away from casters, stop casting before the burst, and keep steady healing on its target.",
    "Beast", "Boss control is unreliable; use mitigation and safe spacing.", {}, true)
mob("agathelos", 4422, "Agathelos the Raging", "circle", 260,
    "boss; stay clear of knockdown and stun Enrage",
    "Rampage can knock down nearby players, and the final Enrage creates the fight's sharpest tank damage.",
    { "Rushing Charge", "Rampage", "Enrage" },
    "Keep casters at range, stabilize after knockdowns, and use stuns or cooldowns during low-health Enrage.",
    "Beast", "Boss control is unreliable; stuns may work when accepted.", {}, true)
mob("charlgaRazorflank", 4421, "Charlga Razorflank", "circle", 270,
    "final boss; pull from hut and interrupt casts",
    "Chain Bolt pressures stacked players while Renew and Purity can extend the fight if casts go unanswered.",
    { "Chain Bolt", "Renew", "Purity" },
    "Interrupt from range, pull Charlga onto the lower landing, spread out, and maintain an interrupt order.",
    "Humanoid", "Boss control is unreliable; interrupts are the dependable answer.", {}, true)

Catalog.RegisterGuide({
    key = "razorfenKraul", name = "Razorfen Kraul", instanceIds = { 47 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "firstForkRoogug", name = "First Fork & Roogug Detour",
            route = {
                "Enter Razorfen Kraul west of the Great Lift, clear the opening patrol away from the first fork, and keep fleeing quilboar inside cleared ground.",
                "Take the first tunnel left for the optional Roogug full-clear detour, then follow the passage to the broad vine bridge that crosses the ravine.",
                "Clear Roogug's landing in small pulls; his final group is linked, so control an extra humanoid and remove the Adept before the boss.",
                "After Roogug, cross the vine back and return to the first fork; take the eastern passage to resume the main route.",
            },
            entries = {
                "earthgrabTotem", "healingWard", "razorfenTotemic",
                "deathsHeadAdept", "razorfenBeastTrainer", "razorfenDefender", "roogug",
            },
            rules = {
                { title = "Fleeing quilboar", guidance = "Fight toward cleared ground and slow or stun low-health humanoids. A runner reaching a hidden tunnel pack can turn a small pull into a wipe." },
                { title = "Roogug's linked group", guidance = "Do not expect a clean boss pull. Assign control before engaging and kill the rooting Adept while the tank gathers Roogug, his Defender, and elemental." },
            },
        },
        {
            key = "trenchesWillix", name = "Trenches & Willix Escort",
            route = {
                "From the first fork, take the eastern path, separate the Defender patrol from nearby casters, then turn into the trenches.",
                "Clear roaming boars and Blood of Agamaggan one at a time; remove long curses and use tunnel corners to pull ranged enemies into the tank.",
                "Clear the ramp, wardens, priests, and hut around Willix before starting the escort; do not begin while patrols or side packs remain alive.",
                "Escort Willix back to the instance entrance, protect him during scripted attacks, then backtrack to the trench entrance and take the northern route.",
            },
            entries = {
                "deathsHeadPriest", "deathsHeadAdept", "razorfenGroundshaker",
                "razorfenDefender",
            },
            rules = {
                { title = "Line-of-sight pulls", guidance = "Use tunnel corners to force priests and Adepts into melee. Charging into their room risks patrols and enemies positioned above the path." },
                { title = "Willix escort", guidance = "Pre-clear the route, let Willix set the pace, and keep threat off him during each ambush. Return to the trenches after he reaches the entrance." },
            },
        },
        {
            key = "highLedgesWarlords", name = "High Ledges & Warlords",
            route = {
                "Take the northern route from the trenches, stay in the center beneath the first ledges, and pull enemies down before climbing the three-way ramp.",
                "Clear the southern ledge and Beast Trainers before Aggem, then return to the ramp and clear the northern ledge for Jargba.",
                "Move west from the ramp, pull Sages around the corner, and clear paired Champions before approaching Ramtusk's upper ledge.",
                "After Ramtusk, follow the lower western passage, clear every cubby, and prepare before crossing the next vine toward Halmgar's platform.",
            },
            entries = {
                "earthgrabTotem", "healingWard", "lavaSpoutTotem", "boarSpirit",
                "razorfenTotemic", "deathsHeadPriest", "deathsHeadSage", "deathsHeadSeer",
                "deathsHeadAdept", "razorfenDustweaver", "razorfenGroundshaker",
                "razorfenSpearhide", "quilguardChampion", "razorfenBeastTrainer",
                "razorfenDefender", "aggemThorncurse", "deathSpeakerJargba", "overlordRamtusk",
            },
            rules = {
                { title = "Ledge discipline", guidance = "Pull down whenever possible and never fight two Groundshakers together. If the ledge chains, retreat or drop to cleared ground instead of standing in place." },
                { title = "Totem priority", guidance = "Switch immediately to healing, root, and fire totems. Killing a low-health totem is faster and safer than trying to out-damage its effect." },
                { title = "Ramtusk's guards", guidance = "Assign humanoid control to both Spearhides when possible. If control is limited, keep Ramtusk tanked while the group kills one active guard at a time." },
            },
        },
        {
            key = "bridgesBatCavern", name = "Long Bridges & Bat Cavern",
            route = {
                "Clear Halmgar's crowded platform after the first vine, then pull hidden Champions back onto the bridge before crossing the remaining spans.",
                "Enter the Bat Cavern slowly, keep bats away from casters, and check the rare spawn point for Blind Hunter while clearing toward the southern ward.",
                "Kill the Seer and two Ward Guardians, then kill both non-aggressive Ward Keepers to lower the barrier before entering Agathelos's tunnel.",
                "Return to the Bat Cavern, take the northwest ramp, clear the final patrols, then interrupt Charlga from range and pull her down from the hut.",
            },
            entries = {
                "earthgrabTotem", "healingWard", "lavaSpoutTotem",
                "razorfenTotemic", "deathsHeadSage", "deathsHeadSeer", "wardGuardian",
                "razorfenDustweaver", "razorfenEarthbreaker", "quilguardChampion",
                "greaterKraulBat", "razorfenBeastTrainer", "razorfenDefender", "kraulBat",
                "earthcallerHalmgar", "blindHunter", "agathelos", "charlgaRazorflank",
            },
            rules = {
                { title = "Bridge patrols", guidance = "Rest before each span and pull hidden or wandering Champions back to the last cleared platform. Do not fight while exposed to the next landing." },
                { title = "Bat silence", guidance = "Tank Greater Kraul Bats away from the healer and ranged casters. Stop casting for Blind Hunter's burst instead of losing a critical heal to silence." },
                { title = "Agathelos ward", guidance = "Kill the Seer first, interrupt and focus the two healing Guardians, then kill both passive Ward Keepers to remove the barrier." },
                { title = "Charlga interrupts", guidance = "Start with a ranged interrupt, bring Charlga onto the lower landing, spread for Chain Bolt, and assign an interrupt order for Renew and follow-up casts." },
            },
        },
    },
})
