-- Passive, movable tank threat-control HUD.
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ThreatAwareness = {}
local A = ApogeePartyHealthBars_ThreatAwareness

local WIDTH, ROW_HEIGHT, HEADER_HEIGHT, FOOTER_HEIGHT = 284, 24, 0, 18
local CONTROL_BAR_WIDTH = 112
local QUEUE_LIMIT = 5
local ROW_GAP = 1
local ALERT_THROTTLE = 1.5
local COLORS = {
    safe = { 0.25, 0.85, 0.35 }, slipping = { 1.00, 0.82, 0.15 },
    critical = { 1.00, 0.35, 0.08 }, lost = { 1.00, 0.10, 0.10 },
}
local TARGET_COLOR = { 0.38, 0.72, 0.92 }
local D, frame, coverage
local rows = {}
local queueSlots = {}
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
    if unlocked and D and D.SettingsSurfaces then
        D.SettingsSurfaces.RefreshConfigurationPreviewDock("threatAwareness")
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
    name:SetWidth(135); name:SetJustifyH("LEFT")
    name:SetWordWrap(false)

    local controlBar = CreateFrame("Frame", nil, row)
    controlBar:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    controlBar:SetSize(CONTROL_BAR_WIDTH, 12)
    marker:SetPoint("RIGHT", controlBar, "LEFT", -5, 0)

    local controlBg = controlBar:CreateTexture(nil, "BACKGROUND")
    controlBg:SetAllPoints(); controlBg:SetColorTexture(0.13, 0.14, 0.16, 1)
    local controlFill = controlBar:CreateTexture(nil, "ARTWORK")
    controlFill:SetWidth(0)
    local zeroLine = controlBar:CreateTexture(nil, "OVERLAY")
    zeroLine:SetPoint("TOP", controlBar, "TOP", 0, -1)
    zeroLine:SetPoint("BOTTOM", controlBar, "BOTTOM", 0, 1)
    zeroLine:SetWidth(1); zeroLine:SetColorTexture(0.72, 0.72, 0.76, 0.9)
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
    row.controlBar, row.controlFill = controlBar, controlFill
    row.zeroLine = zeroLine
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

function A.GetControlDisplay(enemy)
    if not enemy or enemy.live == false or type(enemy.control) ~= "number" then return nil end
    local magnitude = math.max(0, math.min(100, math.abs(enemy.control)))
    local held = enemy.isTanking == true
    return {
        direction = held and "positive" or "negative",
        progress = magnitude,
    }
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
    row.name:SetWidth(enemy.raidMarker and 116 or 135)
    local name = A.GetEnemyName(enemy)
    local context = enemy.stale and "last seen" or nil
    row.name:SetText(name .. (context and ("  |cff77777f> " .. context .. "|r") or ""))
    if isCurrentTarget then
        row.name:SetTextColor(0.92, 0.97, 1.00)
    else
        row.name:SetTextColor(color[1], color[2], color[3])
    end

    local display = A.GetControlDisplay(enemy)
    row.controlBar:SetShown(display ~= nil)
    if display then
        row.controlFill:ClearAllPoints()
        if display.direction == "positive" then
            row.controlFill:SetPoint("TOPLEFT", row.controlBar, "TOP", 1, -1)
            row.controlFill:SetPoint("BOTTOMLEFT", row.controlBar, "BOTTOM", 1, 1)
        else
            row.controlFill:SetPoint("TOPRIGHT", row.controlBar, "TOP", -1, -1)
            row.controlFill:SetPoint("BOTTOMRIGHT", row.controlBar, "BOTTOM", -1, 1)
        end
        row.controlFill:SetWidth((CONTROL_BAR_WIDTH / 2 - 2) * display.progress / 100)
        row.controlFill:SetColorTexture(color[1], color[2], color[3], 1)
    end
    row:Show()
end

