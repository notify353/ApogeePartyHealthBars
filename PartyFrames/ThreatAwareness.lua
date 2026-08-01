-- Passive, movable multi-enemy threat awareness HUD.
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ThreatAwareness = {}
local A = ApogeePartyHealthBars_ThreatAwareness

local WIDTH, ROW_HEIGHT, HEADER_HEIGHT, FOOTER_HEIGHT = 284, 24, 0, 18
local RISK_BAR_WIDTH = 88
local QUEUE_LIMIT = 5
local ROW_GAP = 1
local ALERT_THROTTLE = 1.5
local COLORS = {
    safe = { 0.25, 0.85, 0.35 }, slipping = { 1.00, 0.82, 0.15 },
    critical = { 1.00, 0.35, 0.08 }, lost = { 1.00, 0.10, 0.10 },
}
local TARGET_COLOR = { 0.38, 0.72, 0.92 }
local MODES = { radar = true, alarm = true, queue = true }
local D, frame, coverage
local rows = {}
local unlocked = false
local positionLoaded = false
local lastAlertAt = -math.huge
local observing = false

local function Saved() return S.sv or {} end
local function IsEnabled()
    return Saved().enabled ~= false
        and Saved().threatAwarenessEnabled == true
        and (not D.IsSupported or D.IsSupported())
end

local function Mode()
    local mode = Saved().threatAwarenessMode
    return MODES[mode] and mode or "radar"
end

local function DisplayMode()
    return Mode()
end

local function SavePosition()
    if not frame or not S.sv then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    S.sv.threatAwarenessPoint, S.sv.threatAwarenessRelPoint = point, relPoint
    S.sv.threatAwarenessX, S.sv.threatAwarenessY = x, y
end

function A.ResetPosition()
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    if S.sv then
        S.sv.threatAwarenessPoint, S.sv.threatAwarenessRelPoint = nil, nil
        S.sv.threatAwarenessX, S.sv.threatAwarenessY = nil, nil
    end
end

function A.RestorePosition()
    if not frame then return end
    frame:ClearAllPoints()
    local sv = Saved()
    if type(sv.threatAwarenessX) == "number" and type(sv.threatAwarenessY) == "number" then
        local ok = pcall(frame.SetPoint, frame, sv.threatAwarenessPoint or "CENTER", UIParent,
            sv.threatAwarenessRelPoint or "CENTER", sv.threatAwarenessX, sv.threatAwarenessY)
        if ok then return end
    end
    A.ResetPosition()
