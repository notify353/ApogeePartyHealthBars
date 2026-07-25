local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local Data = ApogeePartyHealthBars_CleanseData

ApogeePartyHealthBars_CleanseWatch = {}
local Watch = ApogeePartyHealthBars_CleanseWatch

local FRAME_WIDTH, LANE_HEIGHT = 500, 84
local BUTTON_WIDTH, BUTTON_HEIGHT, BUTTON_GAP = 84, 16, 3
local LANE_SIDE_PADDING, CONTENT_TOP = 6, 15
local BUTTON_BOTTOM, CONTENT_BUTTON_GAP = 3, 2
local ICON_SIZE, ICON_GAP, TITLE_DESCRIPTION_GAP = 22, 5, 1
local MIN_DESCRIPTION_FONT_SIZE = 4
local DEFAULT_POINT, DEFAULT_X, DEFAULT_Y = "TOPRIGHT", 0, 0
local units = C.SLOT_UNITS
local D, frame, bodyBackground
local lanes, capabilities = {}, {}
local ignoredEffects = {}
local unlocked = false

local function capFontSize(fontString, maximumSize)
    local fontPath, size, fontFlags = fontString:GetFont()
    if fontPath and size and size > maximumSize then
        fontString:SetFont(fontPath, maximumSize, fontFlags)
    end
end

local function saved()
    return S.sv or {}
end

local function hasCapabilities()
    return Data.HasCapability(capabilities)
end

local function isEnabled()
    return saved().cleanseWatchEnabled ~= false and hasCapabilities()
end

local function shouldShowFrame()
    return isEnabled() or (unlocked and hasCapabilities())
end

local function formatTime(remaining)
    if remaining == math.huge then return "" end
    if remaining >= 60 then return string.format("%dm", math.ceil(remaining / 60)) end
    return string.format("%ds", math.max(0, math.ceil(remaining)))
end

local function configureButton(button, capability)
    button.capability = capability
    if capability then
        button:SetAttribute("type", "spell")
        -- An unranked cast name lets Classic choose the highest learned rank.
        button:SetAttribute("spell",
            capability.baseName or capability.spellName or capability.spellId)
        button:Show()
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button:Hide()
    end
end

local function setButtonVisual(button, active, label)
    local alpha = active and 1 or 0
    button.background:SetAlpha(alpha)
    button.label:SetAlpha(alpha)
    button.label:SetText(active and label or "")
    for _, edge in ipairs(button.border) do edge:SetAlpha(alpha) end
    -- Secure buttons must retain their unit and spell attributes in combat.
    -- Cover inactive buttons with an ordinary frame instead of mutating their
    -- protected mouse state, so hidden slots cannot cast while UNIT_AURA
    -- updates remain combat-safe.
    button.inputShield:SetShown(button.capability ~= nil and not active)
    button.active = active
end

local function setLaneVisual(lane, shown)
    local alpha = shown and 1 or 0
    lane.background:SetAlpha(alpha)
    lane.typeTitle:SetAlpha(alpha)
    if not shown then
        lane.emptyLabel:SetAlpha(0)
        lane.effectCard.icon:SetAlpha(0)
        lane.effectCard.title:SetAlpha(0)
        lane.effectCard.description:SetAlpha(0)
    end
end

local function layoutCapabilities()
    local laneCount, verticalOffset = 0, 0
    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        local lane = lanes[dispelType]
        lane.capability = capabilities[dispelType]
        if lane.capability then
            laneCount = laneCount + 1
            lane.layoutHeight = LANE_HEIGHT
            lane:SetHeight(lane.layoutHeight)
            lane:ClearAllPoints()
            lane:SetPoint("TOPLEFT", frame, "TOPLEFT", 0,
                -verticalOffset)
            lane:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0,
                -verticalOffset)
            verticalOffset = verticalOffset + lane.layoutHeight
            for _, button in ipairs(lane.buttons) do
                configureButton(button, lane.capability)
            end
        else
            lane:ClearAllPoints()
            for _, button in ipairs(lane.buttons) do configureButton(button, nil) end
            setLaneVisual(lane, false)
        end
    end
    frame:SetHeight(laneCount > 0 and verticalOffset or LANE_HEIGHT)
end

