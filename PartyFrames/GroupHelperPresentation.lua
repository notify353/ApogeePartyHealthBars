local Presentation = {}
ApogeePartyHealthBars.Define("Runtime", "GroupHelperPresentation", Presentation)

local D
local rows = {}
local sidecar, commandRow, tankButton
local drinkCards = {}
local buffLanes = {}
local currentSnapshot = { eligible = false, visible = false, manaRows = {}, buffIssues = {} }
local previewSnapshot
local committedReserved = false

local SIDECAR_WIDTH = 140
local SIDECAR_GAP = 6
local DRINK_CARD_WIDTH = 84
local DRINK_CARD_HEIGHT = 22
local BUFF_LANE_WIDTH = 43
local BUFF_ICON_SIZE = 18
local BUFF_ICON_GAP = 3
local COMMAND_BUTTON_SIZE = 20
local COMMAND_EDGE_INSET = 0
local PULL_ONLY_ROW_WIDTH = COMMAND_EDGE_INSET * 2 + COMMAND_BUTTON_SIZE
local COMMAND_ROW_HEIGHT = 22
local COMMAND_GAP = 3
local TANK_ICON = "Interface\\Icons\\Ability_Warrior_Charge"

local COLORS = {
    surface = { 0.025, 0.030, 0.040, 0.88 },
    edge = { 0.18, 0.21, 0.27, 0.72 },
    detected = { 0.35, 0.82, 0.58, 1 },
    notDetected = { 0.94, 0.58, 0.24, 1 },
    unavailable = { 0.55, 0.58, 0.64, 1 },
}

local function setButtonEnabled(button, enabled)
    if D.Helpers.SetButtonEnabled then
        D.Helpers.SetButtonEnabled(button, enabled)
    elseif enabled then
        button:Enable()
    else
        button:Disable()
    end
end

local function createSurface(parent, height, frameType)
    local frame = CreateFrame(frameType or "Frame", nil, parent)
    frame:SetHeight(height)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(unpack(COLORS.surface))
    local edge = frame:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edge:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edge:SetWidth(2)
    edge:SetColorTexture(unpack(COLORS.edge))
    local top = frame:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(unpack(COLORS.edge))
    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    bottom:SetColorTexture(unpack(COLORS.edge))
    frame.background, frame.edge = background, edge
    frame.topEdge, frame.bottomEdge = top, bottom
    return frame
end

local function createIconButton(parent, texture)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(COMMAND_BUTTON_SIZE, COMMAND_BUTTON_SIZE)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(18, 18)
    icon:SetTexture(texture)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetPoint("CENTER")
    highlight:SetSize(20, 20)
    highlight:SetColorTexture(1, 1, 1, 0.10)
    button:SetScript("OnEnable", function(self)
        self:SetAlpha(1)
        if self.icon.SetDesaturated then self.icon:SetDesaturated(false) end
    end)
    button:SetScript("OnDisable", function(self)
        self:SetAlpha(0.38)
        if self.icon.SetDesaturated then self.icon:SetDesaturated(true) end
    end)
    button.icon = icon
    button.highlight = highlight
    return button
end

local function rowGuid(row)
    if row.previewGuid then return row.previewGuid end
    return D.GetUnitGUID(row.unitId)
end

local function drinkCopy(state)
    if state == "detected" then
        return "DRINKING", COLORS.detected,
            "Recognized drink aura active."
    end
    if state == "notDetected" then
        return "THIRSTY", COLORS.notDetected,
            "Below 75% mana; no recognized drink aura. This does not prove refusal."
    end
    return "DRINK STATUS UNAVAILABLE", COLORS.unavailable,
        "Drink auras cannot be inspected on this client."
end

local function drinkStatusText(entry, now)
    local status = drinkCopy(entry and entry.drinkState)
    if not entry or entry.drinkState ~= "detected" then return status end
    local duration = tonumber(entry.drinkAuraDuration)
    local expiration = tonumber(entry.drinkAuraExpirationTime)
    if not duration or duration <= 0 or not expiration or expiration <= 0 then
        return status
    end
    now = tonumber(now) or (GetTime and GetTime()) or 0
    local remaining = math.ceil(math.max(0, expiration - now))
    if remaining <= 0 then return status end
    return status .. " " .. tostring(remaining) .. "s"
end

