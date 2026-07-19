-- Immutable combat macro recipes for TBC Anniversary.
ApogeePartyHealthBars_MacroData = {}
local D = ApogeePartyHealthBars_MacroData

D.Categories = {
    { id = "all", label = "All Examples" },
    { id = "attack", label = "Safe Attacks" },
    { id = "interrupt", label = "Stopcasting" },
    { id = "pet", label = "Pet Combat" },
    { id = "control", label = "Control & Targeting" },
    { id = "state", label = "Forms & Stealth" },
}

D.DocumentationCategories = {
    { id = "all", label = "All Topics" },
    { id = "generated", label = "Generated Templates" },
    { id = "syntax", label = "Syntax Glossary" },
    { id = "recipes", label = "Combat Recipes" },
}

D.SyntaxTopics = {
    { id = "syntax-targetenemy", title = "Conditional Enemy Targeting", body = "/targetenemy [noexists][dead][help]", explanation = "Finds a hostile target only when the current target is missing, dead, or friendly.", applied = "Generated auto-attack and curated melee families plus explicit combat recipes, not ordinary spells.", why = "It preserves a valid living enemy instead of changing targets on every press.", tradeoffs = "It is unsafe as a universal default because friendly, utility, stealth, and crowd-control spells may not want an enemy target.", copyable = false },
    { id = "syntax-startattack", title = "Start Melee Auto-Attack", body = "/startattack", explanation = "Starts melee auto-attack without toggling it off on another press.", applied = "The Attack template, curated weapon abilities, and the ranged auto-attack melee fallback.", why = "Confirmed attack actions engage reliably even when another cast cannot fire.", tradeoffs = "Do not add it universally: it can break crowd control, cancel stealth plans, or start unwanted combat.", copyable = false },
    { id = "syntax-nochanneling", title = "Optional Channel Guard", body = "/cast [nochanneling:Mind Flay] Mind Flay(Rank 7)", explanation = "Casts unless that same named spell is already channeling.", applied = "Optional custom macros for actual channeled spells such as Mind Flay; it is not added to ordinary generated spells.", why = "It can make one channel key spammable without preventing other abilities from interrupting that channel.", tradeoffs = "It prevents another copy from queuing during the channel, so latency can leave a small gap afterward.", copyable = false },
    { id = "syntax-bang", title = "Prevent Toggle-Off with !", body = "/cast !Auto Shot", explanation = "The ! prefix turns on a toggle-style spell but does not turn it off on another press.", applied = "Generated Auto Shot, wand Shoot, and client-confirmed ranged auto-attacks; selected custom toggle recipes also use it.", why = "Repeated key presses cannot cancel a supported repeating or toggle action.", tradeoffs = "Do not add ! indiscriminately when intentional cancellation matters.", copyable = false },
    { id = "syntax-ranked", title = "Rank-Qualified Spell Names", body = "/cast Fireball(Rank 1)", explanation = "Keeps the Spellbook subtext so the macro casts the exact assigned rank.", applied = "Generated spell macros when the client supplies rank text.", why = "Classic characters may intentionally assign different ranks of the same spell.", tradeoffs = "Reset continues using the rank currently stored on the assignment.", copyable = false },
    { id = "syntax-conditions", title = "Macro Conditions", body = "/cast [@mouseover,help,nodead] Flash Heal", explanation = "Bracketed conditions choose whether and where a secure macro command may act.", applied = "Generated auto-attack templates use target-state conditions; users can add modifiers or unit targeting to custom macros.", why = "Conditions provide predictable choices without addon code making protected combat decisions.", tradeoffs = "Conditions cannot inspect arbitrary cooldown, resource, or rotation state.", copyable = false },
    { id = "syntax-reset", title = "Reset to Generated Default", body = "Reset", explanation = "Reset rebuilds the selected action's macro from its current spell or item.", applied = "The focused macro editor for Shortcuts, Keys, Wheel, and Buttons.", why = "It restores the latest smart template without clearing the assigned action or sound.", tradeoffs = "Reset replaces the current custom macro text after the user saves it.", copyable = false },
    { id = "syntax-custom", title = "Custom Macro Preservation", body = "Custom text is preserved", explanation = "Normalization, profiles, imports, movement, and layout changes retain nonblank macro text exactly.", applied = "Every stored Shortcut, Key, Wheel, and Button action.", why = "Generated defaults are a starting point rather than an ownership claim over user edits.", tradeoffs = "Existing assignments are not automatically upgraded; use Reset to adopt a newer template.", copyable = false },
    { id = "syntax-limit", title = "255-Byte Macro Limit", body = "Maximum: 255 bytes", explanation = "WoW macro bodies are limited to 255 bytes, measured as encoded text bytes rather than visible characters.", applied = "Macro-editor validation and every executable library recipe.", why = "Rejecting oversized text prevents a saved action from being truncated or failing unexpectedly.", tradeoffs = "Localized characters may consume more than one byte.", copyable = false },
    { id = "syntax-stopattack", title = "Stop Auto-Attack for Control", body = "/stopattack", explanation = "Stops melee, Auto Shot, or wand Shoot before a control or urgent utility spell.", applied = "Custom crowd-control and wand-cancel macros such as Polymorph or Sap.", why = "An automatic weapon swing can immediately break control or delay the spell you meant to cast.", tradeoffs = "It deliberately costs attack uptime, so use it only where stopping is part of the intent.", copyable = false },
    { id = "syntax-mouseover-help", title = "Friendly Mouseover Priority", body = "/cast [@mouseover,help,nodead][help,nodead][@player] Flash Heal", explanation = "Uses a living friendly mouseover first, then a friendly target, then the player.", applied = "Optional custom healing, buff, cleanse, and utility macros outside native Healing clicks.", why = "The current hostile target can stay selected while the spell goes to the intended ally.", tradeoffs = "Mouse position becomes meaningful; omit the fallback branches when an accidental target would be worse than a failed cast.", copyable = false },
    { id = "syntax-focus", title = "Focus with Normal Fallback", body = "/cast [@focus,harm,nodead][] Counterspell", explanation = "Uses a living hostile focus when available and otherwise preserves the spell's normal targeting.", applied = "Optional interrupts, crowd control, dispels, and utility spells in TBC Anniversary.", why = "A priority enemy can be controlled without losing the current target.", tradeoffs = "The focus must be maintained deliberately, and some spells need friendly rather than hostile conditions.", copyable = false },
    { id = "syntax-cursor", title = "Ground Spell at Cursor", body = "/cast [@cursor] Blizzard", explanation = "Places a ground-targeted spell immediately at the world cursor instead of opening the targeting circle.", applied = "Optional custom macros for ground-targeted spells.", why = "It removes the second placement click for faster execution.", tradeoffs = "A misplaced cursor means a misplaced spell; use normal casting when precise confirmation matters.", copyable = false },
    { id = "syntax-help-harm", title = "Help/Harm Dual Purpose", body = "/cast [help] Flash Heal; [harm] Smite", explanation = "Selects a friendly or hostile spell from the current target's relationship.", applied = "Optional bindings that intentionally combine two related actions.", why = "It saves a key while keeping the decision visible and based on target state.", tradeoffs = "A wrong or missing target can choose the wrong branch or do nothing; never use it to guess cooldowns or resources.", copyable = false },
    { id = "syntax-modifier", title = "Modifier and Rank Choice", body = "/cast [mod:shift] Healing Touch(Rank 4); Healing Touch(Rank 7)", explanation = "Lets the player explicitly choose another spell, rank, or target while holding a modifier.", applied = "Optional custom bindings and deliberate Classic downranking.", why = "The player makes the decision that secure macros are not allowed to infer from health, mana, or cooldown state.", tradeoffs = "A modifier already used by the physical binding still counts as held, so design Keys, Wheel, and Buttons macros carefully.", copyable = false },
    { id = "syntax-stealth", title = "Spam-Safe Stealth State", body = "/cast [nostealth] !Prowl", explanation = "Attempts the toggle only while not already stealthed.", applied = "Optional Stealth and Prowl macros.", why = "Repeated presses cannot immediately cancel the state the first press entered.", tradeoffs = "It removes same-button cancellation; leave stealth through an attack or a separate cancel action.", copyable = false },
    { id = "syntax-next-swing", title = "Queued Next-Swing Toggle", body = "/cast !Heroic Strike", explanation = "Keeps a supported next-swing ability queued instead of allowing a second press to cancel it.", applied = "Optional Classic abilities such as Heroic Strike, Cleave, Maul, and Raptor Strike after class-specific testing.", why = "It protects an intentional queued attack from key spam.", tradeoffs = "Queued attacks spend resources and replace a normal swing; preventing cancellation can cause rage or mana starvation.", copyable = false },
}

