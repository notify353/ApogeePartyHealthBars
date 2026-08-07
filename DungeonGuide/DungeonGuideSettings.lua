ApogeePartyHealthBars_DungeonGuideSettings = {}
local S = ApogeePartyHealthBars_DungeonGuideSettings
local D
local DEFAULT_POINT, DEFAULT_X, DEFAULT_Y = "CENTER", 0, 0
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1000, 720
local MIN_WIDTH, MIN_HEIGHT = 720, 520

function S.Initialize(deps)
    assert(type(deps) == "table" and type(deps.GetSavedVariables) == "function",
        "DungeonGuideSettings requires saved variables")
    D = deps
end
local function saved() return D and D.GetSavedVariables() or nil end
function S.GetAutoMarkEnabled()
    local v = saved()
    return v and v.dungeonGuideAutoMarkEnabled == true or false
end
function S.SetAutoMarkEnabled(enabled)
    local v = saved(); if not v then return false end
    enabled = enabled == true
    if v.dungeonGuideAutoMarkEnabled == enabled then return false end
    v.dungeonGuideAutoMarkEnabled = enabled
    return true
end
function S.GetBookPosition()
    local v = saved() or {}
    return v.dungeonGuidePoint or DEFAULT_POINT, v.dungeonGuideRelPoint or DEFAULT_POINT,
        tonumber(v.dungeonGuideX) or DEFAULT_X, tonumber(v.dungeonGuideY) or DEFAULT_Y
end
function S.SetBookPosition(point, relativePoint, x, y)
    local v = saved(); if not v then return end
    v.dungeonGuidePoint = point or DEFAULT_POINT
    v.dungeonGuideRelPoint = relativePoint or point or DEFAULT_POINT
    v.dungeonGuideX, v.dungeonGuideY = tonumber(x) or DEFAULT_X, tonumber(y) or DEFAULT_Y
end
function S.ResetBookPosition() S.SetBookPosition(DEFAULT_POINT, DEFAULT_POINT, DEFAULT_X, DEFAULT_Y) end

local function normalizeDimension(value, fallback, minimum, maximum)
    value = tonumber(value)
    if not value or value ~= value then value = fallback end
    return math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
end

function S.GetBookSize()
    local v = saved() or {}
    return normalizeDimension(v.dungeonGuideWidth, DEFAULT_WIDTH, MIN_WIDTH, 3840),
        normalizeDimension(v.dungeonGuideHeight, DEFAULT_HEIGHT, MIN_HEIGHT, 2160)
end

function S.SetBookSize(width, height)
    local v = saved(); if not v then return false end
    width = normalizeDimension(width, DEFAULT_WIDTH, MIN_WIDTH, 3840)
    height = normalizeDimension(height, DEFAULT_HEIGHT, MIN_HEIGHT, 2160)
    if v.dungeonGuideWidth == width and v.dungeonGuideHeight == height then
        return false
    end
    v.dungeonGuideWidth, v.dungeonGuideHeight = width, height
    return true
end

function S.ResetBookWindow()
    S.ResetBookPosition()
    return S.SetBookSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
end

function S.GetDefaultBookSize() return DEFAULT_WIDTH, DEFAULT_HEIGHT end
