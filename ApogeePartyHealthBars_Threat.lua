local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_Threat = {}
local H = ApogeePartyHealthBars_Threat

local rows, syncTicker
local needsTicker = false
local CHALLENGER_UNITS = {
    "player", "party1", "party2", "party3", "party4",
    "pet", "partypet1", "partypet2", "partypet3", "partypet4",
}

local FALLBACK_COLORS = {
    [1] = { 1.00, 0.85, 0.10 },
    [2] = { 1.00, 0.50, 0.00 },
    [3] = { 1.00, 0.10, 0.10 },
}

local function IsEnabled()
    return S.sv and S.sv.threatEnabled == true
end

local function IsMarginEnabled()
    return IsEnabled() and S.sv and S.sv.threatPercentEnabled == true
end

local function GetStatusColor(status)
    local r, g, b
    if status and GetThreatStatusColor then r, g, b = GetThreatStatusColor(status) end
    if r then return r, g, b end
    local color = FALLBACK_COLORS[status] or FALLBACK_COLORS[1]
    return color[1], color[2], color[3]
end

local function StyleText(fontString)
    fontString:SetFontObject("GameFontHighlightSmall")
    local fontPath, size = fontString:GetFont()
    if fontPath and size then fontString:SetFont(fontPath, size, "OUTLINE") end
end

local function CreateVisuals(row)
    local rail = row.btn:CreateTexture(nil, "OVERLAY")
    rail:SetWidth(C.THREAT_RAIL_W)
    rail:SetPoint("TOPRIGHT", row.barBg, "TOPLEFT", -C.THREAT_RAIL_GAP, 0)
    rail:SetPoint("BOTTOMRIGHT", row.barBg, "BOTTOMLEFT", -C.THREAT_RAIL_GAP, 0)
    rail:Hide()

    local pulse = rail:CreateAnimationGroup()
    local fadeOut = pulse:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.25)
    fadeOut:SetDuration(0.12)
    fadeOut:SetOrder(1)
    local fadeIn = pulse:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.25)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.20)
    fadeIn:SetOrder(2)

    local text = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("RIGHT", row.barBg, "LEFT",
        -(C.THREAT_RAIL_GAP + C.THREAT_RAIL_W + C.THREAT_TEXT_GAP), 0)
    text:SetWidth(C.THREAT_TEXT_W)
    text:SetJustifyH("RIGHT")
    text:SetWordWrap(false)
    text:SetMaxLines(1)
    StyleText(text)
    text:Hide()

    row.threatRail = rail
    row.threatPulse = pulse
    row.threatText = text
end

local function HideRow(row, clearStatus)
    row.threatRail:Hide()
    row.threatText:Hide()
    if clearStatus then row._threatStatus = nil end
end

local function BuildSnapshot()
    local snapshot = { details = {} }
    snapshot.hasTarget = UnitDetailedThreatSituation and UnitExists("target")
        and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    if not snapshot.hasTarget then return snapshot end

    for _, unitId in ipairs(CHALLENGER_UNITS) do
        if UnitExists(unitId) then
            local isTanking, status, scaledPercent = UnitDetailedThreatSituation(unitId, "target")
            if type(scaledPercent) == "number" then
                snapshot.details[unitId] = {
                    isTanking = isTanking,
                    status = status,
                    scaledPercent = scaledPercent,
                }
            end
        end
    end
    return snapshot
end

local function GetClosestChallenger(snapshot, tankUnit)
    local closest = 0
    for unitId, detail in pairs(snapshot.details) do
        if unitId ~= tankUnit then closest = math.max(closest, detail.scaledPercent) end
    end
    return closest
end

local function SetMarginText(row, detail, snapshot)
    if not IsMarginEnabled() or not detail then
        row.threatText:Hide()
        return
    end

    local displayPercent = detail.scaledPercent
    local prefix = ""
    if detail.isTanking then
        displayPercent = math.max(0, 100 - GetClosestChallenger(snapshot, row.unitId))
        prefix = "+"
    end

    local rounded = math.floor(displayPercent + 0.5)
    row.threatText:SetText(string.format("%s%d%%", prefix, rounded))

    local r, g, b
    if detail.isTanking then
        if rounded > 30 then
            r, g, b = 0.30, 1.00, 0.35
        elseif rounded > 10 then
            r, g, b = 1.00, 0.85, 0.10
        else
            r, g, b = 1.00, 0.15, 0.15
        end
    elseif rounded >= 90 then
        r, g, b = 1.00, 0.15, 0.15
    elseif rounded >= 70 then
        r, g, b = 1.00, 0.85, 0.10
    else
        r, g, b = 0.85, 0.85, 0.85
    end
    row.threatText:SetTextColor(r, g, b, 1)
    row.threatText:Show()
end

local function RenderRow(row, snapshot)
    if not IsEnabled() or not row.btn:IsShown() or not UnitExists(row.unitId) then
        HideRow(row, true)
        return
    end

    local status = UnitThreatSituation and UnitThreatSituation(row.unitId) or nil
    if status and status > 0 then
        local r, g, b = GetStatusColor(status)
        row.threatRail:SetColorTexture(r, g, b, 1)
        row.threatRail:Show()
        local previous = row._threatStatus or 0
        if status >= 2 and previous < 2 then
            row.threatPulse:Stop()
            row.threatPulse:Play()
        end
    else
        row.threatRail:Hide()
    end

    SetMarginText(row, snapshot.details[row.unitId], snapshot)
    row._threatStatus = status
end

function H.Attach(unitRows, syncCallback)
    rows = unitRows
    syncTicker = syncCallback
    for i = 1, C.MAX_ROWS do CreateVisuals(rows[i]) end
end

function H.GetGutterWidth()
    if not IsMarginEnabled() then return 0 end
    return C.THREAT_TEXT_W + C.THREAT_TEXT_GAP + C.THREAT_RAIL_W + C.THREAT_RAIL_GAP
end

function H.IsActive()
    return IsEnabled() and needsTicker
end

function H.Refresh()
    if not rows then return end
    needsTicker = false
    if IsEnabled() then
        if UnitAffectingCombat then
            for i = 1, C.MAX_ROWS do
                if UnitExists(rows[i].unitId) and UnitAffectingCombat(rows[i].unitId) then
                    needsTicker = true
                    break
                end
            end
        else
            needsTicker = true
        end
    end
    local snapshot = BuildSnapshot()
    for i = 1, C.MAX_ROWS do RenderRow(rows[i], snapshot) end
    if syncTicker then syncTicker() end
end