local TARGET = "/targetenemy [noexists][dead][help]"
local function stopcast(spell)
    return "/stopcasting\n/cast [@focus,harm,nodead][] " .. spell
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
        body = TARGET .. "\n/cast !Shoot\n/startattack",
    },
    {
        id = "hunter-safe-auto-shot", category = "attack", classes = { HUNTER = true },
        title = "Spam-Safe Auto Shot",
        explanation = "Targets an enemy and starts Auto Shot without toggling it off when the button is spammed.",
        requirements = "Requires a ranged weapon and Auto Shot.", requiredSpells = { "Auto Shot" },
        body = TARGET .. "\n/cast !Auto Shot\n/startattack",
    },
    {
        id = "hunter-force-auto-shot", category = "attack", classes = { HUNTER = true },
        title = "Shot with Forced Auto Shot",
        explanation = "Starts Auto Shot without toggling it off, then attempts Arcane Shot on the same target.",
        requirements = "Requires a ranged weapon, Auto Shot, and Arcane Shot.",
        verificationNote = "Optional expert pattern; verify shot timing and weaving behavior in game.",
        requiredSpells = { "Auto Shot", "Arcane Shot" },
        body = "/cast !Auto Shot\n/cast Arcane Shot",
    },
    {
        id = "hunter-pet-auto-shot", category = "pet", classes = { HUNTER = true },
        title = "Pet Attack & Safe Auto Shot",
        explanation = "Sends your pet to a valid enemy and starts Auto Shot without toggling it off.",
        requirements = "Requires an active pet, a ranged weapon, and Auto Shot.", requiredSpells = { "Auto Shot" },
        body = TARGET .. "\n/petattack [@target,harm,nodead]\n/cast !Auto Shot\n/startattack",
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
    { id = "mage-safe-polymorph", category = "control", classes = { MAGE = true }, title = "Mouseover Polymorph without Auto-Attack", explanation = "Stops weapon attacks, controls a living hostile mouseover when present, and otherwise uses the current target.", requirements = "Requires Polymorph and a crowd-control target.", requiredSpells = { "Polymorph" }, body = "/stopattack\n/cast [@mouseover,harm,nodead][] Polymorph" },
    { id = "rogue-safe-sap", category = "control", classes = { ROGUE = true }, title = "Mouseover Sap without Auto-Attack", explanation = "Stops weapon attacks, Saps a living hostile mouseover when present, and otherwise uses the current target.", requirements = "Requires Stealth, Sap, and a valid out-of-combat target.", requiredSpells = { "Sap" }, body = "/stopattack\n/cast [@mouseover,harm,nodead][] Sap" },
    { id = "druid-spam-safe-prowl", category = "state", classes = { DRUID = true }, title = "Spam-Safe Prowl", explanation = "Enters Prowl only while not already stealthed, so repeated presses cannot immediately cancel it.", requirements = "Requires Cat Form and Prowl.", verificationNote = "Use a separate action when you intentionally want to leave Prowl.", requiredSpells = { "Prowl" }, body = "/cast [nostealth] !Prowl" },
    { id = "rogue-spam-safe-stealth", category = "state", classes = { ROGUE = true }, title = "Spam-Safe Stealth", explanation = "Enters Stealth only while not already stealthed, so repeated presses cannot immediately cancel it.", requirements = "Requires Stealth and being out of combat.", verificationNote = "Use a separate action when you intentionally want to leave Stealth.", requiredSpells = { "Stealth" }, body = "/cast [nostealth] !Stealth" },
    { id = "warrior-queued-heroic-strike", category = "attack", classes = { WARRIOR = true }, title = "Keep Heroic Strike Queued", explanation = "Queues Heroic Strike without letting repeated presses toggle the pending next-swing attack off.", requirements = "Requires Heroic Strike and enough rage when the next melee swing lands.", verificationNote = "Preventing cancellation can waste rage; verify the queue indicator and resource behavior in game.", requiredSpells = { "Heroic Strike" }, body = "/startattack\n/cast !Heroic Strike" },
    { id = "druid-queued-maul", category = "attack", classes = { DRUID = true }, title = "Keep Maul Queued", explanation = "Queues Maul without letting repeated presses toggle the pending next-swing attack off.", requirements = "Requires Bear Form, Maul, and enough rage when the next melee swing lands.", verificationNote = "Preventing cancellation can starve other Bear abilities; verify the queue indicator and resource behavior in game.", requiredSpells = { "Maul" }, body = "/startattack\n/cast !Maul" },
    { id = "hunter-queued-raptor-strike", category = "attack", classes = { HUNTER = true }, title = "Keep Raptor Strike Queued", explanation = "Queues Raptor Strike without letting repeated presses toggle the pending next-swing attack off.", requirements = "Requires a melee weapon, Raptor Strike, and enough mana when the next melee swing lands.", verificationNote = "This applies to the queued TBC version; verify the queue indicator and melee-weaving behavior in game.", requiredSpells = { "Raptor Strike" }, body = "/startattack\n/cast !Raptor Strike" },
}
