ApogeePartyHealthBars_DungeonBoardEligibility = {}
local Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility
local Catalog = ApogeePartyHealthBars_DungeonBoardCatalog

local VALID_ROLES = { tank = true, healer = true }
local DEFAULT_LEVELS_BELOW = 10
local DEFAULT_LEVELS_ABOVE = 3
local MAX_LEVEL_OFFSET = 60

local function normalizeOffset(value, fallback)
    value = tonumber(value)
    if not value or value ~= value then value = fallback end
    value = math.max(0, math.min(MAX_LEVEL_OFFSET, value))
    return math.floor(value + 0.5)
end

function Eligibility.GetDefaultLevelOffsets()
    return DEFAULT_LEVELS_BELOW, DEFAULT_LEVELS_ABOVE
end

function Eligibility.GetLevelOffsetLimits()
    return 0, MAX_LEVEL_OFFSET
end

function Eligibility.NormalizeLevelOffsets(levelsBelow, levelsAbove)
    return normalizeOffset(levelsBelow, DEFAULT_LEVELS_BELOW),
        normalizeOffset(levelsAbove, DEFAULT_LEVELS_ABOVE)
end

function Eligibility.GetLevelWindow(playerLevel, levelsBelow, levelsAbove)
    playerLevel = tonumber(playerLevel)
    if not playerLevel or playerLevel <= 0 or playerLevel ~= playerLevel then return nil end
    playerLevel = math.floor(playerLevel)
    levelsBelow, levelsAbove = Eligibility.NormalizeLevelOffsets(levelsBelow, levelsAbove)
    return {
        minLevel = math.max(1, playerLevel - levelsBelow),
        maxLevel = playerLevel + levelsAbove,
        playerLevel = playerLevel,
        levelsBelow = levelsBelow,
        levelsAbove = levelsAbove,
    }
end

function Eligibility.NormalizeRole(value)
    if VALID_ROLES[value] then return value end
    return "healer"
end

function Eligibility.NeedsRole(entry, role)
    for _, neededRole in ipairs(entry and entry.neededRoles or {}) do
        if neededRole == role then return true end
    end
    return false
end

function Eligibility.MatchesRole(entry, role)
    role = Eligibility.NormalizeRole(role)
    local needsTank = Eligibility.NeedsRole(entry, "tank")
    local needsHealer = Eligibility.NeedsRole(entry, "healer")
    if role == "tank" then return needsTank and not needsHealer end
    return needsHealer and not needsTank
end

function Eligibility.GetEligibleDungeonKeys(entry, playerLevel, levelWindow)
    local result = {}
    if type(entry) ~= "table" then return result end
    levelWindow = levelWindow or Eligibility.GetLevelWindow(playerLevel)
    if not levelWindow then return result end
    for _, key in ipairs(entry.dungeonKeys or {}) do
        local eligible = Catalog.IsLevelAppropriate(
            key, playerLevel, entry.heroic, levelWindow)
        if eligible then result[#result + 1] = key end
    end
    return result
end

function Eligibility.IsBoardVisible(entry, role, playerLevel, levelWindow)
    if type(entry) ~= "table" then return false end
    local eligibleKeys = Eligibility.GetEligibleDungeonKeys(entry, playerLevel, levelWindow)
    if #eligibleKeys == 0 then return false end
    return Eligibility.MatchesRole(entry, role)
end

function Eligibility.IsFeedOpportunity(entry, role, playerLevel, levelWindow)
    if type(entry) ~= "table" or entry.source == "blizzard" then
        return false
    end
    if not Eligibility.MatchesRole(entry, role) then return false end
    for _, key in ipairs(Eligibility.GetEligibleDungeonKeys(
        entry, playerLevel, levelWindow))
    do
        if Catalog.IsFivePlayer(key) then return true end
    end
    return false
end
