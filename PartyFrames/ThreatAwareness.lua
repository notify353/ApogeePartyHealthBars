-- Passive, fixed-position tank threat-control HUD.
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ThreatAwareness = {}
local A = ApogeePartyHealthBars_ThreatAwareness

local ROW_INSET, NAME_LEFT, NAME_WIDTH = 5, 10, 135
local CONTROL_BAR_WIDTH, CONTROL_BAR_HEIGHT, CONTROL_RIGHT = 112, 16, 7
local STATUS_BAR_HEIGHT = 5
local MARKER_WIDTH, MARKER_GAP, CENTER_GAP = 14, 5, 96
local WIDTH = ROW_INSET * 2 + NAME_LEFT + NAME_WIDTH + CENTER_GAP
    + MARKER_WIDTH + MARKER_GAP + CONTROL_BAR_WIDTH + CONTROL_RIGHT
local ROW_HEIGHT, FOOTER_HEIGHT = 24, 18
local QUEUE_LIMIT = 5
local DEBUFF_ICON_SIZE, DEBUFF_ICON_GAP, DEBUFF_LANE_GAP = 18, 2, 6
local DEBUFF_LIMIT = 6
local ROW_GAP = 1
local COLORS = {
    safe = { 0.25, 0.85, 0.35 }, slipping = { 1.00, 0.82, 0.15 },
    critical = { 1.00, 0.35, 0.08 }, lost = { 1.00, 0.10, 0.10 },
}
local TARGET_COLOR = { 0.38, 0.72, 0.92 }
local TARGET_INDICATOR_WIDTH = 3
local HEALTH_COLOR = { 0.18, 0.82, 0.30 }
local CAST_COLOR = { 1.00, 0.68, 0.12 }
local PROTECTED_CAST_COLOR = { 0.58, 0.58, 0.62 }
local D, frame, coverage
local rows = {}
local queueSlots = {}
local previewing = false
local observing = false
local previewCastEpoch

local function Saved() return S.sv or {} end
local function IsEnabled()
    local saved = Saved()
    return saved.enabled ~= false
        and saved.threatAwarenessEnabled == true
        and (not D.IsSupported or D.IsSupported())
end

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function EmptySnapshot(limitedCoverage)
    return {
        enemies = {},
        counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
        total = 0,
        limitedCoverage = limitedCoverage == true,
    }
