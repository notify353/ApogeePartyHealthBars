-- Immutable combat macro recipes for TBC Anniversary.
ApogeePartyHealthBars_MacroData = {}
local D = ApogeePartyHealthBars_MacroData

D.Categories = {
    { id = "all", label = "All Examples" },
    { id = "attack", label = "Safe Attacks" },
    { id = "interrupt", label = "Stopcasting" },
    { id = "pet", label = "Pet Combat" },
}

local TARGET = "/targetenemy [noexists][dead][help]"
local function stopcast(spell)
    return "/stopcasting\n/cast [@target,harm,nodead] " .. spell
end

D.Recipes = {
    {
        id = "universal-safe-attack", category = "attack",
        title = "Safe Target & Attack", explanation = "Keeps a living hostile target, finds one only when needed, and starts melee auto-attack.",
        body = TARGET .. "\n/startattack",
    },
    {
        id = "wand-safe-shoot", category = "attack", classes = { MAGE = true, PRIEST = true, WARLOCK = true },
        title = "Spam-Safe Wand Shoot",
        explanation = "Targets an enemy and starts Shoot without toggling your wand attack off when the button is spammed.",
        requirements = "Requires an equipped wand and the Shoot ability.", requiredSpells = { "Shoot" },
        body = TARGET .. "\n/cast !Shoot",
    },
    {
        id = "hunter-safe-auto-shot", category = "attack", classes = { HUNTER = true },
        title = "Spam-Safe Auto Shot",
        explanation = "Targets an enemy and starts Auto Shot without toggling it off when the button is spammed.",
        requirements = "Requires a ranged weapon and Auto Shot.", requiredSpells = { "Auto Shot" },
        body = TARGET .. "\n/cast !Auto Shot",
    },
    {
        id = "hunter-pet-auto-shot", category = "pet", classes = { HUNTER = true },
        title = "Pet Attack & Safe Auto Shot",
        explanation = "Sends your pet to a valid enemy and starts Auto Shot without toggling it off.",
        requirements = "Requires an active pet, a ranged weapon, and Auto Shot.", requiredSpells = { "Auto Shot" },
        body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast !Auto Shot",
    },
    {
        id = "warlock-pet-attack", category = "pet", classes = { WARLOCK = true },
        title = "Safe Pet Attack",
        explanation = "Keeps a living hostile target, finds one only when needed, and sends your demon to attack it.",
        requirements = "Requires an active demon.",
        body = TARGET .. "\n/petattack [@target,harm,nodead]",
    },
    { id = "druid-stop-feral-charge", category = "interrupt", classes = { DRUID = true }, title = "Stopcast Feral Charge", explanation = "Stops your current cast before attempting Feral Charge on a living hostile target.", requirements = "Requires the Feral Charge talent, Bear Form, and a target in range.", verificationNote = "Verify form and range behavior in game.", requiredSpells = { "Feral Charge" }, body = stopcast("Feral Charge") },
    { id = "hunter-stop-scatter", category = "interrupt", classes = { HUNTER = true }, title = "Stopcast Scatter Shot", explanation = "Stops your current cast before attempting Scatter Shot on a living hostile target.", requirements = "Requires the Scatter Shot talent and a target in range.", requiredSpells = { "Scatter Shot" }, body = stopcast("Scatter Shot") },
    { id = "mage-stop-counter", category = "interrupt", classes = { MAGE = true }, title = "Stopcast Counterspell", explanation = "Stops your current cast before immediately attempting Counterspell on a living hostile target.", requirements = "Requires Counterspell and a target in range.", requiredSpells = { "Counterspell" }, body = stopcast("Counterspell") },
    { id = "paladin-stop-hammer", category = "interrupt", classes = { PALADIN = true }, title = "Stopcast Hammer of Justice", explanation = "Stops your current cast before attempting Hammer of Justice on a living hostile target.", requirements = "Requires Hammer of Justice and a target in range.", requiredSpells = { "Hammer of Justice" }, body = stopcast("Hammer of Justice") },
    { id = "priest-stop-silence", category = "interrupt", classes = { PRIEST = true }, title = "Stopcast Silence", explanation = "Stops your current cast before attempting Silence on a living hostile target.", requirements = "Requires the Silence talent and a target in range.", requiredSpells = { "Silence" }, body = stopcast("Silence") },
    { id = "rogue-stop-kick", category = "interrupt", classes = { ROGUE = true }, title = "Stopcast Kick", explanation = "Cancels any current cast or channel before attempting Kick on a living hostile target.", requirements = "Requires Kick, melee range, and a suitable weapon.", requiredSpells = { "Kick" }, body = stopcast("Kick") },
    { id = "shaman-stop-shock", category = "interrupt", classes = { SHAMAN = true }, title = "Stopcast Earth Shock", explanation = "Stops your current cast before immediately attempting Earth Shock on a living hostile target.", requirements = "Requires Earth Shock and a target in range.", requiredSpells = { "Earth Shock" }, body = stopcast("Earth Shock") },
    { id = "warlock-stop-spell-lock", category = "interrupt", classes = { WARLOCK = true }, title = "Stopcast Spell Lock", explanation = "Stops your current cast before ordering your Felhunter to use Spell Lock on a living hostile target.", requirements = "Requires an active Felhunter with Spell Lock.", verificationNote = "Verify pet autocast and target behavior in game.", requiredPetSpells = { "Spell Lock" }, body = stopcast("Spell Lock") },
    { id = "warrior-stop-pummel", category = "interrupt", classes = { WARRIOR = true }, title = "Stopcast Pummel", explanation = "Cancels any current cast or channel before attempting Pummel on a living hostile target.", requirements = "Requires Pummel, Berserker Stance, and melee range.", verificationNote = "Does not change stances automatically.", requiredSpells = { "Pummel" }, body = stopcast("Pummel") },
}