local function applyOutOfCombatState()
    if InCombatLockdown and InCombatLockdown() then return false end
    local configurationVisible = unlocked and hasCapabilities()
    frame:EnableMouse(configurationVisible)
    if configurationVisible then
        frame:RegisterForDrag("LeftButton")
    else
        frame:RegisterForDrag()
    end
    D.ConfigSurfaces.SetSurfaceChromeShown("cleanse", configurationVisible)
    frame:SetShown(shouldShowFrame())
    return true
end

local function reconcileSecure()
    if not frame then return false end
    if InCombatLockdown and InCombatLockdown() then
        D.SecureFrames.RequestSecureUpdate()
        return false
    end
    local _, _, knownList = D.PlayerSpells.BuildKnownSpellMap()
    capabilities = Data.ResolveCapabilities(knownList)
    layoutCapabilities()
    applyOutOfCombatState()
    return true
end

local function auraKey(aura)
    return aura.spellId and ("id:" .. tostring(aura.spellId))
        or ("name:" .. tostring(aura.name or "Unknown"))
end

local function displayUnitName(unitIndex, unitId)
    local name = UnitName and UnitName(unitId)
    if name and name ~= "" then return name end
    return unitIndex == 1 and "Player" or ("Party " .. tostring(unitIndex - 1))
end