local function PreviewSnapshot()
    return {
        total = 7,
        limitedCoverage = false,
        demoHint = "Right = threat lead  |  Left = effort to regain",
        counts = { safe = 4, slipping = 1, critical = 1, lost = 1 },
        enemies = {
            { guid = "demo-lost", name = "Loose Marauder", severity = "lost", control = -38,
                isTanking = false, live = true, raidMarker = 8 },
            { guid = "demo-critical", name = "Pack Enforcer", severity = "critical", control = 7,
                isTanking = true, live = true, isCurrentTarget = true },
            { guid = "demo-slipping", name = "Restless Hound", severity = "slipping", control = 22,
                isTanking = true, live = true },
            { guid = "demo-safe-1", name = "Guarded Brute", severity = "safe", control = 48,
                isTanking = true, live = true },
            { guid = "demo-safe-2", name = "Guarded Mystic", severity = "safe", control = 55,
                isTanking = true, live = true },
            { guid = "demo-safe-3", name = "Guarded Scout", severity = "safe", control = 61,
                isTanking = true, live = true },
            { guid = "demo-safe-4", name = "Guarded Sentry", severity = "safe", control = 68,
                isTanking = true, live = true },
        },
    }
end

function A.GetDemoSnapshot() return PreviewSnapshot() end

local function FindCandidate(enemies, visible, predicate)
    for _, enemy in ipairs(enemies) do
        if enemy.guid and not visible[enemy.guid] and (not predicate or predicate(enemy)) then
            return enemy
        end
    end
    return nil
end