end

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", ROW_INSET,
        -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -ROW_INSET,
        -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetHeight(ROW_HEIGHT)

    local rail = row:CreateTexture(nil, "ARTWORK")
    rail:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    rail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    rail:SetWidth(3)

    local marker = row:CreateTexture(nil, "ARTWORK")
    marker:SetSize(MARKER_WIDTH, MARKER_WIDTH)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    name:SetPoint("LEFT", row, "LEFT", NAME_LEFT, 0)
    name:SetWidth(NAME_WIDTH); name:SetJustifyH("LEFT")
    name:SetWordWrap(false)

    local statusBar = CreateFrame("Frame", nil, row)
    statusBar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -CONTROL_RIGHT, 1)
    statusBar:SetSize(CONTROL_BAR_WIDTH, STATUS_BAR_HEIGHT)
    local statusBackground = statusBar:CreateTexture(nil, "BACKGROUND")
    statusBackground:SetAllPoints()
    statusBackground:SetColorTexture(0.10, 0.10, 0.11, 0.85)
    local statusFill = statusBar:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBar, "TOPLEFT", 0, 0)
    statusFill:SetPoint("BOTTOMLEFT", statusBar, "BOTTOMLEFT", 0, 0)
    statusFill:SetWidth(0)
    statusFill:SetColorTexture(HEALTH_COLOR[1], HEALTH_COLOR[2], HEALTH_COLOR[3], 1)

    local controlBar = CreateFrame("Frame", nil, row)
    controlBar:SetPoint("TOPRIGHT", row, "TOPRIGHT", -CONTROL_RIGHT, -1)
    controlBar:SetSize(CONTROL_BAR_WIDTH, CONTROL_BAR_HEIGHT)
    marker:SetPoint("RIGHT", controlBar, "LEFT", -MARKER_GAP, 0)

    local controlBg = controlBar:CreateTexture(nil, "BACKGROUND")
    controlBg:SetAllPoints(); controlBg:SetColorTexture(0.13, 0.14, 0.16, 1)
    local controlFill = controlBar:CreateTexture(nil, "ARTWORK")
    controlFill:SetWidth(0)
    local zeroLine = controlBar:CreateTexture(nil, "OVERLAY")
    zeroLine:SetPoint("TOP", controlBar, "TOP", 0, -1)
    zeroLine:SetPoint("BOTTOM", controlBar, "BOTTOM", 0, 1)
    zeroLine:SetWidth(1); zeroLine:SetColorTexture(0.72, 0.72, 0.76, 0.9)
    local targetIndicator = row:CreateTexture(nil, "OVERLAY")
    targetIndicator:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    targetIndicator:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    targetIndicator:SetWidth(TARGET_INDICATOR_WIDTH)
    targetIndicator:SetColorTexture(TARGET_COLOR[1], TARGET_COLOR[2], TARGET_COLOR[3], 0.95)

    local debuffIcons = {}
    for slot = 1, DEBUFF_LIMIT do
        local holder = CreateFrame("Frame", nil, row)
        holder:SetSize(DEBUFF_ICON_SIZE, DEBUFF_ICON_SIZE)
        if slot == 1 then
            holder:SetPoint("LEFT", row, "RIGHT", DEBUFF_LANE_GAP, 0)
        else
            holder:SetPoint("LEFT", debuffIcons[slot - 1], "RIGHT", DEBUFF_ICON_GAP, 0)
        end
        local icon = holder:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local count = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        count:SetPoint("CENTER", holder, "CENTER", 0, 0)
        count:SetJustifyH("CENTER")
        holder.icon, holder.count = icon, count
        holder:Hide()
        debuffIcons[slot] = holder
    end
    local debuffOverflow = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    debuffOverflow:SetPoint("LEFT", debuffIcons[DEBUFF_LIMIT], "RIGHT", 3, 0)
    debuffOverflow:Hide()

    row.rail = rail
    row.marker, row.name = marker, name
    row.statusBar, row.statusFill = statusBar, statusFill
    row.controlBar, row.controlFill = controlBar, controlFill
    row.zeroLine = zeroLine
    row.targetIndicator = targetIndicator
    row.debuffIcons, row.debuffOverflow = debuffIcons, debuffOverflow
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
    index = Clamp(tonumber(index) or 1, 1, 8)
    local column = (index - 1) % 4
    local line = math.floor((index - 1) / 4)
    return column * 0.25, (column + 1) * 0.25, line * 0.5, (line + 1) * 0.5
end

function A.GetControlDisplay(enemy)
    if not enemy or enemy.live == false or type(enemy.control) ~= "number" then return nil end
    local magnitude = Clamp(math.abs(enemy.control), 0, 100)
    local held = enemy.isTanking == true
    return {
        direction = held and "positive" or "negative",
        progress = magnitude,
    }
end

function A.GetSmoothedControlWidth(current, target, elapsed)
    current, target = tonumber(current), tonumber(target)
    if not target then return nil end
    if not current or math.abs(target - current) <= 0.1 then return target end
    local blend = Clamp((tonumber(elapsed) or 0) * 24, 0, 1)
    return current + (target - current) * blend
end

function A.GetHealthDisplay(enemy)
    if not enemy or enemy.live == false or enemy.healthValid ~= true then return nil end
    local maximum = tonumber(enemy.healthMaximum)
    if not maximum or maximum <= 0 then return nil end
    local value = Clamp(tonumber(enemy.health) or 0, 0, maximum)
    return value / maximum
