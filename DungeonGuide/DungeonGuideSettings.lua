ApogeePartyHealthBars_DungeonGuideSettings = {}
local S = ApogeePartyHealthBars_DungeonGuideSettings
local D
local DEFAULT_POINT, DEFAULT_X, DEFAULT_Y = "CENTER", 0, 0

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
