ApogeePartyHealthBars_DungeonBoardActivityData = {}
local ActivityData = ApogeePartyHealthBars_DungeonBoardActivityData

-- Activity IDs are client data, not stable dungeon identities. Keep them
-- private to the Group Finder boundary and map them onto catalog keys.
local definitions = {
    { id = 796, key = "WC", expansion = "classicEra" },
    { id = 797, key = "SCH", expansion = "classicEra" },
    { id = 798, key = "RFC", expansion = "classicEra" },
    { id = 799, key = "DM", expansion = "classicEra" },
    { id = 800, key = "SFK", expansion = "classicEra" },
    { id = 801, key = "BFD", expansion = "classicEra" },
    { id = 802, key = "STK", expansion = "classicEra" },
    { id = 803, key = "GNO", expansion = "classicEra" },
    { id = 804, key = "RFK", expansion = "classicEra" },
    { id = 805, key = "SMG", expansion = "classicEra" },
    { id = 806, key = "RFD", expansion = "classicEra" },
    { id = 807, key = "ULD", expansion = "classicEra" },
    { id = 808, key = "ZF", expansion = "classicEra" },
    { id = 809, key = "MAR", expansion = "classicEra" },
    { id = 810, key = "ST", expansion = "classicEra" },
    { id = 811, key = "BRD", expansion = "classicEra" },
    { id = 812, key = "LBRS", expansion = "classicEra" },
    { id = 813, key = "DME", expansion = "classicEra" },
    { id = 814, key = "DMW", expansion = "classicEra" },
    { id = 815, key = "DMN", expansion = "classicEra" },
    { id = 816, key = "STR", expansion = "classicEra" },
    { id = 827, key = "SMA", expansion = "classicEra" },
    { id = 828, key = "SMC", expansion = "classicEra" },
    { id = 829, key = "SML", expansion = "classicEra" },
    { id = 1603, key = "STR", expansion = "classicEra" },

    { id = 817, key = "RAMPS", expansion = "tbcAnniversary" },
    { id = 913, key = "RAMPS", expansion = "tbcAnniversary", heroic = true },
    { id = 818, key = "BF", expansion = "tbcAnniversary" },
    { id = 912, key = "BF", expansion = "tbcAnniversary", heroic = true },
    { id = 819, key = "SH", expansion = "tbcAnniversary" },
    { id = 914, key = "SH", expansion = "tbcAnniversary", heroic = true },
    { id = 820, key = "SP", expansion = "tbcAnniversary" },
    { id = 909, key = "SP", expansion = "tbcAnniversary", heroic = true },
    { id = 821, key = "UB", expansion = "tbcAnniversary" },
    { id = 911, key = "UB", expansion = "tbcAnniversary", heroic = true },
    { id = 822, key = "SV", expansion = "tbcAnniversary" },
    { id = 910, key = "SV", expansion = "tbcAnniversary", heroic = true },
    { id = 823, key = "MT", expansion = "tbcAnniversary" },
    { id = 904, key = "MT", expansion = "tbcAnniversary", heroic = true },
    { id = 824, key = "CRYPTS", expansion = "tbcAnniversary" },
    { id = 903, key = "CRYPTS", expansion = "tbcAnniversary", heroic = true },
    { id = 825, key = "SETH", expansion = "tbcAnniversary" },
    { id = 905, key = "SETH", expansion = "tbcAnniversary", heroic = true },
    { id = 826, key = "SL", expansion = "tbcAnniversary" },
    { id = 906, key = "SL", expansion = "tbcAnniversary", heroic = true },
    { id = 830, key = "OHB", expansion = "tbcAnniversary" },
    { id = 908, key = "OHB", expansion = "tbcAnniversary", heroic = true },
    { id = 831, key = "BM", expansion = "tbcAnniversary" },
    { id = 907, key = "BM", expansion = "tbcAnniversary", heroic = true },
    { id = 832, key = "MECH", expansion = "tbcAnniversary" },
    { id = 916, key = "MECH", expansion = "tbcAnniversary", heroic = true },
    { id = 833, key = "BOT", expansion = "tbcAnniversary" },
    { id = 918, key = "BOT", expansion = "tbcAnniversary", heroic = true },
    { id = 834, key = "ARC", expansion = "tbcAnniversary" },
    { id = 915, key = "ARC", expansion = "tbcAnniversary", heroic = true },
    { id = 835, key = "MGT", expansion = "tbcAnniversary" },
    { id = 917, key = "MGT", expansion = "tbcAnniversary", heroic = true },
}

local byID = {}
for _, definition in ipairs(definitions) do
    byID[definition.id] = definition
end

local function supportsClient(definition, clientFlavor)
    if clientFlavor == "classicEra" then
        return definition.expansion == "classicEra"
    end
    if clientFlavor == "tbcAnniversary" then
        return definition.expansion == "classicEra"
            or definition.expansion == "tbcAnniversary"
    end
    return false
end

local function clone(definition)
    if not definition then return nil end
    return {
        id = definition.id,
        key = definition.key,
        expansion = definition.expansion,
        heroic = definition.heroic == true,
    }
end

function ActivityData.GetActivity(activityID, clientFlavor)
    local definition = byID[activityID]
    if not definition or not supportsClient(definition, clientFlavor) then return nil end
    return clone(definition)
end

function ActivityData.GetActivities(clientFlavor)
    local result = {}
    for _, definition in ipairs(definitions) do
        if supportsClient(definition, clientFlavor) then
            result[#result + 1] = clone(definition)
        end
    end
    return result
end
