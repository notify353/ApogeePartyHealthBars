ApogeePartyHealthBars_DungeonGuidePolicy = {}
local P = ApogeePartyHealthBars_DungeonGuidePolicy
local D

function P.Initialize(deps)
    assert(type(deps) == "table" and type(deps.Catalog) == "table", "DungeonGuidePolicy requires catalog")
    D = deps
end
function P.ParseNpcId(guid)
    if type(guid) ~= "string" then return nil end
    local kind, npcId = guid:match("^([^-]+)%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-([^-]+)%-")
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return tonumber(npcId)
end

local function context()
    local flavor = D and D.GetClientFlavor and D.GetClientFlavor()
    local instanceId = D and D.GetInstanceId and D.GetInstanceId()
    return flavor, tonumber(instanceId)
end

function P.GetCurrentGuide()
    if not D then return nil end
    local flavor, instanceId = context()
    return D.Catalog.GetGuideForInstance(flavor, instanceId)
end

function P.GetRecommendationForGuid(guid)
    if not D then return nil end
    local npcId = P.ParseNpcId(guid)
    if not npcId then return nil end
    local flavor, instanceId = context()
    local mob, mobKey, guide = D.Catalog.FindMob(flavor, instanceId, npcId)
    if not mob then return nil end
    local marker = D.Catalog.GetMarker(mob.marker)
    return {
        guideKey = guide.key, mobKey = mobKey, npcId = npcId, mobName = mob.name,
        markerKey = marker.key, markerLabel = marker.label, markerIndex = marker.index,
        priority = mob.priority, liveReason = mob.liveReason, boss = mob.boss == true,
    }
end