local function createDrinkCard(row)
    local card = createSurface(sidecar, DRINK_CARD_HEIGHT, "Button")
    card:SetWidth(DRINK_CARD_WIDTH)
    local state = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    state:SetPoint("LEFT", card, "LEFT", 6, 0)
    state:SetPoint("RIGHT", card, "RIGHT", -5, 0)
    state:SetJustifyH("LEFT")
    state:SetWordWrap(false)
    card.state = state
    card:SetScript("OnClick", function(self)
        if self.entry then D.Runtime.SendManaUp() end
    end)
    card:Hide()
    row.groupHelperDrinkCard = card
    drinkCards[#drinkCards + 1] = card
end

local function createBuffIndicator(parent)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(BUFF_ICON_SIZE, BUFF_ICON_SIZE)
    if frame.EnableMouse then frame:EnableMouse(true) end
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(BUFF_ICON_SIZE, BUFF_ICON_SIZE)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local badge = frame:CreateTexture(nil, "OVERLAY")
    badge:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    badge:SetSize(9, 9)
    badge:SetColorTexture(0.025, 0.030, 0.040, 0.94)
    local count = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("CENTER", badge, "CENTER", 0, 0)
    count:SetTextColor(0.92, 0.92, 0.90, 1)
    if count.SetScale then count:SetScale(0.72) end
    frame.icon, frame.badge, frame.count = icon, badge, count
    frame:SetScript("OnClick", function(self)
        if self.issue then D.Runtime.SendBuffUp() end
    end)
    frame:Hide()
    return frame
end

local function createBuffLane(row)
    local lane = CreateFrame("Frame", nil, sidecar)
    lane:SetSize(BUFF_LANE_WIDTH, DRINK_CARD_HEIGHT)
    lane.icons = {}
    for index = 1, 2 do
        local indicator = createBuffIndicator(lane)
        indicator:SetPoint("RIGHT", lane, "RIGHT",
            -(index - 1) * (BUFF_ICON_SIZE + BUFF_ICON_GAP), 0)
        lane.icons[index] = indicator
    end
    lane:Hide()
    row.groupHelperBuffLane = lane
    buffLanes[#buffLanes + 1] = lane
end

local function hideHelperVisuals()
    for _, card in ipairs(drinkCards) do card:Hide() end
    for _, lane in ipairs(buffLanes) do lane:Hide() end
    if commandRow then commandRow:Hide() end
    if sidecar then sidecar:Hide() end
end

local function renderBuffIssues(snapshot)
    local byProvider = {}
    if snapshot.visible then
        for _, issue in ipairs(snapshot.buffIssues or {}) do
            for _, guid in ipairs(issue.providerGuids or {}) do
                byProvider[guid] = byProvider[guid] or {}
                byProvider[guid][#byProvider[guid] + 1] = issue
            end
        end
    end
    for index, row in ipairs(rows) do
        local lane = buffLanes[index]
        local issues = byProvider[rowGuid(row)] or {}
        lane:SetShown(#issues > 0)
        for iconIndex, indicator in ipairs(lane.icons) do
            local issue = issues[iconIndex]
            indicator.issue = issue
            indicator:SetShown(issue ~= nil)
            setButtonEnabled(indicator, snapshot.sayAvailable == true)
            if issue then
                local provider = tostring(issue.providerClassToken or "Provider")
                provider = provider:sub(1, 1) .. provider:sub(2):lower()
                indicator.icon:SetTexture(issue.icon)
                indicator.count:SetText(tostring(issue.missingCount or ""))
                D.Helpers.SetTooltip(indicator, issue.label .. " missing",
                    "Missing (" .. tostring(issue.missingCount or 0) .. "): "
                        .. table.concat(issue.missingNames or {}, ", ") .. "\n"
                        .. provider .. " can buff · /say buff up")
            end
        end
    end
end

local function renderDrinkCards(snapshot)
    local byGuid = {}
    for _, entry in ipairs(snapshot.manaRows or {}) do
        if entry.guid then byGuid[entry.guid] = entry end
    end
    for index, row in ipairs(rows) do
        local card = drinkCards[index]
        local entry = snapshot.visible and byGuid[rowGuid(row)] or nil
        card.entry = entry
        card:SetShown(entry ~= nil)
        setButtonEnabled(card, snapshot.sayAvailable == true)
        if entry then
            local status, color, tooltip = drinkCopy(entry.drinkState)
            card.state:SetText(drinkStatusText(entry))
            card.state:SetTextColor(color[1], color[2], color[3], color[4])
            card.edge:SetColorTexture(unpack(color))
            D.Helpers.SetTooltip(card, status,
                tooltip .. " · /say " .. D.Runtime.GetMessages().manaUp)
        end
    end
end

local function commit(snapshot)
    if InCombatLockdown and InCombatLockdown() then
        hideHelperVisuals()
        return false
    end
    local helperVisible = snapshot.visible == true
    local pullVisible = snapshot.pullVisible == true
    local commandVisible = pullVisible
    committedReserved = snapshot.eligible == true or pullVisible
    renderDrinkCards(snapshot)
    renderBuffIssues(snapshot)
    commandRow:SetShown(commandVisible)
    commandRow:SetWidth(PULL_ONLY_ROW_WIDTH)
    tankButton:SetShown(pullVisible)
    setButtonEnabled(tankButton, snapshot.sayAvailable == true)
    sidecar:SetShown(commandVisible or helperVisible)
    D.RequestLayoutUpdate()
    return true
end

function Presentation.Render(snapshot)
    currentSnapshot = snapshot or currentSnapshot
    return commit(previewSnapshot or currentSnapshot)
end

function Presentation.SetPreview(snapshot)
    previewSnapshot = snapshot
    return commit(previewSnapshot or currentSnapshot)
end

function Presentation.ClearPreview()
    previewSnapshot = nil
    for _, row in ipairs(rows) do row.previewGuid = nil end
    return commit(currentSnapshot)
end

function Presentation.IsPreviewing() return previewSnapshot ~= nil end

function Presentation.Tick(now)
    for _, card in ipairs(drinkCards) do
        if card:IsShown() and card.entry and card.entry.drinkState == "detected" then
            card.state:SetText(drinkStatusText(card.entry, now))
        end
    end
end

function Presentation.HideForCombat() hideHelperVisuals() end
function Presentation.RefreshAfterCombat() return true end

function Presentation.GetRequiredHeight(rowBottomOffset)
    if not committedReserved and not previewSnapshot then return 0 end
    return tonumber(rowBottomOffset) or 0
end

function Presentation.LayoutSidecar(rowAnchor, rowBottomOffset)
    if not sidecar or (InCombatLockdown and InCombatLockdown()) then return end
    sidecar:ClearAllPoints()
    sidecar:SetPoint("TOPRIGHT", rowAnchor, "TOPLEFT", -SIDECAR_GAP, 0)
    sidecar:SetSize(SIDECAR_WIDTH,
        math.max(1, Presentation.GetRequiredHeight(rowBottomOffset)))
    local firstHealthBar = rows[1] and rows[1].primary and rows[1].primary.barBg
    commandRow:ClearAllPoints()
    if firstHealthBar then
        commandRow:SetPoint("BOTTOMRIGHT", firstHealthBar, "TOPLEFT",
            -SIDECAR_GAP, COMMAND_GAP)
    else
        commandRow:SetPoint("BOTTOMRIGHT", sidecar, "TOPRIGHT", 0, COMMAND_GAP)
    end
    for index, row in ipairs(rows) do
        local card = drinkCards[index]
        card:ClearAllPoints()
        card:SetPoint("RIGHT", row.primary.barBg, "LEFT", -SIDECAR_GAP, 0)
        card:SetSize(DRINK_CARD_WIDTH, DRINK_CARD_HEIGHT)
        local lane = buffLanes[index]
        lane:ClearAllPoints()
        lane:SetPoint("RIGHT", row.primary.barBg, "LEFT",
            -(SIDECAR_GAP + DRINK_CARD_WIDTH + BUFF_ICON_GAP), 0)
        lane:SetSize(BUFF_LANE_WIDTH, DRINK_CARD_HEIGHT)
    end
end

function Presentation.Initialize(deps)
    for _, key in ipairs({
        "Rows", "Runtime", "Helpers", "GetUnitGUID", "RequestLayoutUpdate",
    }) do
        assert(deps and deps[key] ~= nil,
            "GroupHelperPresentation missing dependency: " .. key)
    end
    D, rows = deps, deps.Rows
end

function Presentation.Build(parent)
    if sidecar then return sidecar end
    sidecar = CreateFrame("Frame", nil, parent)
    sidecar:SetSize(SIDECAR_WIDTH, 1)
    sidecar:EnableMouse(false)
    sidecar:SetScript("OnUpdate", function(self, elapsed)
        self.drinkTimerElapsed = (self.drinkTimerElapsed or 0) + (elapsed or 0)
        if self.drinkTimerElapsed >= 0.20 then
            self.drinkTimerElapsed = 0
            Presentation.Tick()
        end
    end)
    for _, row in ipairs(rows) do
        createDrinkCard(row)
        createBuffLane(row)
    end

    commandRow = CreateFrame("Frame", nil, sidecar)
    commandRow:SetHeight(COMMAND_ROW_HEIGHT)
    commandRow:SetWidth(PULL_ONLY_ROW_WIDTH)

    tankButton = createIconButton(commandRow, TANK_ICON)
    tankButton:SetPoint("RIGHT", commandRow, "RIGHT", -COMMAND_EDGE_INSET, 0)
    D.Helpers.SetTooltip(tankButton, "Pulling here",
        "Sends: /say " .. D.Runtime.GetMessages().pullingHere)
    tankButton:SetScript("OnClick", function()
        D.Runtime.SendPullingHere()
    end)

    sidecar.commandRow = commandRow
    sidecar.tankButton = tankButton
    sidecar.drinkCards = drinkCards
    sidecar.buffLanes = buffLanes
    sidecar:Hide()
    return sidecar
end

function Presentation.GetFrame() return sidecar end
function Presentation.GetRows() return rows end
function Presentation.GetWidth() return SIDECAR_WIDTH end
