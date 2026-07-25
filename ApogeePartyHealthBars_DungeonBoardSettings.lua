ApogeePartyHealthBars_DungeonBoardSettings = {}
local Settings = ApogeePartyHealthBars_DungeonBoardSettings
local Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility

local D
local listeners = {}
local FEED_POINT, FEED_X, FEED_Y = "CENTER", 0, 0
local BOARD_POINT, BOARD_X, BOARD_Y = "TOP", 0, -20

local function saved()
    return D and D.GetSavedVariables and D.GetSavedVariables() or nil
end

local function notify(kind)
    for _, listener in ipairs(listeners) do listener(kind) end
end

function Settings.Initialize(deps)
    assert(type(deps) == "table" and type(deps.GetSavedVariables) == "function",
        "DungeonBoardSettings requires saved variables")
    assert(type(deps.Sounds) == "table", "DungeonBoardSettings requires sounds")
    D = deps
end

function Settings.GetRole()
    local values = saved()
    return Eligibility.NormalizeRole(values and values.dungeonBoardRole)
end

function Settings.SetRole(role)
    local values = saved()
    if not values then return false end
    role = Eligibility.NormalizeRole(role)
    if values.dungeonBoardRole == role then return false end
    values.dungeonBoardRole = role
    notify("role")
    return true
end

function Settings.GetFeedEnabled()
    local values = saved()
    return values == nil or values.dungeonBoardFeedEnabled ~= false
end

function Settings.SetFeedEnabled(enabled)
    local values = saved()
    if not values then return false end
    enabled = enabled == true
    if Settings.GetFeedEnabled() == enabled then return false end
    values.dungeonBoardFeedEnabled = enabled
    notify("feedEnabled")
    return true
end

function Settings.GetSoundKey()
    local values = saved()
    return D.Sounds.NormalizeKey(values and values.dungeonBoardSoundKey, "none", true)
end

function Settings.SetSoundKey(soundKey)
    local values = saved()
    if not values then return false end
    soundKey = D.Sounds.NormalizeKey(soundKey, "none", true)
    if values.dungeonBoardSoundKey == soundKey then return false end
    values.dungeonBoardSoundKey = soundKey
    notify("sound")
    return true
end

function Settings.PreviewSound()
    return D.Sounds.Play(Settings.GetSoundKey())
end

function Settings.GetLevelOffsets()
    local values = saved()
    return Eligibility.NormalizeLevelOffsets(
        values and values.dungeonBoardLevelsBelow,
        values and values.dungeonBoardLevelsAbove)
end

function Settings.GetLevelOffsetLimits()
    return Eligibility.GetLevelOffsetLimits()
end

function Settings.GetLevelWindow(playerLevel)
    local levelsBelow, levelsAbove = Settings.GetLevelOffsets()
    return Eligibility.GetLevelWindow(playerLevel, levelsBelow, levelsAbove)
end

function Settings.SetLevelOffsets(levelsBelow, levelsAbove)
    local values = saved()
    if not values then return false end
    levelsBelow, levelsAbove = Eligibility.NormalizeLevelOffsets(levelsBelow, levelsAbove)
    if values.dungeonBoardLevelsBelow == levelsBelow
        and values.dungeonBoardLevelsAbove == levelsAbove
    then
        return false
    end
    values.dungeonBoardLevelsBelow = levelsBelow
    values.dungeonBoardLevelsAbove = levelsAbove
    notify("levelRange")
    return true
end

function Settings.AdjustLevelOffset(kind, direction)
    local levelsBelow, levelsAbove = Settings.GetLevelOffsets()
    direction = tonumber(direction) or 0
    if kind == "below" then
        levelsBelow = levelsBelow + direction
    elseif kind == "above" then
        levelsAbove = levelsAbove + direction
    else
        return false
    end
    return Settings.SetLevelOffsets(levelsBelow, levelsAbove)
end

function Settings.GetFeedPosition()
    local values = saved() or {}
    return values.dungeonBoardFeedPoint or FEED_POINT,
        values.dungeonBoardFeedRelPoint or FEED_POINT,
        tonumber(values.dungeonBoardFeedX) or FEED_X,
        tonumber(values.dungeonBoardFeedY) or FEED_Y
end

function Settings.ResetFeedPosition()
    Settings.SetFeedPosition(FEED_POINT, FEED_POINT, FEED_X, FEED_Y)
end

function Settings.GetBoardPosition()
    local values = saved() or {}
    return values.dungeonBoardPoint or BOARD_POINT,
        values.dungeonBoardRelPoint or BOARD_POINT,
        tonumber(values.dungeonBoardX) or BOARD_X,
        tonumber(values.dungeonBoardY) or BOARD_Y
end

function Settings.SetBoardPosition(point, relativePoint, x, y)
    local values = saved()
    if not values then return end
    values.dungeonBoardPoint = point or BOARD_POINT
    values.dungeonBoardRelPoint = relativePoint or point or BOARD_POINT
    values.dungeonBoardX = tonumber(x) or BOARD_X
    values.dungeonBoardY = tonumber(y) or BOARD_Y
end

function Settings.ResetBoardPosition()
    Settings.SetBoardPosition(BOARD_POINT, BOARD_POINT, BOARD_X, BOARD_Y)
end

function Settings.SetFeedPosition(point, relativePoint, x, y)
    local values = saved()
    if not values then return end
    values.dungeonBoardFeedPoint = point or "CENTER"
    values.dungeonBoardFeedRelPoint = relativePoint or point or "CENTER"
    values.dungeonBoardFeedX = tonumber(x) or 0
    values.dungeonBoardFeedY = tonumber(y) or 0
end

function Settings.Subscribe(listener)
    assert(type(listener) == "function", "DungeonBoardSettings listener must be a function")
    listeners[#listeners + 1] = listener
end
