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
mob("sandfuryShadowhunter", 7246, "Sandfury Shadowhunter", "skull", 10,
    "Hex drops tank threat; interrupt or kill first",
    "Hex removes its target from the fight and makes every enemy abandon a hexed tank for the rest of the party.",
    { "Hex", "Shoot" },
    "Interrupt or dispel Hex immediately, line-of-sight the bow, and kill the Shadowhunter before durable melee enemies.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("sandfuryWitchDoctor", 5650, "Sandfury Witch Doctor", "skull", 20,
    "heals and dangerous wards; kill first",
    "Flash Heal and Healing Ward prolong every pull, while Lava Spout Totem deals persistent area damage until destroyed.",
    { "Flash Heal", "Healing Ward", "Lava Spout Totem" },
    "Pull it around a corner, destroy hostile wards, interrupt healing, and kill it before Blood Drinkers.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, interrupts, and other humanoid control work.")
mob("sandfurySoulEater", 7247, "Sandfury Soul Eater", "skull", 30,
    "heals allies and drains players; kill first",
    "Dark Offering heals an ally, while Soul Bite restores the Soul Eater by draining both health and mana.",
    { "Dark Offering", "Soul Bite" },
    "Interrupt Dark Offering, stop Soul Bite when possible, and focus the Soul Eater before melee cleanup.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("sandfuryShadowcaster", 5648, "Sandfury Shadowcaster", "skull", 40,
    "ranged shadow caster; interrupt and stack",
    "Repeated shadow casts create avoidable ranged pressure and keep the caster beside patrols unless line of sight is used.",
    { "Shadow Bolt", "Shadow Bolt Volley" },
    "Hide behind a wall to bring it to the tank, interrupt its casts, and kill it before routine melee enemies.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, silences, and other humanoid control work.")
mob("wardOfZumrah", 7785, "Ward of Zum'rah", "skull", 50,
    "boss ward; switch immediately",
    "Zum'rah's ward adds avoidable pressure while the boss heals, volleys the party, and calls nearby dead to fight.",
    {},
    "Destroy each ward as it appears, then return to interrupts and summoned undead before resuming boss damage.",
    "Totem", "Wards cannot be controlled; destroy them immediately.")
mob("murtaGrimgut", 7608, "Murta Grimgut", "skull", 60,
    "Bly ally healer; interrupt and kill first",
    "If Sergeant Bly turns hostile, Murta's healing can sustain the entire mercenary party while Oro pressures the group.",
    { "Heal" },
    "After the betrayal begins, interrupt Murta and kill her before Oro and Bly; do not attack the party before the event ends.",
    "Humanoid", "Polymorph, Sap, Fear, stuns, interrupts, and other humanoid control work.")

-- Secondary threats and control
mob("sandfuryBloodDrinker", 5649, "Sandfury Blood Drinker", "cross", 70,
    "durable life-draining melee; kill second",
    "Blood Leech drains nearby players to heal this durable troll, making split damage and loose positioning inefficient.",
    { "Blood Leech", "Cleave" },
    "Keep it on the tank, spread non-tanks away from its cleave and drain, and focus it after the primary caster.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("sandfuryExecutioner", 7274, "Sandfury Executioner", "circle", 80,
    "pyramid gatekeeper; isolate before the event",
    "The Executioner stands among nearby packs, and an uncontrolled pull can begin the prisoner sequence without safe recovery space.",
    {},
    "Clear the pyramid base, pull the Executioner alone, recover fully, then use his key only when the whole group is ready.",
    "Humanoid", "Boss control is unreliable; use safe pulling, stuns, and focused damage.", {}, true)
mob("nekrum", 7796, "Nekrum Gutchewer", "circle", 90,
    "final pyramid melee boss; focus before Sezz'ziz",
    "Nekrum arrives with Sezz'ziz in the final wave and is the faster first kill while the priest's casts are interrupted.",
    { "Fevered Plague" },
    "Focus Nekrum, cleanse Fevered Plague, and keep Sezz'ziz interrupted until the melee boss is dead.",
    "Humanoid", "Boss control is unreliable; use slows, stuns, and disease removal.", {}, true)
