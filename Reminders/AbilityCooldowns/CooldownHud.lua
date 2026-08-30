local S = ApogeePartyHealthBars_S
local ThreatHud = ApogeePartyHealthBars_ThreatAwareness

ApogeePartyHealthBars_CooldownHud = {}
local H = ApogeePartyHealthBars_CooldownHud

local ICON_SIZE, ICON_GAP, LANE_GAP, LIMIT = 18, 2, 4, 6
local row
local icons = {}
local entries = {}
local previewEntries = {}
local showingPreview = false
local tickTimer = 0
local COUNTDOWN_UPDATE_RATE = 0.1

local function SetCountText(icon, value)
    value = value or ""
    if icon.countText == value then return end
    icon.countText = value
    icon.count:SetText(value)
end

local function GetRemaining(state, now)
    if state.cooling ~= true then return nil end
    return math.max(0, (state.start or 0) + (state.duration or 0) - now)
end

local function CreateIcon(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ICON_SIZE, ICON_SIZE)
    frame:EnableMouse(false)
    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(true) end
    local count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    count:SetPoint("CENTER", frame, "CENTER", 0, 0)
    count:SetJustifyH("CENTER")
    frame.texture, frame.cooldown, frame.count = texture, cooldown, count
    return frame
end

local function RenderIcon(icon, entry, now)
    icon.entry = entry
    icon.texture:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    local state = entry.state or {}
    local cooling = state.cooling == true
    if cooling and state.start and state.duration and state.duration > 0 then
        icon.cooldown:SetCooldown(state.start, state.duration)
        icon.cooldown:Show()
    else
        icon.cooldown:Hide()
        if icon.cooldown.Clear then icon.cooldown:Clear() end
    end
    local remaining = GetRemaining(state, now)
    if cooling and state.ready ~= true then
        SetCountText(icon, remaining and tostring(math.ceil(remaining)) or "")
    elseif state.maximumCharges and state.maximumCharges > 1 then
        SetCountText(icon, tostring(state.charges or 0))
    else
        SetCountText(icon, "")
    end
    local visuallyReady = state.ready == true and state.usable ~= false
    if icon.texture.SetDesaturated then icon.texture:SetDesaturated(not visuallyReady) end
    icon.texture:SetAlpha(visuallyReady and 1 or 0.55)
    icon:Show()
end

local function Layout(activeEntries)
    activeEntries = activeEntries or {}
    local count = math.min(LIMIT, #activeEntries)
    row:SetSize(count > 0 and count * ICON_SIZE + (count - 1) * ICON_GAP or 1, ICON_SIZE)
    local now = GetTime and GetTime() or 0
    tickTimer = 0
    for index = 1, count do
        local icon = icons[index]
        if not icon then icon = CreateIcon(row); icons[index] = icon end
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", row, "LEFT", (index - 1) * (ICON_SIZE + ICON_GAP), 0)
        RenderIcon(icon, activeEntries[index], now)
    end
    for index = count + 1, #icons do icons[index]:Hide() end
end

local function ActiveEntries()
    return S.configMode and previewEntries or entries
end

function H.SetEntries(nextEntries)
    H.Initialize()
    entries = nextEntries or {}
    if not S.configMode then Layout(entries) end
    H.RefreshVisibility()
end

function H.SetPreviewEntries(nextEntries)
    previewEntries = nextEntries or {}
    if S.configMode and row then Layout(previewEntries) end
    H.RefreshVisibility()
end

function H.RefreshVisibility()
    if not row then return end
    local active = ActiveEntries()
    if S.configMode then
        Layout(active)
        showingPreview = true
    elseif showingPreview then
        Layout(entries)
        showingPreview = false
    end
    row:SetShown(S.sv and S.sv.enabled == true
        and S.sv.abilityCooldownsEnabled ~= false and #active > 0)
end

function H.Tick(elapsed)
    if not row or not row:IsShown() then return false end
    if elapsed ~= nil then
        tickTimer = tickTimer - (tonumber(elapsed) or 0)
        if tickTimer > 0 then return false end
        tickTimer = COUNTDOWN_UPDATE_RATE
    end
    local active, expired = ActiveEntries(), false
    local now = GetTime and GetTime() or 0
    for index = 1, math.min(LIMIT, #active) do
        local icon, state = icons[index], active[index].state or {}
        if icon and state.cooling == true and state.ready ~= true then
            local remaining = GetRemaining(state, now)
            SetCountText(icon, remaining and tostring(math.ceil(remaining)) or "")
            if remaining and remaining <= 0 then expired = true end
        end
    end
    return expired
end

function H.Hide() if row then row:Hide() end end

function H.Initialize()
    if row then return end
    local playerStatusAnchor = ThreatHud.GetPlayerStatusAnchor()
    assert(playerStatusAnchor, "CooldownHud requires the built Threat Control player status")
    row = CreateFrame("Frame", nil, ThreatHud.GetFrame())
    row:SetSize(1, ICON_SIZE)
    row:SetPoint("LEFT", playerStatusAnchor, "RIGHT", LANE_GAP, 0)
    row:EnableMouse(false)
    row:Hide()
end

function H.GetAnchor() return row end
function H.GetIcons() return icons end
function H.GetEntries() return entries end
