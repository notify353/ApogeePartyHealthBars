local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_UnitTopology = {}
local T = ApogeePartyHealthBars_UnitTopology

local rows = {}
local ownerByToken = {}
local roleByToken = {}
local trackedTokens = {}

local function BuildTargetToken(owner, depth)
    if depth == 0 then return owner end
    if owner == "player" then
        return depth == 1 and "target" or "targettarget"
    end
    return owner .. string.rep("target", depth)
end

for index, owner in ipairs(C.SLOT_UNITS) do
    local descriptor = {
        index = index,
        owner = owner,
        tokens = {
            BuildTargetToken(owner, 0),
            BuildTargetToken(owner, 1),
            BuildTargetToken(owner, 2),
        },
    }
    rows[index] = descriptor
    for depth = 0, 2 do
        local token = descriptor.tokens[depth + 1]
        ownerByToken[token] = owner
        roleByToken[token] = depth == 0 and "primary"
            or (depth == 1 and "target" or "targetOfTarget")
        trackedTokens[#trackedTokens + 1] = token
    end
end

function T.GetRows()
    return rows
end

function T.GetRow(index)
    return rows[index]
end

function T.GetToken(owner, depth)
    if type(depth) ~= "number" or depth < 0 or depth > 2 then return nil end
    return BuildTargetToken(owner, depth)
end

function T.GetOwner(unitToken)
    return ownerByToken[unitToken]
end

function T.GetRole(unitToken)
    return roleByToken[unitToken]
end

function T.IsTracked(unitToken)
    return ownerByToken[unitToken] ~= nil
end

function T.GetTrackedTokens()
    return trackedTokens
end

function T.ForEachToken(callback)
    for _, token in ipairs(trackedTokens) do callback(token) end
end