mob("sezzziz", 7275, "Shadowpriest Sezz'ziz", "circle", 100,
    "pyramid healer and fear caster; interrupt",
    "Heal and Renew undo progress while Psychic Scream can scatter the party into remaining event enemies.",
    { "Heal", "Renew", "Psychic Scream", "Shadow Bolt" },
    "Tank away from uncleared ground, interrupt healing first, purge Renew when available, and regroup quickly after fear.",
    "Humanoid", "Boss control is unreliable; interrupts, fear breaks, and dispels are dependable.", {}, true)
mob("oroEyegouge", 7606, "Oro Eyegouge", "cross", 110,
    "Bly ally area damage; kill after healer",
    "If Bly betrays the party, Oro adds heavy area pressure while Murta heals and Bly disrupts the tank.",
    { "Demoralizing Shout" },
    "Kill Murta first, then focus Oro while the tank controls Bly and the remaining mercenaries.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("sandfuryGuardian", 7268, "Sandfury Guardian", "cross", 120,
    "poisonous serpent; keep off non-tanks",
    "Poison adds sustained damage and Thrash can spike its target on the final approach when several guardians join a pull.",
    { "Poison", "Thrash" },
    "Pull guardians away from the chief's terrace, cleanse poison, and keep every serpent on the tank.",
    "Beast", "Hibernate, Polymorph, Fear, roots, stuns, and other beast control work.")

-- Routine enemies and summons
mob("scarab", 7269, "Scarab", "none", 130,
    "Theka scarabs; gather for controlled area damage",
    "The scarab room contains dense neutral groups that can overwhelm the healer when careless area damage wakes too many at once.",
    {},
    "Pull only the scarabs needed for safe space, gather them on the tank, and avoid uncontrolled area damage during Theka.",
    "Beast", "Roots, slows, and stuns can hold stragglers; measured area damage is normally faster.")
mob("zulFarrakZombie", 7286, "Zul'Farrak Zombie", "none", 140,
    "Zum'rah summon; gather and clear",
    "Zum'rah calls nearby dead into the fight, creating loose enemies that quickly transfer pressure to the healer.",
    {},
    "Let the tank gather each zombie, use controlled area damage, and return to the ward and boss once the healer is safe.",
    "Undead", "Shackle Undead, Turn Undead, roots, and stuns work; ordinary humanoid control does not.")
mob("sandfuryCretin", 7789, "Sandfury Cretin", "none", 150,
    "pyramid wave; hold the stairs with the NPCs",
    "Large waves climb both sides of the pyramid, but spreading down the stairs makes them harder to gather and heal through.",
    {},
    "Fight near the upper landing, let the mercenaries meet each wave, and keep loose trolls off the healer and Weegli.",
    "Humanoid", "Polymorph, Fear, roots, stuns, and other humanoid control work if a wave needs to be slowed.")
mob("servantOfAntusul", 8156, "Servant of Antu'sul", "none", 160,
    "Antu'sul add; control or clear after wards",
    "Antu'sul summons elite servants alongside broodlings, increasing tank and healer pressure while his healing remains active.",
    {},
    "Destroy Healing Wards first, control or gather the servants, and use measured area damage before returning to Antu'sul.",
    "Beast", "Hibernate, Polymorph, Fear, roots, and stuns work; keep adds away from the healer.")

-- Bosses and rares
mob("antusul", 8127, "Antu'sul", "circle", 200,
    "add-heavy healer boss; destroy wards",
    "Antu'sul heals, drops Earthgrab and Healing Wards, and summons broodlings and elite servants throughout the fight.",
    { "Healing Wave", "Healing Ward", "Earthgrab Totem", "Summon Minions" },
    "Clear the cave mouth, let the tank approach first, destroy wards, interrupt healing, and control each add wave.",
    "Humanoid", "Boss control is unreliable; control the beast adds and destroy totems instead.", {}, true)
