local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities
local Observer = ApogeePartyHealthBars_ThreatObserver

ApogeePartyHealthBars_Threat = {}
local H = ApogeePartyHealthBars_Threat

local rows, syncTicker
local needsTicker = false
local FALLBACK_COLORS = {
    [1] = { 1.00, 0.85, 0.10 },
    [2] = { 1.00, 0.50, 0.00 },
    [3] = { 1.00, 0.10, 0.10 },
}

local function IsEnabled()
    return S.sv and S.sv.threatEnabled == true
        and (not ClientCapabilities or ClientCapabilities.IsFeatureAvailable("threat"))
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

    local barBg = row.btn:CreateTexture(nil, "BACKGROUND")
    barBg:SetColorTexture(0.04, 0.04, 0.04, 0.80)
    barBg:SetPoint("TOPRIGHT", row.barBg, "TOPLEFT",
        -(C.THREAT_RAIL_GAP + C.THREAT_RAIL_W + C.THREAT_TEXT_GAP), 0)
    barBg:SetPoint("BOTTOMRIGHT", row.barBg, "BOTTOMLEFT",
        -(C.THREAT_RAIL_GAP + C.THREAT_RAIL_W + C.THREAT_TEXT_GAP), 0)
    barBg:SetWidth(C.THREAT_TEXT_W)
    barBg:Hide()

    local fill = row.btn:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPRIGHT", barBg, "TOPRIGHT", 0, 0)
    fill:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", 0, 0)
    fill:SetWidth(0)
    fill:Hide()

    row.threatRail = rail
    row.threatPulse = pulse
    row.threatBarBg = barBg
    row.threatBarFill = fill
end

local function HideRow(row, clearStatus)
    row.threatRail:Hide()
    row.threatBarBg:Hide()
    row.threatBarFill:Hide()
    if clearStatus then row._threatStatus = nil end
end

local function BuildSnapshot()
    local snapshot = { details = {} }
    snapshot.hasTarget = UnitDetailedThreatSituation and UnitExists("target")
        and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    if not snapshot.hasTarget then return snapshot end

    snapshot.details = Observer.GetThreatDetails("target")
    return snapshot
end

local function GetClosestChallenger(snapshot, tankUnit)
    local closest = 0
    for unitId, detail in pairs(snapshot.details) do
        if unitId ~= tankUnit then closest = math.max(closest, detail.scaledPercent) end
    end
    return closest
end

local function SetMarginBar(row, detail, snapshot)
    if not IsMarginEnabled() or not detail then
        row.threatBarBg:Hide()
        row.threatBarFill:Hide()
        return
    end

    local displayPercent = detail.scaledPercent
    if detail.isTanking then
        displayPercent = math.max(0, 100 - GetClosestChallenger(snapshot, row.unitId))
    end

    local rounded = math.floor(displayPercent + 0.5)
    local clamped = math.max(0, math.min(100, rounded))

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
    row.threatBarFill:SetColorTexture(r, g, b, 1)
    row.threatBarFill:SetWidth(C.THREAT_TEXT_W * clamped / 100)
    row.threatBarBg:Show()
    row.threatBarFill:Show()
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

    SetMarginBar(row, snapshot.details[row.unitId], snapshot)
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