local function injectConfigurationPreviews(state)
    if not unlocked then return end
    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        local typeState = state[dispelType]
        local definitions = Data.CONFIG_PREVIEW_DEBUFFS[dispelType]
        if capabilities[dispelType] and typeState.count == 0 and definitions then
            for index, definition in ipairs(definitions) do
                local unitIndex = math.min(index, #units)
                local remaining = 18 + (index - 1) * 24
                local effect = {
                    name = definition.name,
                    icon = D.PlayerSpells.GetSpellTexture(definition.spellId),
                    spellId = definition.spellId,
                    applications = dispelType == "Poison" and index == 1 and 3 or 1,
                    earliest = remaining,
                    fallbackDescription = definition.fallbackDescription,
                    members = {{
                        unitId = units[unitIndex],
                        name = displayUnitName(unitIndex, units[unitIndex]),
                        remaining = remaining,
                    }},
                }
                typeState.effects[#typeState.effects + 1] = effect
                typeState.effectsByKey[auraKey(effect)] = effect
                typeState.members[unitIndex] = {
                    primary = effect,
                    auras = { effect },
                    count = 1,
                }
                typeState.count = typeState.count + 1
            end
            typeState.preview = true
        end
    end
end

local function buildState(now)
    local state = {}
    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        state[dispelType] = { effects = {}, effectsByKey = {}, members = {}, count = 0 }
    end

    for unitIndex, unitId in ipairs(units) do
        if UnitExists and UnitExists(unitId) then
            local unitSnapshot = Data.BuildUnitSnapshot(
                D.Auras.GetUnitHarmfulAuraSnapshot(unitId), capabilities, now)
            for _, dispelType in ipairs(Data.TYPE_ORDER) do
                local group = unitSnapshot.byType[dispelType]
                if group then
                    local typeState = state[dispelType]
                    local visibleAuras = {}
                    for _, aura in ipairs(group.auras) do
                        local key = auraKey(aura)
                        if not ignoredEffects[key] then
                            visibleAuras[#visibleAuras + 1] = aura
                            local effect = typeState.effectsByKey[key]
                            if not effect then
                                effect = {
                                    key = key,
                                    name = aura.name or dispelType,
                                    icon = aura.icon,
                                    spellId = aura.spellId,
                                    applications = aura.applications,
                                    earliest = aura.remaining,
                                    members = {},
                                }
                                typeState.effectsByKey[key] = effect
                                typeState.effects[#typeState.effects + 1] = effect
                            end
                            effect.earliest = math.min(
                                effect.earliest, aura.remaining)
                            effect.applications = math.max(
                                tonumber(effect.applications) or 0,
                                tonumber(aura.applications) or 0)
                            effect.members[#effect.members + 1] = {
                                unitId = unitId,
                                name = displayUnitName(unitIndex, unitId),
                                remaining = aura.remaining,
                            }
                        end
                    end
                    if #visibleAuras > 0 then
                        typeState.members[unitIndex] = {
                            primary = visibleAuras[1],
                            auras = visibleAuras,
                            count = #visibleAuras,
                        }
                        typeState.count = typeState.count + #visibleAuras
                    end
                end
            end
        end
    end

    for _, typeState in pairs(state) do
        table.sort(typeState.effects, function(left, right)
            if left.earliest ~= right.earliest then return left.earliest < right.earliest end
            return left.name < right.name
        end)
    end
    injectConfigurationPreviews(state)
    return state
end

local function memberSummary(effect)
    local values = {}
    for _, member in ipairs(effect.members) do
        local remaining = formatTime(member.remaining)
        values[#values + 1] = member.name .. (remaining ~= "" and (" " .. remaining) or "")
    end
    return table.concat(values, ", ")
end

local function measureEffectRow(effectRow)
    local titleHeight = effectRow.title.GetStringHeight
        and effectRow.title:GetStringHeight() or 10
    local descriptionHeight = effectRow.description.GetStringHeight
        and effectRow.description:GetStringHeight() or 10
    return math.max(ICON_SIZE,
        math.ceil(titleHeight + descriptionHeight + TITLE_DESCRIPTION_GAP))
end

local function fitDescription(effectRow)
    local description = effectRow.description
    local fontPath, baseSize, fontFlags =
        description.baseFontPath, description.baseFontSize,
        description.baseFontFlags
    if not (fontPath and baseSize and description.SetFont) then
        effectRow.layoutHeight = measureEffectRow(effectRow)
        return
    end

    local size = baseSize
    description:SetFont(fontPath, size, fontFlags)
    local measuredHeight = measureEffectRow(effectRow)
    while measuredHeight > effectRow.maxLayoutHeight
            and size > MIN_DESCRIPTION_FONT_SIZE do
        size = math.max(MIN_DESCRIPTION_FONT_SIZE, size - 0.5)
        description:SetFont(fontPath, size, fontFlags)
        measuredHeight = measureEffectRow(effectRow)
    end

    -- Blizzard descriptions are normally satisfied by the compact range
    -- above. Continue scaling only for an unusually verbose localized
    -- description so the complete text remains visible in the fixed,
    -- combat-safe lane instead of being clipped.
    while measuredHeight > effectRow.maxLayoutHeight and size > 1 do
        size = math.max(1, size - 0.5)
        description:SetFont(fontPath, size, fontFlags)
        measuredHeight = measureEffectRow(effectRow)
    end
    effectRow.descriptionFontSize = size
    effectRow.layoutHeight = measuredHeight
end

local function renderEffectRow(effectRow, effect)
    local alpha = effect and 1 or 0
    effectRow.icon:SetAlpha(alpha)
    effectRow.title:SetAlpha(alpha)
    effectRow.description:SetAlpha(alpha)
    if not effect then
        effectRow.title:SetText("")
        effectRow.description:SetText("")
        if effectRow.description.baseFontPath then
            effectRow.description:SetFont(
                effectRow.description.baseFontPath,
                effectRow.description.baseFontSize,
                effectRow.description.baseFontFlags)
        end
        effectRow.descriptionFontSize =
            effectRow.description.baseFontSize
        effectRow.layoutHeight = 0
        effectRow:SetHeight(0)
        return
    end

    effectRow.icon:SetTexture(effect.icon
        or D.PlayerSpells.GetSpellTexture(effect.spellId))
    local stacks = effect.applications and effect.applications > 1
        and (" x" .. tostring(effect.applications)) or ""
    effectRow.title:SetText("|cffffffff" .. effect.name .. stacks
        .. "|r  |cff9aa3ad" .. memberSummary(effect) .. "|r")
    local description = D.PlayerSpells.GetSpellDescription(effect.spellId)
    description = description and description ~= ""
        and description or effect.fallbackDescription or "Description is loading…"
    effectRow.description:SetText("|cffc7ccd3" .. tostring(description) .. "|r")
    fitDescription(effectRow)
    effectRow:SetHeight(effectRow.layoutHeight)
end

local function layoutEffectCard(lane, effect)
    local effectCard = lane.effectCard
    effectCard:ClearAllPoints()
    if not effect then return end
    local contentTop = CONTENT_TOP
    local contentBottom = (lane.layoutHeight or LANE_HEIGHT)
        - (BUTTON_BOTTOM + BUTTON_HEIGHT + CONTENT_BUTTON_GAP)
    local freeSpace = math.max(
        0, contentBottom - contentTop - effectCard.layoutHeight)
    local topOffset = contentTop + math.floor(freeSpace / 2)
    effectCard:SetPoint(
        "TOPLEFT", lane, "TOPLEFT", LANE_SIDE_PADDING, -topOffset)
    effectCard:SetPoint(
        "TOPRIGHT", lane, "TOPRIGHT", -LANE_SIDE_PADDING, -topOffset)
end

local function render()
    if not frame then return end
    local state = buildState(D.Now())
    local activeCount = 0
    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        if lanes[dispelType].capability then
            activeCount = activeCount + state[dispelType].count
        end
    end
    local panelActive = activeCount > 0

    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        local lane = lanes[dispelType]
        local typeState = state[dispelType]
        local active = lane.capability and typeState.count > 0
        if active then
            local primaryEffect = typeState.effects[1]
            local hiddenEffectCount = math.max(0, #typeState.effects - 1)
            local suffix = hiddenEffectCount > 0
                and ("  ·  +" .. tostring(hiddenEffectCount) .. " more") or ""
            lane.typeTitle:SetText((typeState.preview
                and (dispelType .. "  ·  configuration preview")
                or (dispelType .. "  ·  " .. tostring(typeState.count)
                    .. " removable effect" .. (typeState.count == 1 and "" or "s")))
                .. suffix)
            lane.emptyLabel:SetAlpha(0)
            renderEffectRow(lane.effectCard, primaryEffect)
            layoutEffectCard(lane, primaryEffect)
            lane.ignoreButton.effectKey =
                not typeState.preview and primaryEffect.key or nil
            lane.ignoreButton.preview = typeState.preview == true
        elseif lane.capability and unlocked then
            lane.typeTitle:SetText(dispelType .. "  ·  clear")
            lane.emptyLabel:SetText("No removable " .. dispelType .. " effects.")
            lane.emptyLabel:SetAlpha(1)
            renderEffectRow(lane.effectCard, nil)
            layoutEffectCard(lane, nil)
            lane.ignoreButton.effectKey = nil
            lane.ignoreButton.preview = false
        else
            lane.ignoreButton.effectKey = nil
            lane.ignoreButton.preview = false
        end
        lane.ignoreButton:SetShown(
            lane.ignoreButton.effectKey ~= nil or lane.ignoreButton.preview)
        setLaneVisual(lane, lane.capability and (active or unlocked))

        for unitIndex, button in ipairs(lane.buttons) do
            local group = typeState.members[unitIndex]
            button.group = group
            local memberActive = active and group ~= nil
            setButtonVisual(button, memberActive,
                memberActive and displayUnitName(unitIndex, button.unitId) or "")
        end
    end

    -- Runtime lanes provide their own backgrounds. Keeping the shared body
    -- transparent prevents clean, fixed secure lanes from leaving a visible
    -- empty category or blank panel area. Configuration mode still shows the
    -- complete positioning surface.
    bodyBackground:SetAlpha(
        unlocked and hasCapabilities() and 1 or 0)
    if not (InCombatLockdown and InCombatLockdown()) then
        frame:SetShown(shouldShowFrame())
    end
end

function Watch.Initialize(deps)
    D = assert(deps, "CleanseWatch requires dependencies")
    for _, key in ipairs({
        "Auras", "PlayerSpells", "SecureFrames", "ConfigSurfaces", "Now",
    }) do
        assert(D[key] ~= nil, "CleanseWatch missing dependency: " .. key)
    end
end

function Watch.Build()
    if frame then return Watch end
    frame = CreateFrame("Frame", "ApogeePartyHealthBarsCleanseWatch", UIParent)
    frame:SetSize(FRAME_WIDTH, LANE_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)

    bodyBackground = frame:CreateTexture(nil, "BACKGROUND")
    bodyBackground:SetAllPoints()
    bodyBackground:SetColorTexture(0.018, 0.024, 0.035, 0.96)

    D.ConfigSurfaces.Register("cleanse", frame)

    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        local lane = CreateFrame("Frame", nil, frame)
        lane:SetHeight(LANE_HEIGHT)
        local background = lane:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        local color = Data.TYPE_COLORS[dispelType]
        background:SetColorTexture(color[1] * 0.08, color[2] * 0.08,
            color[3] * 0.08, 0.96)
        local laneTitle = lane:CreateFontString(
            nil, "ARTWORK", "GameFontNormalSmall")
        capFontSize(laneTitle, 9)
        laneTitle:SetPoint("TOPLEFT", lane, "TOPLEFT", 6, -2)
        laneTitle:SetJustifyH("LEFT")
        laneTitle:SetTextColor(color[1], color[2], color[3])
        local ignoreButton = CreateFrame("Button", nil, lane)
        ignoreButton:SetSize(44, 13)
        ignoreButton:SetPoint("TOPRIGHT", lane, "TOPRIGHT", -5, -1)
        ignoreButton:RegisterForClicks("LeftButtonUp")
        local ignoreBackground =
            ignoreButton:CreateTexture(nil, "BACKGROUND")
        ignoreBackground:SetAllPoints()
        ignoreBackground:SetColorTexture(0.08, 0.09, 0.11, 0.96)
        local ignoreLabel = ignoreButton:CreateFontString(
            nil, "ARTWORK", "GameFontHighlightSmall")
        capFontSize(ignoreLabel, 9)
        ignoreLabel:SetPoint("CENTER")
        ignoreLabel:SetText("Ignore")
        ignoreButton:SetScript("OnClick", function(self)
            if not self.effectKey then return end
            ignoredEffects[self.effectKey] = true
            render()
        end)
        ignoreButton:Hide()
        laneTitle:SetPoint("RIGHT", ignoreButton, "LEFT", -4, 0)
        local emptyLabel = lane:CreateFontString(
            nil, "ARTWORK", "GameFontHighlightSmall")
        capFontSize(emptyLabel, 9)
        emptyLabel:SetPoint("TOPLEFT", lane, "TOPLEFT", 6, -17)
        emptyLabel:SetPoint("RIGHT", lane, "RIGHT", -6, 0)
        emptyLabel:SetJustifyH("LEFT")

        lane.background, lane.typeTitle, lane.emptyLabel =
            background, laneTitle, emptyLabel
        lane.ignoreButton = ignoreButton
        local effectCard = CreateFrame("Frame", nil, lane)
        effectCard.maxLayoutHeight = LANE_HEIGHT
            - CONTENT_TOP
            - (BUTTON_BOTTOM + BUTTON_HEIGHT + CONTENT_BUTTON_GAP)
        effectCard:SetHeight(ICON_SIZE)
        local icon = effectCard:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local effectTitle = effectCard:CreateFontString(
            nil, "ARTWORK", "GameFontHighlightSmall")
        effectTitle:SetPoint("TOPLEFT", icon, "TOPRIGHT", ICON_GAP, 0)
        effectTitle:SetPoint("RIGHT", effectCard, "RIGHT", 0, 0)
        effectTitle:SetJustifyH("LEFT")
        effectTitle:SetWordWrap(false)
        local effectDescription = effectCard:CreateFontString(
            nil, "ARTWORK", "GameFontHighlightSmall")
        effectDescription:SetPoint(
            "TOPLEFT", effectTitle, "BOTTOMLEFT",
            0, -TITLE_DESCRIPTION_GAP)
        effectDescription:SetPoint("RIGHT", effectCard, "RIGHT", 0, 0)
        effectDescription:SetJustifyH("LEFT")
        effectDescription:SetJustifyV("TOP")
        effectDescription:SetWordWrap(true)
        effectDescription.baseFontPath,
            effectDescription.baseFontSize,
            effectDescription.baseFontFlags = effectDescription:GetFont()
        effectCard.icon = icon
        effectCard.title = effectTitle
        effectCard.description = effectDescription
        lane.effectCard = effectCard
        lane.buttons = {}

        local buttonStart = (FRAME_WIDTH
            - (#units * BUTTON_WIDTH + (#units - 1) * BUTTON_GAP)) / 2
        for unitIndex, unitId in ipairs(units) do
            local buttonOffset =
                buttonStart + (unitIndex - 1) * (BUTTON_WIDTH + BUTTON_GAP)
            local button = CreateFrame("Button",
                "ApogeePartyHealthBarsCleanse" .. dispelType .. tostring(unitIndex),
                lane, "SecureUnitButtonTemplate, SecureActionButtonTemplate")
            button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
            button:SetPoint("BOTTOMLEFT", lane, "BOTTOMLEFT",
                buttonOffset, BUTTON_BOTTOM)
            button:SetAttribute("unit", unitId)
            button:SetAttribute("useOnKeyDown", false)
            button:RegisterForClicks("AnyUp")
            local buttonBackground = button:CreateTexture(nil, "BACKGROUND")
            buttonBackground:SetAllPoints()
            buttonBackground:SetColorTexture(color[1] * 0.22, color[2] * 0.22,
                color[3] * 0.22, 0.98)
            local label = button:CreateFontString(
                nil, "ARTWORK", "GameFontHighlightSmall")
            capFontSize(label, 9)
            label:SetPoint("CENTER")
            label:SetWidth(BUTTON_WIDTH - 8)
            label:SetWordWrap(false)
            label:SetJustifyH("CENTER")
            button.unitId, button.dispelType = unitId, dispelType
            button.background, button.label = buttonBackground, label
            button.border = D.CreateBorder(button, 0, 1)

            local inputShield = CreateFrame("Frame", nil, lane)
            inputShield:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
            inputShield:SetPoint("BOTTOMLEFT", lane, "BOTTOMLEFT",
                buttonOffset, BUTTON_BOTTOM)
            inputShield:SetFrameLevel(button:GetFrameLevel() + 1)
            inputShield:EnableMouse(true)
            inputShield:SetPropagateMouseClicks(false)
            button.inputShield = inputShield

            lane.buttons[unitIndex] = button
        end
        lanes[dispelType] = lane
    end

    frame:SetScript("OnDragStart", function(self)
        if unlocked and not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        Watch.SetPosition(point, relativePoint, x, y)
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 0.1 then self.elapsed = 0; render() end
    end)
    Watch.RestorePosition()
    reconcileSecure()
    render()
    return Watch
end

function Watch.Refresh() render() end
function Watch.RefreshCapabilities()
    local changed = reconcileSecure()
    render()
    return changed
end
function Watch.ReconcileSecure() return reconcileSecure() end
function Watch.HasCapability() return hasCapabilities() end
function Watch.GetCapabilities() return capabilities end
function Watch.GetUnavailableReason()
    return hasCapabilities() and nil or "No supported cleanse spell learned."
end
function Watch.IsEnabled() return isEnabled() end

function Watch.SetUnlocked(value)
    local requested = value == true
    if requested and InCombatLockdown and InCombatLockdown() then return false end
    unlocked = requested
    if InCombatLockdown and InCombatLockdown() then
        D.SecureFrames.RequestSecureUpdate()
        render()
        return false
    end
    layoutCapabilities()
    applyOutOfCombatState()
    render()
    return true
end

function Watch.SetPosition(point, relativePoint, x, y)
    if not S.sv then return end
    S.sv.cleanseWatchPoint = point or DEFAULT_POINT
    S.sv.cleanseWatchRelPoint = relativePoint or point or DEFAULT_POINT
    S.sv.cleanseWatchX = tonumber(x) or DEFAULT_X
    S.sv.cleanseWatchY = tonumber(y) or DEFAULT_Y
end

function Watch.RestorePosition()
    if not frame then return end
    if InCombatLockdown and InCombatLockdown() then return false end
    local values = saved()
    frame:ClearAllPoints()
    frame:SetPoint(values.cleanseWatchPoint or DEFAULT_POINT, UIParent,
        values.cleanseWatchRelPoint or DEFAULT_POINT,
        tonumber(values.cleanseWatchX) or DEFAULT_X,
        tonumber(values.cleanseWatchY) or DEFAULT_Y)
    return true
end

function Watch.ResetPosition()
    if InCombatLockdown and InCombatLockdown() then return false end
    frame:ClearAllPoints()
    frame:SetPoint(DEFAULT_POINT, UIParent, DEFAULT_POINT,
        DEFAULT_X, DEFAULT_Y)
    Watch.SetPosition(DEFAULT_POINT, DEFAULT_POINT, DEFAULT_X, DEFAULT_Y)
    return true
end

function Watch.GetFrame() return frame end
function Watch.GetLanes() return lanes end