mob("theka", 7272, "Theka the Martyr", "circle", 210,
    "disease boss; avoid waking the full scarab room",
    "Fevered Plague needs cleansing, and Theka's low-health transformation brings nearby scarabs into the encounter.",
    { "Fevered Plague", "Theka Transform" },
    "Clear working space, cleanse the disease, avoid stray area damage, and finish Theka before cleaning up scarabs.",
    "Humanoid", "Boss control is unreliable; control scarabs and use disease removal.", {}, true)
mob("zumrah", 7271, "Witch Doctor Zum'rah", "circle", 220,
    "ward, heal, and volley boss; control summons",
    "Healing Wave and Shadow Bolt Volley demand interrupts while wards and zombies steadily add pressure.",
    { "Healing Wave", "Shadow Bolt", "Shadow Bolt Volley", "Ward of Zum'rah" },
    "Clear the graveyard edge, interrupt Volley and healing, destroy wards, and gather every summoned zombie.",
    "Humanoid", "Boss control is unreliable; Shackle or Turn summoned undead and interrupt the boss.", {}, true)
mob("sergeantBly", 7604, "Sergeant Bly", "circle", 230,
    "optional betrayal boss; handle his healer first",
    "Talking to Bly after the pyramid event can turn his surviving mercenary party hostile for the Divino-matic Rod quest.",
    { "Revenge", "Shield Bash" },
    "Have Weegli open the gate first, recover, then trigger Bly only if needed; kill Murta, Oro, and Bly in that order.",
    "Humanoid", "Boss control is unreliable; control his companions and protect casters from Shield Bash.",
    { "Skip the betrayal when nobody needs the Divino-matic Rod quest objective." }, true)
mob("velratha", 7795, "Hydromancer Velratha", "circle", 240,
    "pool patrol; isolate and interrupt healing",
    "Velratha patrols among dense pool packs, so engaging her in place can add multiple casters and guardians.",
    { "Healing Wave" },
    "Clear a retreat lane, pull her alone with line of sight, interrupt Healing Wave, and loot both quest items before moving on.",
    "Humanoid", "Boss control is unreliable; use line of sight, interrupts, and focused damage.", {}, true)
mob("gahzrilla", 7273, "Gahz'rilla", "circle", 250,
    "optional Mallet summon; brace against the knock-up",
    "Freeze Solid removes a player briefly, while Gahz'rilla Slam launches nearby players high enough to cause dangerous falls.",
    { "Freeze Solid", "Gahz'rilla Slam", "Icicle" },
    "Clear the pool, use the Mallet at the gong, and fight under the arch or in water so Slam cannot cause lethal fall damage.",
    "Beast", "Boss control is unreliable; use positioning, magic dispels, and mitigation.",
    { "The encounter is unavailable unless someone carries the Mallet of Zul'Farrak." }, true)
mob("ruuzlu", 7797, "Ruuzlu", "circle", 260,
    "chief's companion; kill before Ukorz",
    "Ruuzlu begins beside Ukorz and adds cleave and execute pressure throughout the final encounter if left alive.",
    { "Cleave", "Execute" },
    "Have the tank face both enemies away, focus Ruuzlu first, and keep low-health players away from his execute range.",
    "Humanoid", "Boss control is unreliable; use focused damage and defensive cooldowns.", {}, true)
mob("ukorz", 7267, "Chief Ukorz Sandscalp", "circle", 270,
    "final boss; face away and manage Enrage",
    "Cleave punishes players in front, and Berserker Stance increases Ukorz's damage as the final fight progresses.",
    { "Cleave", "Berserker Stance" },
    "Kill Ruuzlu first, keep Ukorz faced away from the party, and save mitigation and healing cooldowns for Enrage.",
    "Humanoid", "Boss control is unreliable; use positioning, mitigation, and focused damage.", {}, true)
