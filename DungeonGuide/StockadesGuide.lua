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

-- Main hall and recurring cell packs
mob("defiasPrisoner", 1706, "Defias Prisoner", "skull", 10,
    "Disarm disrupts tank threat; kill first",
    "Disarm can stall weapon-based threat while nearby prisoners run toward uncleared cells.",
    { "Disarm" },
    "Focus quickly, slow the runner, and give the tank time to rebuild threat after Disarm.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("defiasInsurgent", 1715, "Defias Insurgent", "skull", 20,
    "pack support; remove its Battle Shout",
    "Battle Shout strengthens every nearby melee enemy and makes a linked cell pull harder to stabilize.",
    { "Battle Shout", "Demoralizing Shout" },
    "Interrupt or purge support effects when practical, focus it early, and stop its escape.",
    "Humanoid", "Normal humanoid control works; silence and stuns can limit its support effects.")
mob("defiasConvict", 1711, "Defias Convict", "cross", 30,
    "knockdown and wound pressure; kill second",
    "Backhand can knock down and stun a party member while Rend and Infected Wound increase sustained pressure.",
    { "Backhand", "Infected Wound", "Rend" },
    "Kill after Skull, cleanse or mitigate the wound effects, and keep it from reaching another room.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.")
mob("defiasCaptive", 1707, "Defias Captive", "none", 40,
    "control one backstabber in a large pull",
    "Controlling one backstabber reduces pressure while the group establishes threat on the rest of a linked cell pack.",
    { "Backstab", "Infected Wound" },
    "Keep it controlled away from incidental damage, then face it toward the tank during cleanup.",
    "Humanoid", "Polymorph, Sap, Fear, roots, stuns, and other humanoid control work.",
    { "Skip control when the pull is small enough to tank safely." })
mob("defiasInmate", 1708, "Defias Inmate", "none", 50,
    "routine melee cleanup; stop the runner",
    "It is a lower-priority melee body, but its Rend and low-health escape can still extend a pull.",
    { "Rend" },
    "Tank normally, clean it up after marked enemies, and slow or stun it before it flees.",
    "Humanoid", "Normal humanoid control works when an oversized pull needs another target removed.")

-- Variable-cell bosses
mob("targorr", 1696, "Targorr the Dread", "circle", 100,
    "boss; control adds before his Enrage",
    "Circle identifies Targorr while his linked Defias and fast melee attacks create the real opening danger.",
    { "Dual Wield", "Enrage", "Thrash" },
    "Control one add, kill the active Defias first, then keep Targorr on the tank through Enrage.",
    "Humanoid", "Use control on nearby Defias and mitigation on Targorr.",
    { "Check every main-hall cell because his spawn room can vary." }, true)
mob("kamDeepfury", 1666, "Kam Deepfury", "circle", 110,
    "boss; stabilize through tank stuns and blocks",
    "Circle identifies Kam while Shield Slam can stun the tank and his defenses prolong pressure from any remaining adds.",
    { "Defensive Stance", "Improved Blocking", "Shield Slam" },
    "Control or kill nearby Defias, keep healing ready for a tank stun, and maintain steady damage through his defenses.",
    "Humanoid", "Use control on nearby Defias and keep defensive support ready for Shield Slam.",
    { "He can occupy different cells; keep checking rooms if he was not in the main hall." }, true)
mob("bruegal", 1720, "Bruegal Ironknuckle", "circle", 120,
    "rare boss; clear his cell before engaging",
    "Circle identifies this rare spawn, whose surrounding cell pack is more dangerous than his simple melee attacks.",
    { "Dazed" },
    "Clear or control nearby Defias, keep him on the tank, and finish the straightforward fight.",
    "Humanoid", "Boss control is unreliable; use ordinary mitigation.",
    { "He is very rare and can appear in cells on either wing; never assume a missing room spawn is a route error." }, true)

-- Western wing
mob("dextrenWard", 1663, "Dextren Ward", "circle", 100,
    "boss; clear for fear before the pull",
    "Intimidating Shout can send the party into uncleared cells and turn a controlled boss pull into a large chain pull.",
    { "Battle Stance", "Intimidating Shout", "Slam" },
    "Clear the adjoining rooms, fight in safe space, then focus Dextren while controlling any remaining Defias.",
    "Humanoid", "Boss control is unreliable; Fear protection and quick recovery matter more than ordinary CC.", {}, true)

