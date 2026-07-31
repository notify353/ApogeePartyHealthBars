ApogeePartyHealthBars_PlayerContext = {}
local P = ApogeePartyHealthBars_PlayerContext

local function activeTalentGroup()
    local value
    if C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup then
        value = C_SpecializationInfo.GetActiveSpecGroup(false, false)
    elseif GetActiveTalentGroup then
        value = GetActiveTalentGroup()
    end
    value = tonumber(value)
    return value and value >= 1 and math.floor(value) or 1
end

local function talentSnapshot(group)
    local result = { group = group, tabs = {}, ranksByTalentId = {}, primaryTab = nil }
    local bestPoints = -1
    local tabCount = tonumber(GetNumTalentTabs and GetNumTalentTabs()) or 3
    for tab = 1, math.max(0, tabCount) do
        local name, points
        if GetTalentTabInfo then
            local icon
            name, icon, points = GetTalentTabInfo(tab, false, false, group)
        end
        points = tonumber(points) or 0
        local entry = { index = tab, name = name, points = points, talents = {} }
        result.tabs[#result.tabs + 1] = entry
        if points > bestPoints then
            bestPoints, result.primaryTab = points, tab
        elseif points == bestPoints then
            result.primaryTab = nil
        end
        local count = tonumber(GetNumTalents and GetNumTalents(tab, false, false, group)) or 0
        for talent = 1, count do
            local talentName, icon, tier, column, rank, maxRank, talentId
            if C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
                local info = C_SpecializationInfo.GetTalentInfo({
                    specializationIndex = tab, talentIndex = talent,
                    isInspect = false, isPet = false, groupIndex = group,
                })
                if info then
                    talentName, icon, tier, column = info.name, info.icon, info.tier, info.column
                    rank, maxRank, talentId = info.rank, info.maxRank, info.talentID
                end
            elseif GetTalentInfo then
                local meetsPrereq, previewRank, meetsPreviewPrereq, isExceptional, hasGoldBorder
                talentName, icon, tier, column, rank, maxRank, meetsPrereq, previewRank,
                    meetsPreviewPrereq, isExceptional, hasGoldBorder, talentId =
                    GetTalentInfo(tab, talent, false, false, group)
            end
            local definition = {
                index = talent, name = talentName, icon = icon, tier = tier, column = column,
                rank = tonumber(rank) or 0, maxRank = tonumber(maxRank) or 0, talentId = talentId,
            }
            entry.talents[#entry.talents + 1] = definition
            if talentId and definition.rank > 0 then
                result.ranksByTalentId[talentId] = definition.rank
            end
        end
    end
    return result
end

function P.GetSnapshot()
    local classToken, raceToken
    if UnitClass then local _; _, classToken = UnitClass("player") end
    if UnitRace then local _; _, raceToken = UnitRace("player") end
    local group = activeTalentGroup()
    local form = tonumber(GetShapeshiftForm and GetShapeshiftForm()) or 0
    local formSpellId
    if form > 0 and GetShapeshiftFormInfo then
        local _, _, _, spellId = GetShapeshiftFormInfo(form)
        formSpellId = spellId
    end
    return {
        classToken = classToken,
        raceToken = raceToken,
        level = tonumber(UnitLevel and UnitLevel("player")) or 0,
        talentGroup = group,
        talents = talentSnapshot(group),
        form = form,
        formSpellId = formSpellId,
        stealthed = IsStealthed and IsStealthed() == true or false,
    }
end

function P.GetActiveTalentGroup() return activeTalentGroup() end
function P.GetClassToken()
    if not UnitClass then return nil end
    local _, token = UnitClass("player")
    return token
end
function P.GetRaceToken()
    if not UnitRace then return nil end
    local _, token = UnitRace("player")
    return token
end
function P.GetLevel() return tonumber(UnitLevel and UnitLevel("player")) or 0 end
function P.GetForm() return tonumber(GetShapeshiftForm and GetShapeshiftForm()) or 0 end
function P.GetFormSpellId()
    local form = P.GetForm()
    if form <= 0 or not GetShapeshiftFormInfo then return nil end
    local _, _, _, spellId = GetShapeshiftFormInfo(form)
    return spellId
end
function P.IsStealthed() return IsStealthed and IsStealthed() == true or false end