mob("sandarr", 10080, "Sandarr Dunereaver", "circle", 280,
    "optional rare; isolate before engaging",
    "Sandarr can appear along the early route near ordinary patrols, turning a routine pull into an unexpected elite fight.",
    { "Thrash" },
    "Pull the rare into cleared ground, keep it on the tank, and finish it before advancing to the next patrol.",
    "Humanoid", "Boss control is unreliable; use slows, stuns, and focused damage.", {}, true)
mob("dustwraith", 10081, "Dustwraith", "circle", 290,
    "optional graveyard rare; clear nearby graves",
    "Dustwraith can appear near Zum'rah's graveyard, where disturbed graves or nearby patrols can add undead to the fight.",
    { "Shadow Bolt Volley" },
    "Clear the graveyard edge, isolate the rare, interrupt its volley, and avoid opening shallow graves during combat.",
    "Undead", "Boss control is unreliable; use Shackle, Turn Undead, interrupts, and focused damage.", {}, true)
mob("zerillis", 10082, "Zerillis", "circle", 300,
    "wandering rare; line-of-sight the ranged attack",
    "Zerillis patrols the central city and can join another pull while attacking from range with slows and nets.",
    { "Frost Shot", "Net", "Shoot" },
    "Wait for a safe patrol position, pull behind cover, and keep Zerillis in melee range until the fight ends.",
    "Humanoid", "Boss control is unreliable; use line of sight, dispels, and focused damage.", {}, true)

