local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_UnitAPI = {}
local U = ApogeePartyHealthBars_UnitAPI

function U.Exists(unitId)
    if unitId == nil or UnitExists == nil then return false end
    local exists = UnitExists(unitId)
    return exists == true or exists == 1
end

function U.IsConnected(unitId)
    if not U.Exists(unitId) then return false end
    if not UnitIsConnected then return true end
    local connected = UnitIsConnected(unitId)
    return connected == true or connected == 1
end

function U.IsDead(unitId)
    if not U.Exists(unitId) or not UnitIsDeadOrGhost then return false end
    local dead = UnitIsDeadOrGhost(unitId)
    return dead == true or dead == 1
end

function U.GetHealth(unitId)
    if not U.Exists(unitId) then return 0, 1 end
    local value = UnitHealth and UnitHealth(unitId) or 0
    local maximum = UnitHealthMax and UnitHealthMax(unitId) or 1
    if type(value) ~= "number" then value = 0 end
    local validMaximum = type(maximum) == "number" and maximum > 0
    if not validMaximum then maximum = 1 end
    return value, maximum, validMaximum
end

function U.GetIdentity(unitId)
    local identity = { name = unitId, isPlayer = false }
    if not U.Exists(unitId) then return identity end
    if UnitGUID then identity.guid = UnitGUID(unitId) end
    if UnitName then identity.name = UnitName(unitId) or unitId end
    if UnitIsPlayer then
        local isPlayer = UnitIsPlayer(unitId)
        identity.isPlayer = isPlayer == true or isPlayer == 1
    end
    if identity.isPlayer and UnitClass then
        local _, classToken = UnitClass(unitId)
        identity.classToken = classToken
    end
    if UnitReaction then identity.reaction = UnitReaction("player", unitId) end
    if UnitFactionGroup then identity.faction = UnitFactionGroup(unitId) end
    identity.oppositeFactionPlayer = U.IsOppositeFactionPlayer(unitId)
    return identity
end

function U.GetGUID(unitId)
    if not U.Exists(unitId) or not UnitGUID then return nil end
    return UnitGUID(unitId)
end

function U.GetPowerChannels(unitId)
    local channels = {}
    if not U.Exists(unitId) then return channels end

    local powerType, powerToken
    if UnitPowerType then powerType, powerToken = UnitPowerType(unitId) end
    if powerType == nil then powerType, powerToken = C.MANA_POWER, "MANA" end

    local function add(channelType, channelToken)
        local maximum = UnitPowerMax and UnitPowerMax(unitId, channelType) or 0
        if type(maximum) ~= "number" or maximum <= 0 then return end
        local value = UnitPower and UnitPower(unitId, channelType) or 0
        if type(value) ~= "number" then value = 0 end
        channels[#channels + 1] = {
            powerType = channelType,
            powerToken = channelToken,
            value = value,
            maximum = maximum,
        }
    end

    if powerType ~= C.MANA_POWER then add(C.MANA_POWER, "MANA") end
    add(powerType, powerToken)
    return channels
end

function U.GetDefaultRange(unitId)
    if not U.Exists(unitId) or not UnitInRange then return true end
    local inRange, checkedRange = UnitInRange(unitId)
    if not checkedRange then return true end
    return inRange == true or inRange == 1
end

function U.CanHeal(unitId)
    if not U.Exists(unitId) or U.IsDead(unitId) or not U.IsConnected(unitId) then return false end
    if UnitCanAssist and not UnitCanAssist("player", unitId) then return false end
    if UnitIsEnemy and UnitIsEnemy("player", unitId) then return false end
    return true
end

function U.IsOppositeFactionPlayer(unitId)
    if not U.Exists(unitId) or not UnitIsPlayer or not UnitIsPlayer(unitId) then return false end
    if not UnitFactionGroup then return false end
    local playerFaction = UnitFactionGroup("player")
    local unitFaction = UnitFactionGroup(unitId)
    return playerFaction ~= nil and unitFaction ~= nil and playerFaction ~= unitFaction
end