end

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 5,
        -(HEADER_HEIGHT + (index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5,
        -(HEADER_HEIGHT + (index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetHeight(ROW_HEIGHT)
    local rail = row:CreateTexture(nil, "ARTWORK")
    rail:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    rail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    rail:SetWidth(3)
    local marker = row:CreateTexture(nil, "ARTWORK")
    marker:SetSize(14, 14)
    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    name:SetPoint("LEFT", row, "LEFT", 10, 0)
    name:SetWidth(159); name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    local riskBar = CreateFrame("Frame", nil, row)
    riskBar:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    riskBar:SetSize(RISK_BAR_WIDTH, 8)
    marker:SetPoint("RIGHT", riskBar, "LEFT", -5, 0)
    local riskBg = riskBar:CreateTexture(nil, "BACKGROUND")
    riskBg:SetAllPoints(); riskBg:SetColorTexture(0.13, 0.14, 0.16, 1)
    local riskFill = riskBar:CreateTexture(nil, "ARTWORK")
    riskFill:SetPoint("TOPLEFT", riskBar, "TOPLEFT", 1, -1)
    riskFill:SetPoint("BOTTOMLEFT", riskBar, "BOTTOMLEFT", 1, 1)
    riskFill:SetWidth(0)
    local targetOutline = {}
    local function TargetEdge(pointA, pointB, width, height)
        local edge = row:CreateTexture(nil, "OVERLAY")
        edge:SetPoint(pointA, row, pointA, 0, 0)
        edge:SetPoint(pointB, row, pointB, 0, 0)
        if width then edge:SetWidth(width) end
        if height then edge:SetHeight(height) end
        edge:SetColorTexture(TARGET_COLOR[1], TARGET_COLOR[2], TARGET_COLOR[3], 0.95)
        targetOutline[#targetOutline + 1] = edge
    end
    TargetEdge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
    row.rail = rail
    row.marker, row.name = marker, name
    row.riskBar, row.riskFill = riskBar, riskFill
    row.targetOutline = targetOutline
    rows[index] = row
    return row
end

function A.IsCurrentTarget(enemy, currentTargetGuid)
    return enemy ~= nil and (enemy.isCurrentTarget == true
        or (currentTargetGuid ~= nil and enemy.guid == currentTargetGuid))
end

function A.GetEnemyName(enemy)
    return tostring(enemy and enemy.name or "Enemy")
end

function A.GetRaidMarkerTexCoords(index)
    index = math.max(1, math.min(8, tonumber(index) or 1))
    local column = (index - 1) % 4
    local line = math.floor((index - 1) / 4)
    return column * 0.25, (column + 1) * 0.25, line * 0.5, (line + 1) * 0.5
end

function A.GetRiskProgress(enemy)
    if not enemy or enemy.live == false or type(enemy.margin) ~= "number" then return nil end
    if enemy.severity == "lost" then return 100 end
    local margin = math.max(0, math.min(100, enemy.margin))
    if enemy.severity == "critical" then
        return math.max(70, math.min(95, 95 - margin * 2.5))
    elseif enemy.severity == "slipping" then
        return math.max(35, math.min(70, 35 + (30 - margin) * 1.75))
    end
    return math.max(20, math.min(35, 35 - (margin - 30)))
end

local function RenderRow(row, enemy, currentTargetGuid)
    local color = COLORS[enemy.severity] or COLORS.safe
    local isCurrentTarget = A.IsCurrentTarget(enemy, currentTargetGuid)
    for _, edge in ipairs(row.targetOutline) do edge:SetShown(isCurrentTarget) end
    row.rail:SetColorTexture(color[1], color[2], color[3], 1)
    if enemy.raidMarker then
        row.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        if SetRaidTargetIconTexture then
            SetRaidTargetIconTexture(row.marker, enemy.raidMarker)
        else
            row.marker:SetTexCoord(A.GetRaidMarkerTexCoords(enemy.raidMarker))
        end
        row.marker:Show()
    else
        row.marker:Hide()
    end
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row, "LEFT", 10, 0)
    if enemy.raidMarker then
        row.name:SetWidth(140)
    else
        row.name:SetWidth(159)
    end
    local name = A.GetEnemyName(enemy)
    local context = enemy.stale and "last seen" or nil
    row.name:SetText(name .. (context and ("  |cff77777f> " .. context .. "|r") or ""))
    if isCurrentTarget then
        row.name:SetTextColor(0.92, 0.97, 1.00)
    else
        row.name:SetTextColor(color[1], color[2], color[3])
    end
    local progress = A.GetRiskProgress(enemy)
    row.riskBar:SetShown(progress ~= nil)
    if progress then
        row.riskFill:SetColorTexture(color[1], color[2], color[3], 1)
        row.riskFill:SetWidth((RISK_BAR_WIDTH - 2) * progress / 100)
    end
    row:Show()
end

local function PreviewSnapshot(requestedMode)
    local mode = MODES[requestedMode] and requestedMode or DisplayMode()
    if mode == "alarm" then
        return {
            total = 5, limitedCoverage = false,
            demoHint = "Appears only when threat is lost",
            counts = { safe = 2, slipping = 0, critical = 1, lost = 2 },
            enemies = {
                { name = "Loose Marauder", severity = "lost", victim = "Healer", margin = 38, live = true, raidMarker = 8, isCurrentTarget = true },
                { name = "Stray Hound", severity = "lost", victim = "Mage", margin = 64, live = true },
                { name = "Pack Enforcer", severity = "critical", victim = "Tank", margin = 7, live = true, isCurrentTarget = true },
                { name = "Guarded Brute", severity = "safe", victim = "Tank", margin = 48, live = true },
                { name = "Guarded Mystic", severity = "safe", victim = "Tank", margin = 55, live = true },
            },
        }
    elseif mode == "queue" then
        return {
            total = 7, limitedCoverage = false,
            demoHint = "5 most urgent  |  +2 more observed",
            counts = { safe = 4, slipping = 1, critical = 1, lost = 1 },
            enemies = {
                { name = "Loose Marauder", severity = "lost", victim = "Healer", margin = 38, live = true, raidMarker = 8 },
                { name = "Pack Enforcer", severity = "critical", victim = "Tank", margin = 7, live = true, isCurrentTarget = true },
                { name = "Restless Hound", severity = "slipping", victim = "Tank", margin = 22, live = true },
                { name = "Guarded Brute", severity = "safe", victim = "Tank", margin = 48, live = true },
                { name = "Guarded Mystic", severity = "safe", victim = "Tank", margin = 55, live = true },
                { name = "Guarded Scout", severity = "safe", victim = "Tank", margin = 61, live = true },
                { name = "Guarded Sentry", severity = "safe", victim = "Tank", margin = 68, live = true },
            },
        }
    end
    return {
        total = 6, limitedCoverage = false,
        demoHint = "Most urgent observed enemy",
        counts = { safe = 3, slipping = 1, critical = 1, lost = 1 },
        enemies = {
            { name = "Loose Marauder", severity = "lost", victim = "Healer", margin = 72, live = true, raidMarker = 8, isCurrentTarget = true },
            { name = "Pack Enforcer", severity = "critical", victim = "Tank", margin = 7, live = true },
            { name = "Restless Hound", severity = "slipping", victim = "Tank", margin = 22, live = true },
            { name = "Guarded Brute", severity = "safe", victim = "Tank", margin = 48, live = true },
            { name = "Guarded Mystic", severity = "safe", victim = "Tank", margin = 55, live = true },
            { name = "Guarded Scout", severity = "safe", victim = "Tank", margin = 61, live = true },
        },
    }
end

function A.GetDemoSnapshot(mode) return PreviewSnapshot(mode) end

local function DisplayEnemies(snapshot, mode)
    if mode == "alarm" then
        local result = {}
        for _, enemy in ipairs(snapshot.enemies or {}) do
            if enemy.severity == "lost" then result[#result + 1] = enemy end
        end
        return result, 1
    end
    return snapshot.enemies or {}, mode == "queue" and QUEUE_LIMIT or 1
end

function A.GetPresentation(snapshot, requestedMode)
    snapshot = snapshot or { enemies = {}, counts = {}, total = 0 }
    local mode = MODES[requestedMode] and requestedMode or "radar"
    local display, limit = DisplayEnemies(snapshot, mode)
    local enemies = {}
    for index = 1, math.min(#display, limit) do enemies[index] = display[index] end
    local counts = snapshot.counts or {}
    local presentation = { mode = mode, enemies = enemies, overflow = 0 }
    if mode == "radar" then
        presentation.title = "PACK RADAR"
        presentation.summary = string.format("%d ENEMIES  |  %d LOST  |  %d RISK",
            snapshot.total or 0, counts.lost or 0, (counts.critical or 0) + (counts.slipping or 0))
    elseif mode == "alarm" then
        presentation.title = "LOSS ALARM"
        presentation.summary = (counts.lost or 0) > 0
            and (tostring(counts.lost) .. " LOST") or "SECURE"
    else
        presentation.overflow = math.max(0, #(snapshot.enemies or {}) - QUEUE_LIMIT)
        presentation.title = "THREAT QUEUE"
        presentation.summary = presentation.overflow > 0
            and ("+" .. presentation.overflow .. " MORE") or "TOP 5"
    end
    return presentation
end

function A.ShouldPlayLostAlert(nextSnapshot, enabled, isPreview, now, previousAlertAt)
    return enabled == true and not isPreview
        and #(nextSnapshot and nextSnapshot.lostTransitions or {}) > 0
        and now - (previousAlertAt or -math.huge) >= ALERT_THROTTLE
end

function A.GetFooterText(snapshot, presentation)
    snapshot = snapshot or {}
    if snapshot.demoHint then return snapshot.demoHint end
    local overflow = presentation and presentation.mode == "queue"
        and tonumber(presentation.overflow) or 0
    if overflow > 0 then
        return "+" .. overflow .. " MORE"
            .. (snapshot.limitedCoverage and "  |  LIMITED COVERAGE" or "")
    end
    return snapshot.limitedCoverage
        and "LIMITED COVERAGE  |  Enable enemy nameplates" or ""
end

local function Render(snapshot)
    if not frame then return end
    snapshot = snapshot or { enemies = {}, counts = {}, total = 0, limitedCoverage = true }
    local mode = DisplayMode()
    local presentation = A.GetPresentation(snapshot, mode)
    local display = presentation.enemies
    local visible = #display
    local footerText = A.GetFooterText(snapshot, presentation)
    coverage:SetText(footerText)
    local currentTargetGuid = not unlocked and UnitGUID and UnitGUID("target") or nil
    for index = 1, visible do
        RenderRow(rows[index] or CreateRow(index), display[index], currentTargetGuid)
    end
    for index = visible + 1, #rows do rows[index]:Hide() end
    local displayedRows = math.max(visible, unlocked and 1 or 0)
    local hasFooter = footerText ~= ""
    local height = HEADER_HEIGHT + displayedRows * (ROW_HEIGHT + ROW_GAP)
        + (hasFooter and FOOTER_HEIGHT or 5)
    frame:SetSize(WIDTH, height)
    local shouldShow = unlocked or (IsEnabled() and not S.configMode
        and (mode ~= "alarm" or visible > 0) and (snapshot.total or 0) > 0)
    frame:SetShown(shouldShow)
end

function A.Refresh(suppressAlert)
    A.Build()
    local enabled = IsEnabled()
    if not unlocked and not enabled then
        if observing then D.Observer.ResetHistory(); observing = false end
        local empty = {
            enemies = {}, counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
            total = 0, limitedCoverage = true, lostTransitions = {},
        }
        Render(empty)
        return empty
    end
    local snapshot
    if unlocked then
        snapshot = PreviewSnapshot()
    else
        snapshot = D.Observer.Refresh()
        observing = true
    end
    local now = D.Now()
    if not suppressAlert and A.ShouldPlayLostAlert(
        snapshot, enabled, unlocked, now, lastAlertAt) then
        D.Sounds.Play(Saved().threatAwarenessSoundKey)
        lastAlertAt = now
    end
    Render(snapshot)
    return snapshot
end

function A.SetMode(mode)
    if not MODES[mode] then mode = "radar" end
    Saved().threatAwarenessMode = mode
    A.Refresh(true)
end
function A.GetMode() return Mode() end
function A.SetSoundKey(key) Saved().threatAwarenessSoundKey = D.Sounds.NormalizeKey(key, "alarm_soft", true) end
function A.GetSoundKey() return D.Sounds.NormalizeKey(Saved().threatAwarenessSoundKey, "alarm_soft", true) end
function A.PreviewSound() D.Sounds.Play(A.GetSoundKey()) end
function A.IsActive() return IsEnabled() or unlocked end

function A.SetUnlocked(value)
    A.Build()
    unlocked = value == true and not (InCombatLockdown and InCombatLockdown())
    frame:EnableMouse(unlocked)
    if unlocked then frame:RegisterForDrag("LeftButton") else frame:RegisterForDrag() end
    D.SettingsSurfaces.SetSurfaceChromeShown("threatAwareness", false)
    A.Refresh(true)
end

function A.Hide() if frame then frame:Hide() end end

function A.Build()
    if frame then
        if not positionLoaded and S.sv then A.RestorePosition(); positionLoaded = true end
        return frame
    end
    frame = CreateFrame("Frame", "ApogeePartyHealthBarsThreatAwarenessHud", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEADER_HEIGHT + ROW_HEIGHT + FOOTER_HEIGHT)
    frame:SetMovable(true); frame:SetClampedToScreen(true); frame:SetFrameStrata("MEDIUM")
    frame:SetScript("OnDragStart", function(self) if unlocked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) if unlocked then self:StopMovingOrSizing(); SavePosition() end end)
    coverage = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    coverage:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 5)
    coverage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 5)
    coverage:SetJustifyH("CENTER"); coverage:SetWordWrap(false)
    coverage:SetTextColor(0.55, 0.55, 0.60)
    D.SettingsSurfaces.Register("threatAwareness", frame, { automaticChrome = false })
    A.RestorePosition(); positionLoaded = S.sv ~= nil
    frame:Hide()
    return frame
end

function A.Initialize(deps)
    D = deps
    assert(D and D.Observer and D.Sounds and D.SettingsSurfaces and D.Now,
        "ThreatAwareness missing dependencies")
end

function A.GetFrame() return frame end
function A.GetRows() return rows end