-- Eastern wing
mob("hamhock", 1717, "Hamhock", "circle", 100,
    "boss; control adds and spread for lightning",
    "Chain Lightning punishes a stacked party while Bloodlust increases his melee pressure.",
    { "Chain Lightning", "Bloodlust" },
    "Control one add, establish threat on the other, spread when space allows, and burn Hamhock quickly.",
    "Humanoid", "Boss control is unreliable; use humanoid CC on his Defias adds instead.", {}, true)
mob("bazilThredd", 1716, "Bazil Thredd", "circle", 110,
    "final boss; protect the tank through Smoke Bomb",
    "Smoke Bomb can stun the tank while Bazil's dual-wield attacks continue, creating a sharp healing spike.",
    { "Smoke Bomb", "Battle Shout", "Dual Wield" },
    "Pull or control his Defias first, top the tank before the stun, and interrupt or mitigate support effects.",
    "Humanoid", "Boss control is unreliable; use interrupts and mitigation while the tank is stunned.", {}, true)

local function overviewMap()
    return {
        texture = "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\DungeonGuide\\Stockades.png",
        width = 2048, height = 2048,
        caption = "Gold route — dashed alternate — orange optional; numbers show boss order",
        description = "Complete Stockade overview with the central cell block, variable boss cells, west-first Dextren route, central backtrack, and eastern Hamhock and Bazil wing.",
    }
end

Catalog.RegisterGuide({
    key = "stockades", name = "The Stockade", instanceIds = { 34 },
    clientFlavors = { classicEra = true, tbcAnniversary = true }, mobs = mobs,
    sections = {
        {
            key = "mainHall", name = "Main Hall & Cell Sweep", map = overviewMap(),
            route = {
                "Enter through the Stockade portal in Stormwind's Mage Quarter; Horde groups face a dangerous city approach before the instance.",
                "Descend the ramp, wait for the hall patrol, and pull the first pack back toward the entrance instead of fighting beside cell doors.",
                "Clear every main-hall cell in small pulls and inspect each room for Targorr, Kam Deepfury, or rare Bruegal Ironknuckle.",
                "At the far junction, turn left for the western wing first; do not leave runners or uncleared doorway packs behind the group.",
            },
            entries = {
                "defiasPrisoner", "defiasInsurgent", "defiasConvict", "defiasCaptive",
                "defiasInmate", "targorr", "kamDeepfury", "bruegal",
            },
            rules = {
                { title = "Fleeing prisoners", guidance = "Fight toward cleared ground and slow, root, or stun every low-health Defias. A runner reaching a cell can link several additional enemies." },
                { title = "Cell doorways", guidance = "Wait for patrols and pull from range. Enemies standing near both opposing doors can link before the tank has stable threat." },
                { title = "Variable bosses", guidance = "Targorr, Kam, and Bruegal can occupy different cells. Check rooms during the full clear instead of treating one memorized spawn as guaranteed." },
            },
        },
        {
            key = "westernWing", name = "Western Wing", map = overviewMap(),
            route = {
                "Turn left at the main junction and pull the entrance inmates back into the cleared main hall.",
                "Clear both sides of the western corridor methodically, using the last cleared room as recovery space between linked cell pulls.",
                "Empty Dextren Ward's adjoining rooms before engaging him so Intimidating Shout cannot send players into fresh enemies.",
                "After Dextren falls, return to the main junction and turn into the eastern wing to complete the dungeon.",
            },
            entries = { "dextrenWard" },
            rules = {
                { title = "Fear safety", guidance = "Do not use uncontrolled Fear near occupied cells. Clear Dextren's approach and fight him away from unopened rooms before the first Intimidating Shout." },
                { title = "Western backtrack", guidance = "The route intentionally returns to the central junction after Dextren; there is no through-path from the western terminus to Bazil." },
            },
        },
        {
            key = "easternWing", name = "Eastern Wing", map = overviewMap(),
            route = {
                "From the central junction, take the eastern corridor and intercept its wandering Insurgent before descending into the cell packs.",
                "Continue checking rooms for Kam or Bruegal if neither appeared earlier, and keep every low-health runner inside cleared space.",
                "Clear around Hamhock, control his two Defias, and spread enough to reduce Chain Lightning jumps without approaching occupied cells.",
                "Clear Bazil Thredd's side cells, pull his remaining Defias separately when possible, then finish the dungeon in his central cell.",
            },
            entries = { "hamhock", "bazilThredd" },
            rules = {
                { title = "Hamhock's adds", guidance = "Control one Defias and establish threat on the other. Avoid stacking the party tightly while Hamhock is casting Chain Lightning." },
                { title = "Bazil's stun", guidance = "Top the tank before Smoke Bomb and keep backup healing ready. Do not begin the boss while an avoidable Defias add is still loose." },
            },
        },
    },
})
