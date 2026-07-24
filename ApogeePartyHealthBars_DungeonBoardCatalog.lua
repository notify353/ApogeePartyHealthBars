ApogeePartyHealthBars_DungeonBoardCatalog = {}
local Catalog = ApogeePartyHealthBars_DungeonBoardCatalog

local definitions = {
    { key = "RFC", name = "Ragefire Chasm", expansion = "classicEra", minLevel = 15, maxLevel = 20,
        aliases = { "rfc", "ragefire", "chasm" } },
    { key = "WC", name = "Wailing Caverns", expansion = "classicEra", minLevel = 17, maxLevel = 25,
        aliases = { "wc", "wailing", "caverns" } },
    { key = "DM", name = "The Deadmines", expansion = "classicEra", minLevel = 17, maxLevel = 26,
        aliases = { "deadmines", "vc", "vancleef", "dead mines", "mine" } },
    { key = "SFK", name = "Shadowfang Keep", expansion = "classicEra", minLevel = 18, maxLevel = 26,
        aliases = { "sfk", "shadowfang" } },
    { key = "BFD", name = "Blackfathom Deeps", expansion = "classicEra", minLevel = 20, maxLevel = 30,
        aliases = { "bfd", "blackfathom", "fathom" } },
    { key = "STK", name = "The Stockade", expansion = "classicEra", minLevel = 22, maxLevel = 30,
        aliases = { "stk", "stock", "stockade", "stockades" } },
    { key = "GNO", name = "Gnomeregan", expansion = "classicEra", minLevel = 24, maxLevel = 34,
        aliases = {
            "gnomer", "gno", "gnomeregan", "gnomeragan", "gnome", "gnomregan",
            "gnomragan", "gnom", "gnomergan",
        } },
    { key = "RFK", name = "Razorfen Kraul", expansion = "classicEra", minLevel = 30, maxLevel = 40,
        aliases = { "rfk", "kraul" } },
    { key = "SMG", name = "Scarlet Monastery - Graveyard", expansion = "classicEra",
        minLevel = 26, maxLevel = 36, aliases = { "smgy", "smg", "gy", "graveyard" } },
    { key = "SML", name = "Scarlet Monastery - Library", expansion = "classicEra",
        minLevel = 29, maxLevel = 39, aliases = { "smlib", "sml", "lib", "library" } },
    { key = "SMA", name = "Scarlet Monastery - Armory", expansion = "classicEra",
        minLevel = 34, maxLevel = 42,
        aliases = { "smarm", "sma", "arm", "armory", "herod", "armoury", "arms" } },
    { key = "SMC", name = "Scarlet Monastery - Cathedral", expansion = "classicEra",
        minLevel = 37, maxLevel = 45, aliases = { "smcath", "smc", "cath", "cathedral" } },
    { key = "RFD", name = "Razorfen Downs", expansion = "classicEra", minLevel = 40, maxLevel = 50,
        aliases = { "rfd", "downs" } },
    { key = "ULD", name = "Uldaman", expansion = "classicEra", minLevel = 37, maxLevel = 45,
        aliases = { "uld", "ulda", "uldaman", "ulduman", "uldman", "uldama", "udaman" } },
    { key = "ZF", name = "Zul'Farrak", expansion = "classicEra", minLevel = 44, maxLevel = 54,
        aliases = {
            "zf", "zul farrak", "zulfarrak", "zulfarak", "zulfa", "zulf",
        } },
    { key = "MAR", name = "Maraudon", expansion = "classicEra", minLevel = 32, maxLevel = 44,
        aliases = {
            "mar", "mara", "maraudon", "mauradon", "mauro", "maurodon", "princessrun",
            "maraudin", "maura", "marau", "mauraudon",
        } },
    { key = "ST", name = "The Temple of Atal'Hakkar", expansion = "classicEra",
        minLevel = 50, maxLevel = 60, aliases = { "st", "sunken", "atal", "temple" } },
    { key = "BRD", name = "Blackrock Depths", expansion = "classicEra", minLevel = 49, maxLevel = 61,
        aliases = { "brd", "emperor", "emp", "arenarun", "angerforge", "blackrockdepth" } },
    { key = "DME", name = "Dire Maul - East", expansion = "classicEra", minLevel = 54, maxLevel = 60,
        aliases = { "dme", "dmeast", "east", "puzilin", "jumprun" } },
    { key = "DMW", name = "Dire Maul - West", expansion = "classicEra", minLevel = 57, maxLevel = 60,
        aliases = { "dmw", "dmwest", "west" } },
    { key = "DMN", name = "Dire Maul - North", expansion = "classicEra", minLevel = 58, maxLevel = 60,
        aliases = { "dmn", "dmnorth", "north", "tribute", "dmt" } },
    { key = "STR", name = "Stratholme", expansion = "classicEra", minLevel = 58, maxLevel = 60,
        aliases = {
            "stratlive", "live", "living", "stratud", "undead", "ud", "baron", "stratholme",
            "stath", "stratholm", "strah", "strath", "strat", "starth",
        } },
    { key = "SCH", name = "Scholomance", expansion = "classicEra", minLevel = 58, maxLevel = 60,
        aliases = { "scholomance", "scholo", "sholo", "sholomance" } },
    { key = "LBRS", name = "Lower Blackrock Spire", expansion = "classicEra",
        minLevel = 57, maxLevel = 60, aliases = { "lower", "lbrs", "lrbs" } },
    { key = "UBRS", name = "Upper Blackrock Spire", expansion = "classicEra",
        minLevel = 58, maxLevel = 60, aliases = { "upper", "ubrs", "urbs", "rend" } },

    { key = "RAMPS", name = "Hellfire Ramparts", expansion = "tbcAnniversary",
        minLevel = 59, maxLevel = 67, aliases = { "ramparts", "rampart", "ramp", "ramps" } },
    { key = "BF", name = "The Blood Furnace", expansion = "tbcAnniversary",
        minLevel = 61, maxLevel = 68, aliases = { "furnace", "furn", "bf" } },
    { key = "SP", name = "The Slave Pens", expansion = "tbcAnniversary",
        minLevel = 62, maxLevel = 69, aliases = { "slavepens", "pens", "sp" } },
    { key = "UB", name = "The Underbog", expansion = "tbcAnniversary",
        minLevel = 63, maxLevel = 70, aliases = { "underbog", "ub" } },
    { key = "MT", name = "Mana-Tombs", expansion = "tbcAnniversary",
        minLevel = 64, maxLevel = 71, aliases = { "manatombs", "mana", "mt", "tomb", "tombs" } },
    { key = "CRYPTS", name = "Auchenai Crypts", expansion = "tbcAnniversary",
        minLevel = 65, maxLevel = 72,
        aliases = { "crypts", "crypt", "auchenai", "ac", "acrypts", "acrypt" } },
    { key = "OHB", name = "Old Hillsbrad Foothills", expansion = "tbcAnniversary",
        minLevel = 66, maxLevel = 73,
        aliases = { "ohb", "oh", "ohf", "durnholde", "hillsbrad", "escape" } },
    { key = "SETH", name = "Sethekk Halls", expansion = "tbcAnniversary",
        minLevel = 67, maxLevel = 73, aliases = { "sethekk", "seth", "sethek" } },
    { key = "SL", name = "Shadow Labyrinth", expansion = "tbcAnniversary",
        minLevel = 69, maxLevel = 75, aliases = { "sl", "slab", "labyrinth", "lab" } },
    { key = "SH", name = "The Shattered Halls", expansion = "tbcAnniversary",
        minLevel = 69, maxLevel = 75, aliases = { "sh", "shattered", "shatered", "shaterred" } },
    { key = "BM", name = "The Black Morass", expansion = "tbcAnniversary",
        minLevel = 69, maxLevel = 75, aliases = { "morass", "bm", "black" } },
    { key = "SV", name = "The Steamvault", expansion = "tbcAnniversary",
        minLevel = 69, maxLevel = 75,
        aliases = { "sv", "steamvault", "steamvaults", "steam vault", "valts" } },
    { key = "MECH", name = "The Mechanar", expansion = "tbcAnniversary",
        minLevel = 70, maxLevel = 75, aliases = { "mech", "mechanar" } },
    { key = "BOT", name = "The Botanica", expansion = "tbcAnniversary",
        minLevel = 70, maxLevel = 75, aliases = { "botanica", "bot" } },
    { key = "ARC", name = "The Arcatraz", expansion = "tbcAnniversary",
        minLevel = 70, maxLevel = 75, aliases = { "arc", "arcatraz", "alcatraz" } },
    { key = "MGT", name = "Magisters' Terrace", expansion = "tbcAnniversary",
        minLevel = 68, maxLevel = 75,
        aliases = { "mgt", "mrt", "terrace", "magisters", "magister" } },
}

local byKey = {}
for _, definition in ipairs(definitions) do
    byKey[definition.key] = definition
end

local function cloneDefinition(definition)
    if not definition then return nil end
    local copy = {}
    for key, value in pairs(definition) do
        if key == "aliases" then
            copy.aliases = {}
            for index, alias in ipairs(value) do
                copy.aliases[index] = alias
            end
        else
            copy[key] = value
        end
    end
    return copy
end

local function supportsClient(definition, clientFlavor)
    if clientFlavor == "classicEra" then
        return definition.expansion == "classicEra"
    end
    if clientFlavor == "tbcAnniversary" then
        return definition.expansion == "classicEra" or definition.expansion == "tbcAnniversary"
    end
    return false
end

function Catalog.GetDungeon(key)
    return cloneDefinition(byKey[key])
end

function Catalog.GetDungeons(clientFlavor)
    local result = {}
    for _, definition in ipairs(definitions) do
        if supportsClient(definition, clientFlavor) then
            result[#result + 1] = cloneDefinition(definition)
        end
    end
    return result
end