function A.ReconcileQueue(snapshot, previousSlots)
    snapshot = snapshot or { enemies = {}, total = 0 }
    previousSlots = previousSlots or {}
    local enemies = snapshot.enemies or {}
    local byGuid, visible = {}, {}
    for _, enemy in ipairs(enemies) do
        if enemy.guid then byGuid[enemy.guid] = enemy end
    end

    local slots = {}
    for index = 1, QUEUE_LIMIT do
        local guid = previousSlots[index]
        if guid and byGuid[guid] then
            slots[index] = guid
            visible[guid] = true
        end
    end

    for index = 1, QUEUE_LIMIT do
        if not slots[index] then
            local candidate = FindCandidate(enemies, visible, function(enemy)
                return enemy.live ~= false
            end) or FindCandidate(enemies, visible)
            if candidate then
                slots[index] = candidate.guid
                visible[candidate.guid] = true
            end
        end
    end

    while true do
        local hiddenLost = FindCandidate(enemies, visible, function(enemy)
            return enemy.severity == "lost" and enemy.live ~= false
        end)
        if not hiddenLost then break end
        local replacementIndex
        for index = 1, QUEUE_LIMIT do
            local enemy = slots[index] and byGuid[slots[index]] or nil
            if enemy and enemy.live == false then
                replacementIndex = index
                break
            end
        end
        local safestControl
        if not replacementIndex then
            for index = 1, QUEUE_LIMIT do
                local enemy = slots[index] and byGuid[slots[index]] or nil
                if enemy and enemy.isTanking == true and type(enemy.control) == "number"
                    and (safestControl == nil or enemy.control > safestControl) then
                    replacementIndex, safestControl = index, enemy.control
                end
            end
        end
        if not replacementIndex then break end
        visible[slots[replacementIndex]] = nil
        slots[replacementIndex] = hiddenLost.guid
        visible[hiddenLost.guid] = true
    end

    local presentation = { enemies = {}, slotGuids = slots, overflow = 0, visible = 0 }
    for index = 1, QUEUE_LIMIT do
        local enemy = slots[index] and byGuid[slots[index]] or nil
        presentation.enemies[index] = enemy
        if enemy then presentation.visible = presentation.visible + 1 end
    end
    presentation.overflow = math.max(0, (snapshot.total or #enemies) - presentation.visible)
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
    local overflow = tonumber(presentation and presentation.overflow) or 0
    if overflow > 0 then
        return "+" .. overflow .. " MORE"
            .. (snapshot.limitedCoverage and "  |  LIMITED COVERAGE" or "")
    end
    return snapshot.limitedCoverage
        and "LIMITED COVERAGE  |  Enable enemy nameplates" or ""
end

local function Render(snapshot, presentation)
    if not frame then return end
    snapshot = snapshot or { enemies = {}, total = 0, limitedCoverage = true }
    presentation = presentation or A.ReconcileQueue(snapshot, {})
    local footerText = A.GetFooterText(snapshot, presentation)
    coverage:SetText(footerText)
    local currentTargetGuid = not unlocked and UnitGUID and UnitGUID("target") or nil
    local highestSlot = 0
    for index = 1, QUEUE_LIMIT do
        local enemy = presentation.enemies[index]
        if enemy then
            RenderRow(rows[index] or CreateRow(index), enemy, currentTargetGuid)
            highestSlot = index
        elseif rows[index] then
            rows[index]:Hide()
        end
    end
    local displayedRows = math.max(highestSlot, unlocked and 1 or 0)
    local hasFooter = footerText ~= ""
    local height = HEADER_HEIGHT + displayedRows * (ROW_HEIGHT + ROW_GAP)
        + (hasFooter and FOOTER_HEIGHT or 5)
    frame:SetSize(WIDTH, height)
    local shouldShow = unlocked or (IsEnabled() and not S.configMode
        and (snapshot.total or 0) > 0)
    frame:SetShown(shouldShow)
end

function A.Refresh(suppressAlert)
    A.Build()
    local enabled = IsEnabled()
    if not unlocked and not enabled then
        if observing then D.Observer.ResetHistory(); observing = false end
        queueSlots = {}
        local empty = {
            enemies = {}, counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
            total = 0, limitedCoverage = true, lostTransitions = {},
        }
        Render(empty, A.ReconcileQueue(empty, {}))
        return empty
    end

    local snapshot, presentation
    if unlocked then
        snapshot = PreviewSnapshot()
        presentation = A.ReconcileQueue(snapshot, {})
    else
        snapshot = D.Observer.Refresh()
        observing = true
        if (snapshot.total or 0) == 0 then queueSlots = {} end
        presentation = A.ReconcileQueue(snapshot, queueSlots)
        queueSlots = presentation.slotGuids
    end
    local now = D.Now()
    if not suppressAlert and A.ShouldPlayLostAlert(
        snapshot, enabled, unlocked, now, lastAlertAt) then
        D.Sounds.Play(Saved().threatAwarenessSoundKey)
        lastAlertAt = now
    end
    Render(snapshot, presentation)
    return snapshot
end

function A.SetSoundKey(key)
    Saved().threatAwarenessSoundKey = D.Sounds.NormalizeKey(key, "alarm_soft", true)
end
function A.GetSoundKey()
    return D.Sounds.NormalizeKey(Saved().threatAwarenessSoundKey, "alarm_soft", true)
end
function A.PreviewSound() D.Sounds.Play(A.GetSoundKey()) end
function A.IsActive() return IsEnabled() or unlocked end

function A.SetUnlocked(value)
    A.Build()
    local nextUnlocked = value == true and not (InCombatLockdown and InCombatLockdown())
    local wasUnlocked = unlocked
    unlocked = nextUnlocked
    if nextUnlocked and not wasUnlocked then
        D.SettingsSurfaces.DockConfigurationPreview("threatAwareness")
    elseif wasUnlocked and not nextUnlocked then
        D.SettingsSurfaces.ReleaseConfigurationPreview("threatAwareness")
    end
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
    frame:SetScript("OnDragStart", function(self)
        if not unlocked then return end
        D.SettingsSurfaces.MarkConfigurationPreviewMoved("threatAwareness")
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self) if unlocked then self:StopMovingOrSizing(); SavePosition() end end)
    coverage = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    coverage:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 5)
    coverage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 5)
    coverage:SetJustifyH("CENTER"); coverage:SetWordWrap(false)
    coverage:SetTextColor(0.55, 0.55, 0.60)
    D.SettingsSurfaces.Register("threatAwareness", frame, {
        automaticChrome = false,
        configurationStrata = "HIGH",
    })
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