end

local function GetCastProgress(enemy, now)
    local cast = enemy and enemy.live ~= false and enemy.cast or nil
    local startTime = tonumber(cast and cast.startTime)
    local endTime = tonumber(cast and cast.endTime)
    now = tonumber(now)
    if not startTime or not endTime or not now or endTime <= startTime
        or now >= endTime then
        return nil
    end
    local progress
    if cast.isChannel == true then
        progress = (endTime - now) / (endTime - startTime)
    else
        progress = (now - startTime) / (endTime - startTime)
    end
    return Clamp(progress, 0, 1), cast.notInterruptible == true,
        cast.isChannel == true, cast.name
end

function A.GetCastDisplay(enemy, now)
    local progress, notInterruptible, isChannel, name = GetCastProgress(enemy, now)
    if progress == nil then return nil end
    return {
        progress = progress,
        notInterruptible = notInterruptible,
        isChannel = isChannel,
        name = name,
    }
end

function A.GetDemoCast(now, epoch)
    now, epoch = tonumber(now) or 0, tonumber(epoch) or 0
    local castDuration, healthDuration = 4, 1
    local phase = math.max(0, now - epoch) % (castDuration + healthDuration)
    if phase >= castDuration then return nil end
    local startTime = now - phase
    return {
        name = "Shadow Bolt",
        startTime = startTime,
        endTime = startTime + castDuration,
        notInterruptible = false,
        isChannel = false,
    }
end

function A.GetDebuffDisplay(enemy)
    if not enemy or enemy.live == false then return {}, 0 end
    return enemy.playerDebuffSlots or {},
        math.max(0, tonumber(enemy.playerDebuffOverflow) or 0)
end

function A.GetDebuffAlpha(aura, now)
    local expirationTime = tonumber(aura and aura.expirationTime) or 0
    now = tonumber(now) or 0
    local remaining = expirationTime - now
    if expirationTime <= 0 or remaining > 5 then return 1 end
    if remaining <= 0 then return 0 end
    local phase = (now * 2) % 1
    local triangle = math.abs(phase * 2 - 1)
    return 0.3 + 0.7 * triangle
end

local function RenderStatusBar(row, enemy, now)
    local castProgress, notInterruptible = GetCastProgress(enemy, now)
    local progress = castProgress or A.GetHealthDisplay(enemy)
    row.statusBar:SetShown(progress ~= nil)
    if progress == nil then return false end
    row.statusFill:SetWidth(CONTROL_BAR_WIDTH * progress)
    local color = HEALTH_COLOR
    if castProgress ~= nil then
        color = notInterruptible and PROTECTED_CAST_COLOR or CAST_COLOR
    end
    row.statusFill:SetColorTexture(color[1], color[2], color[3], 1)
    return castProgress ~= nil
end

local function ResetControlState(row)
    row.controlDirection = nil
    row.controlCurrentWidth = nil
    row.controlTargetWidth = nil
    row.controlFill:SetWidth(0)
end

local function SetControlDirection(row, direction)
    row.controlDirection = direction
    row.controlCurrentWidth = 0
    row.controlFill:SetWidth(0)
    row.controlFill:ClearAllPoints()
    if direction == "positive" then
        row.controlFill:SetPoint("TOPLEFT", row.controlBar, "TOP", 1, -1)
        row.controlFill:SetPoint("BOTTOMLEFT", row.controlBar, "BOTTOM", 1, 1)
    else
        row.controlFill:SetPoint("TOPRIGHT", row.controlBar, "TOP", -1, -1)
        row.controlFill:SetPoint("BOTTOMRIGHT", row.controlBar, "BOTTOM", -1, 1)
    end
end

local function HideRow(row)
    row.enemy = nil
    ResetControlState(row)
    row:Hide()
end