Catalog.RegisterGuide({
    key = "zulFarrak", name = "Zul'Farrak", instanceIds = { 209 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "entranceAntusul", name = "Entrance & Antu'sul",
            route = {
                "Enter through the southern gate, clear the first patrols into safe ground, and use walls to stack Shadowcasters, Witch Doctors, and Shadowhunters on the tank.",
                "At the central fork, take the eastern passage and check the early patrol route for rare Sandarr Dunereaver without chasing him into another group.",
                "Clear the cracked-wall approach and every basilisk outside Antu'sul's cave; the tank approaches first because the boss engages at long range.",
                "Defeat Antu'sul, backtrack to the central fork, and continue north toward Theka rather than cutting across uncleared city patrols.",
            },
            entries = {
                "sandfuryShadowhunter", "sandfuryWitchDoctor", "sandfurySoulEater",
                "sandfuryShadowcaster", "sandfuryBloodDrinker", "servantOfAntusul",
                "antusul", "sandarr",
            },
            rules = {
                { title = "Caster corners", guidance = "Use the entrance walls and ruined buildings to pull ranged trolls onto the tank. Never chase a caster toward an uncleared plaza patrol." },
                { title = "Antu'sul pull", guidance = "Clear outside the cave, let the tank cross the proximity trigger alone, destroy every Healing Ward, and control servants while broodlings are gathered." },
            },
        },
        {
            key = "thekaZumrah", name = "Theka & Zum'rah",
            route = {
                "Enter Theka's scarab court from the east, clear only enough neutral scarabs for working space, and keep area damage away from untouched clusters.",
                "Defeat Theka, then follow the northern loop toward Zum'rah while isolating plaza patrols and checking for wandering rare Zerillis.",
                "Clear the graveyard edge without opening shallow graves, check the western tombs for rare Dustwraith, and establish a safe camp before Zum'rah.",
                "Kill Zum'rah with ward and zombie switches, then continue west toward the pyramid and clear its entire base before touching the Executioner.",
            },
            entries = {
                "sandfuryShadowhunter", "sandfuryWitchDoctor", "sandfurySoulEater",
                "sandfuryShadowcaster", "wardOfZumrah", "sandfuryBloodDrinker",
                "scarab", "zulFarrakZombie", "theka", "zumrah", "dustwraith", "zerillis",
            },
            rules = {
                { title = "Scarab restraint", guidance = "Clear a compact fighting pocket before Theka and stop uncontrolled area damage from waking the full room when he transforms." },
                { title = "Shallow graves", guidance = "Opening graves can release additional enemies. Leave them untouched during Zum'rah, then open them only after the room is stable." },
                { title = "Zum'rah priorities", guidance = "Interrupt Shadow Bolt Volley and Healing Wave, destroy every Ward of Zum'rah, and gather summoned zombies before resuming boss damage." },
            },
        },
        {
            key = "pyramidEvent", name = "Pyramid Event",
            route = {
                "Clear every patrol at the pyramid base and both stair approaches, pull the Sandfury Executioner alone, then recover fully before using his cage key.",
                "Open all cages only when the party is ready, remain near the upper landing, and let Bly's mercenaries help gather the waves climbing both staircases.",
                "Protect the healer and Weegli Blastfuse through every wave; Nekrum and Sezz'ziz arrive together at the end, so focus Nekrum while interrupting the priest.",
                "After the event, speak with Weegli before any optional Bly confrontation so he survives to blast open the gate leading to Chief Ukorz.",
                "Trigger Sergeant Bly's betrayal only for the Divino-matic Rod objective, after the gate is open and the party has recovered.",
            },
            entries = {
                "murtaGrimgut", "sandfuryExecutioner", "nekrum", "sezzziz",
                "oroEyegouge", "sandfuryCretin", "sergeantBly",
            },
            rules = {
                { title = "Event commitment", guidance = "Do not open the cages until the base is empty and everyone has restored health and mana; the event runs through successive waves without a reset break." },
                { title = "Hold the landing", guidance = "Stay near the top so friendly mercenaries meet both stair waves together. Do not run downhill and split tank threat or healer line of sight." },
                { title = "Keep Weegli alive", guidance = "Keep enemies off Weegli and talk to him as soon as the final wave is secure; his demolition opens the only normal route to the chief." },
                { title = "Optional betrayal", guidance = "Open the chief's gate first. If the quest fight is needed, interrupt Murta, kill her before Oro, and control Bly until his companions are dead." },
            },
        },
        {
            key = "sacredPoolChief", name = "Sacred Pool & Chief",
            route = {
                "Return through the western city loop toward the sacred pool, pulling each caster pack behind cover and separating Sandfury Guardian patrols.",
                "Clear the complete pool edge, isolate Hydromancer Velratha from her patrol, and loot her before approaching the gong platform.",
                "If someone has the Mallet of Zul'Farrak, use it at the gong and fight Gahz'rilla under the arch or in water to control Slam fall damage.",
                "Backtrack to Weegli's opened gate, clear all guardians from the final terrace, and fight Ruuzlu and Chief Ukorz with both faced away from the party.",
                "Focus Ruuzlu first, then finish Ukorz while saving tank and healer cooldowns for Berserker Stance and late cleave pressure.",
            },
            entries = {
                "sandfuryShadowhunter", "sandfuryWitchDoctor", "sandfurySoulEater",
                "sandfuryShadowcaster", "sandfuryBloodDrinker", "sandfuryGuardian",
                "velratha", "gahzrilla", "ruuzlu", "ukorz",
            },
            rules = {
                { title = "Mallet check", guidance = "Gahz'rilla is optional and requires the Mallet of Zul'Farrak. Confirm a carrier before the run; the gong cannot substitute for the item." },
                { title = "Pool preparation", guidance = "Clear the full fighting area before using the gong. Tank under the arch or in water so Gahz'rilla Slam cannot turn its knock-up into lethal fall damage." },
                { title = "Final terrace", guidance = "Clear the guardian serpents before the bosses, face both trolls away, kill Ruuzlu first, and reserve mitigation for Ukorz's Berserker Stance." },
            },
        },
    },
})