local function RenderRow(row, enemy, currentTargetGuid, now)
    if not row.enemy or row.enemy.guid ~= enemy.guid then ResetControlState(row) end
    row.enemy = enemy
    local color = COLORS[enemy.severity] or COLORS.safe
    local isCurrentTarget = A.IsCurrentTarget(enemy, currentTargetGuid)
    row.targetIndicator:SetShown(isCurrentTarget)
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
    local name = A.GetEnemyName(enemy)
    local suffix = enemy.stale and "  |cff77777f> last seen|r" or ""
    row.name:SetText(name .. suffix)
    if isCurrentTarget then
        row.name:SetTextColor(0.92, 0.97, 1.00)
    else
        row.name:SetTextColor(color[1], color[2], color[3])
    end

    RenderStatusBar(row, enemy, now)

    local display = A.GetControlDisplay(enemy)
    row.controlBar:SetShown(display ~= nil)
    if display then
        if row.controlDirection ~= display.direction then
            SetControlDirection(row, display.direction)
        end
        row.controlTargetWidth = (CONTROL_BAR_WIDTH / 2 - 2) * display.progress / 100
        if row.controlCurrentWidth == nil then
            row.controlCurrentWidth = row.controlTargetWidth
            row.controlFill:SetWidth(row.controlCurrentWidth)
        end
        row.controlFill:SetColorTexture(color[1], color[2], color[3], 1)
    else
        ResetControlState(row)
    end
    local debuffs, overflow = A.GetDebuffDisplay(enemy)
    for index, holder in ipairs(row.debuffIcons) do
        local aura = debuffs[index]
        if aura then
            holder.icon:SetTexture(aura.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local applications = tonumber(aura.applications) or 0
            holder.count:SetText(applications > 1 and tostring(applications) or "")
            holder:SetAlpha(A.GetDebuffAlpha(aura, now))
            holder:Show()
        else
            holder:Hide()
        end
    end
    row.debuffOverflow:SetText(overflow > 0 and ("+" .. overflow) or "")
    row.debuffOverflow:SetShown(overflow > 0)
    row:Show()
end

local function PreviewSnapshot()
    local now = D and D.Now and D.Now() or 0
    if previewCastEpoch == nil then previewCastEpoch = now - 1 end
    local demoCast = A.GetDemoCast(now, previewCastEpoch)
    return {
        total = 7,
        limitedCoverage = false,
        counts = { safe = 4, slipping = 1, critical = 1, lost = 1 },
        enemies = {
            { guid = "demo-lost", name = "Loose Marauder", severity = "lost", control = -38,
                isTanking = false, live = true, raidMarker = 8,
                health = 72, healthMaximum = 100, healthValid = true,
                playerDebuffSlots = {
                    { name = "Sunder Armor", icon = "Interface\\Icons\\Ability_Warrior_Sunder",
                        applications = 3, duration = 30, expirationTime = now + 18 },
                    false,
                    false,
                    { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", applications = 1,
                        duration = 15, expirationTime = now + 4 },
                    false,
                    false,
                }, playerDebuffOverflow = 0 },
            { guid = "demo-critical", name = "Pack Enforcer", severity = "critical", control = 7,
                isTanking = true, live = true, isCurrentTarget = true,
                health = 43, healthMaximum = 100, healthValid = true,
                cast = demoCast,
                playerDebuffSlots = {
                    { name = "Sunder Armor", icon = "Interface\\Icons\\Ability_Warrior_Sunder",
                        applications = 5, duration = 30, expirationTime = now + 24 },
                    false, false, false, false, false,
                }, playerDebuffOverflow = 0 },
            { guid = "demo-slipping", name = "Restless Hound", severity = "slipping", control = 22,
                isTanking = true, live = true, health = 61, healthMaximum = 100,
                healthValid = true },
            { guid = "demo-safe-1", name = "Guarded Brute", severity = "safe", control = 48,
                isTanking = true, live = true, health = 84, healthMaximum = 100,
                healthValid = true },
            { guid = "demo-safe-2", name = "Guarded Mystic", severity = "safe", control = 55,
                isTanking = true, live = true, health = 95, healthMaximum = 100,
                healthValid = true },
            { guid = "demo-safe-3", name = "Guarded Scout", severity = "safe", control = 61,
                isTanking = true, live = true },
            { guid = "demo-safe-4", name = "Guarded Sentry", severity = "safe", control = 68,
                isTanking = true, live = true },
        },
    }
end

function A.GetDemoSnapshot() return PreviewSnapshot() end

local function FindCandidate(enemies, occupiedGuids, predicate)
    for _, enemy in ipairs(enemies) do
        if enemy.guid and not occupiedGuids[enemy.guid]
            and (not predicate or predicate(enemy)) then
            return enemy
        end
    end
    return nil
end

local function AssignSlot(slots, occupiedGuids, index, enemy)
    local previousGuid = slots[index]
    if previousGuid then occupiedGuids[previousGuid] = nil end
    slots[index] = enemy.guid
    occupiedGuids[enemy.guid] = true
end

local function FindReplacementSlot(slots, byGuid)
    for index = 1, QUEUE_LIMIT do
        local enemy = slots[index] and byGuid[slots[index]] or nil
        if enemy and enemy.live == false then return index end
    end

    local replacementIndex, safestControl
    for index = 1, QUEUE_LIMIT do
        local enemy = slots[index] and byGuid[slots[index]] or nil
        if enemy and enemy.isTanking == true and type(enemy.control) == "number"
            and (safestControl == nil or enemy.control > safestControl) then
            replacementIndex, safestControl = index, enemy.control
        end
    end
    return replacementIndex
end

function A.ReconcileQueue(snapshot, previousSlots)
    snapshot = snapshot or { enemies = {}, total = 0 }
    previousSlots = previousSlots or {}
    local enemies = snapshot.enemies or {}
    local byGuid, occupiedGuids = {}, {}
    for _, enemy in ipairs(enemies) do
        if enemy.guid then byGuid[enemy.guid] = enemy end
    end

    local slots = {}
    for index = 1, QUEUE_LIMIT do
        local guid = previousSlots[index]
        if guid and byGuid[guid] then
            slots[index] = guid
            occupiedGuids[guid] = true
        end
    end

    for index = 1, QUEUE_LIMIT do
        if not slots[index] then
            local candidate = FindCandidate(enemies, occupiedGuids, function(enemy)
                return enemy.live ~= false
            end) or FindCandidate(enemies, occupiedGuids)
            if candidate then AssignSlot(slots, occupiedGuids, index, candidate) end
        end
    end

    while true do
        local hiddenLost = FindCandidate(enemies, occupiedGuids, function(enemy)
            return enemy.severity == "lost" and enemy.live ~= false
        end)
        if not hiddenLost then break end
        local replacementIndex = FindReplacementSlot(slots, byGuid)
        if not replacementIndex then break end
        AssignSlot(slots, occupiedGuids, replacementIndex, hiddenLost)
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

function A.GetFooterText(snapshot, presentation)
    snapshot = snapshot or {}
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
    local currentTargetGuid = not previewing and UnitGUID and UnitGUID("target") or nil
    local now
    local highestSlot = 0
    for index = 1, QUEUE_LIMIT do
        local enemy = presentation.enemies[index]
        if enemy then
            now = now or D.Now()
            RenderRow(rows[index] or CreateRow(index), enemy, currentTargetGuid, now)
            highestSlot = index
        elseif rows[index] then
            HideRow(rows[index])
        end
    end
    local displayedRows = math.max(highestSlot, previewing and 1 or 0)
    local hasFooter = footerText ~= ""
    local height = displayedRows * (ROW_HEIGHT + ROW_GAP)
        + (hasFooter and FOOTER_HEIGHT or 5)
    frame:SetSize(WIDTH, height)
    local shouldShow = previewing or (IsEnabled() and not S.configMode
        and (snapshot.total or 0) > 0)
    frame:SetShown(shouldShow)
end


function A.RefreshUnit(unit)
    if not frame or not frame:IsShown() or not D.UnitAPI then return false end
    local guid = D.UnitAPI.GetGUID(unit)
    if not guid then return false end
    local matchedRow
    for _, row in ipairs(rows) do
        if row.enemy and row.enemy.guid == guid then matchedRow = row; break end
    end
    if not matchedRow then return false end
    local health, healthMaximum, healthValid = D.UnitAPI.GetHealth(unit)
    local cast = D.UnitAPI.GetCast(unit)
    local enemy = matchedRow.enemy
    enemy.unit = unit
    enemy.health, enemy.healthMaximum = health, healthMaximum
    enemy.healthValid, enemy.cast = healthValid == true, cast
    RenderStatusBar(matchedRow, enemy, D.Now())
    return true
end

function A.Tick(elapsed)
    if not frame or not frame:IsShown() then return end
    local now = D.Now()
    for _, row in ipairs(rows) do
        local enemy = row.enemy
        if enemy and enemy.cast then
            if not RenderStatusBar(row, enemy, now) then enemy.cast = nil end
        end
        local targetWidth = row.controlTargetWidth
        if targetWidth ~= nil and row.controlCurrentWidth ~= targetWidth then
            local width = A.GetSmoothedControlWidth(
                row.controlCurrentWidth, targetWidth, elapsed)
            row.controlCurrentWidth = width
            row.controlFill:SetWidth(width)
        end
    end
end

function A.Refresh()
    A.Build()
    local enabled = IsEnabled()
    if not previewing and not enabled then
        if observing then D.Observer.ResetHistory(); observing = false end
        queueSlots = {}
        local empty = EmptySnapshot(true)
        Render(empty)
        return empty
    end

    local snapshot, presentation
    if previewing then
        snapshot = PreviewSnapshot()
        presentation = A.ReconcileQueue(snapshot, {})
    else
        snapshot = D.Observer.Refresh()
        observing = true
        if (snapshot.total or 0) == 0 then queueSlots = {} end
        presentation = A.ReconcileQueue(snapshot, queueSlots)
        queueSlots = presentation.slotGuids
    end
    Render(snapshot, presentation)
    return snapshot
end

function A.IsActive() return IsEnabled() or previewing end

function A.SetPreview(value)
    A.Build()
    local nextPreviewing = value == true
    if nextPreviewing and not previewing then
        previewCastEpoch = D.Now() - 1
    elseif not nextPreviewing then
        previewCastEpoch = nil
    end
    previewing = nextPreviewing
    D.SettingsSurfaces.SetSurfaceChromeShown("threatAwareness", false)
    A.Refresh()
end

function A.Hide() if frame then frame:Hide() end end

function A.Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "ApogeePartyHealthBarsThreatAwarenessHud", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, ROW_HEIGHT + FOOTER_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetMovable(false); frame:EnableMouse(false); frame:SetFrameStrata("MEDIUM")
    coverage = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    coverage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        -(ROW_INSET + CONTROL_RIGHT), 5)
    coverage:SetWidth(CONTROL_BAR_WIDTH)
    coverage:SetJustifyH("CENTER"); coverage:SetWordWrap(false)
    coverage:SetTextColor(0.55, 0.55, 0.60)
    D.SettingsSurfaces.Register("threatAwareness", frame, {
        automaticChrome = false,
        configurationStrata = "HIGH",
    })
    frame:Hide()
    return frame
end

function A.Initialize(deps)
    D = deps
    assert(D and D.Observer and D.SettingsSurfaces and D.Now and D.UnitAPI,
        "ThreatAwareness missing dependencies")
end

function A.GetFrame() return frame end
function A.GetRows() return rows end
