local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local API = ApogeePartyHealthBars_UnitAPI
local Capabilities = ApogeePartyHealthBars_ClientCapabilities
local TargetHud = ApogeePartyHealthBars_TargetNameplateHud

ApogeePartyHealthBars_PlayerStatusHud = {}
local H = ApogeePartyHealthBars_PlayerStatusHud

local SURFACE_KEY = "playerStatus"
local SURFACE_ORDER = 1
local SURFACE_GAP = 0
local BAR_WIDTH = 6 * (C.SHORTCUT_ICON_SIZE or 24) + 5 * (C.SHORTCUT_ICON_GAP or 3)
local HEALTH_HEIGHT = 10
local HEALTH_POWER_GAP = 1
local POWER_HEIGHT = C.MANA_H or 5
local POWER_GAP = C.MANA_GAP or 1
local HEALTH_COLOR = { 0.28, 0.74, 0.46, 1 }

local D
local live
local previews = {}

local function ApplyBackground(texture)
    texture:SetTexture(C.FLAT_BAR_TEXTURE)
    texture:SetHorizTile(false)
    texture:SetVertTile(false)
    texture:SetVertexColor(unpack(C.BAR_BG_COLOR))
end

local function ApplyStatusBar(bar, color)
    bar:SetStatusBarTexture(C.FLAT_BAR_TEXTURE)
    if color then bar:SetStatusBarColor(unpack(color)) end
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:EnableMouse(false)
end

local function CreateDisplay(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(BAR_WIDTH, 1)
    frame:EnableMouse(false)

    local healthBackground = frame:CreateTexture(nil, "BACKGROUND")
    ApplyBackground(healthBackground)
    healthBackground:Hide()

    local healthBar = CreateFrame("StatusBar", nil, frame)
    ApplyStatusBar(healthBar, HEALTH_COLOR)
    healthBar:Hide()

    local incomingHealBar = CreateFrame("StatusBar", nil, healthBar)
    incomingHealBar:SetAllPoints()
    ApplyStatusBar(incomingHealBar, C.INCOMING_HEAL_COLOR)
    incomingHealBar:SetFrameLevel(healthBar:GetFrameLevel() - 1)
    incomingHealBar:Hide()

    local shieldBar = CreateFrame("StatusBar", nil, healthBar)
    ApplyStatusBar(shieldBar, C.SHIELD_BAR_COLOR)
    shieldBar:SetFrameLevel(healthBar:GetFrameLevel())
    shieldBar:Hide()

    local display = {
        frame = frame,
        healthBackground = healthBackground,
        healthBar = healthBar,
        shieldBar = shieldBar,
        incomingHealBar = incomingHealBar,
        powerBackgrounds = {},
        powerBars = {},
        channels = {},
    }
    frame.display = display

    for index = 1, 2 do
        local background = frame:CreateTexture(nil, "BACKGROUND")
        ApplyBackground(background)
        background:Hide()

        local bar = CreateFrame("StatusBar", nil, frame)
        ApplyStatusBar(bar)
        bar:Hide()
        display.powerBackgrounds[index], display.powerBars[index] = background, bar
    end
    return display
end

local function LayoutShield(display, health, visualMaximum, shield)
    if shield <= 0 then
        display.shieldBar:Hide()
        return
    end
    local healthWidth = BAR_WIDTH * health / visualMaximum
    local shieldWidth = math.max(BAR_WIDTH * shield / visualMaximum, 1)
    display.shieldBar:ClearAllPoints()
    display.shieldBar:SetPoint("TOPLEFT", display.healthBar, "TOPLEFT", healthWidth, 0)
    display.shieldBar:SetPoint("BOTTOMLEFT", display.healthBar, "BOTTOMLEFT", healthWidth, 0)
    display.shieldBar:SetWidth(shieldWidth)
    display.shieldBar:SetMinMaxValues(0, 1)
    display.shieldBar:SetValue(1)
    display.shieldBar:Show()
end

local function LayoutIncomingHeal(display, health, visualMaximum, incoming)
    if incoming <= 0 then
        display.incomingHealBar:Hide()
        return
    end
    display.incomingHealBar:SetMinMaxValues(0, visualMaximum)
    display.incomingHealBar:SetValue(math.min(health + incoming, visualMaximum))
    display.incomingHealBar:Show()
end

local function RenderHealth(display, health, healthMaximum, validMaximum, shield, incoming)
    if not validMaximum then
        display.healthBackground:Hide()
        display.healthBar:Hide()
        display.shieldBar:Hide()
        display.incomingHealBar:Hide()
        return false
    end
    shield = math.max(0, tonumber(shield) or 0)
    incoming = math.max(0, tonumber(incoming) or 0)
    local visualMaximum = math.max(healthMaximum + shield, 1)

    display.healthBackground:ClearAllPoints()
    display.healthBackground:SetPoint("TOPLEFT", display.frame, "TOPLEFT", 0, 0)
    display.healthBackground:SetSize(BAR_WIDTH, HEALTH_HEIGHT)
    display.healthBar:ClearAllPoints()
    display.healthBar:SetAllPoints(display.healthBackground)
    display.healthBar:SetMinMaxValues(0, visualMaximum)
    display.healthBar:SetValue(health)
    display.healthBar:SetStatusBarColor(unpack(HEALTH_COLOR))
    display.healthBackground:Show()
    display.healthBar:Show()
    LayoutShield(display, health, visualMaximum, shield)
    LayoutIncomingHeal(display, health, visualMaximum, incoming)
    return true
end

local function RenderPower(display, channels, topOffset)
    display.channels = channels or {}
    local count = math.min(2, #display.channels)
    local y = topOffset
    for index = 1, 2 do
        local background, bar = display.powerBackgrounds[index], display.powerBars[index]
        local channel = display.channels[index]
        if channel then
            background:ClearAllPoints()
            background:SetPoint("TOPLEFT", display.frame, "TOPLEFT", 0, -y)
            background:SetSize(BAR_WIDTH, POWER_HEIGHT)
            bar:ClearAllPoints()
            bar:SetAllPoints(background)
            bar:SetMinMaxValues(0, channel.maximum)
            bar:SetValue(channel.value)
            bar:SetStatusBarColor(API.GetPowerColor(channel.powerType, channel.powerToken))
            background:Show()
            bar:Show()
            y = y + POWER_HEIGHT + POWER_GAP
        else
            background:Hide()
            bar:Hide()
        end
    end
    return count
end

local function Render(display, snapshot)
    local hasHealth = RenderHealth(display, snapshot.health, snapshot.healthMaximum,
        snapshot.validHealthMaximum, snapshot.shield, snapshot.incoming)
    local powerOffset = hasHealth and (HEALTH_HEIGHT + HEALTH_POWER_GAP) or 0
    local powerCount = RenderPower(display, snapshot.channels, powerOffset)
    local powerHeight = powerCount > 0
        and powerCount * POWER_HEIGHT + (powerCount - 1) * POWER_GAP or 0
    local height = (hasHealth and HEALTH_HEIGHT or 0)
        + (hasHealth and powerCount > 0 and HEALTH_POWER_GAP or 0)
        + powerHeight
    display.frame:SetSize(BAR_WIDTH, math.max(1, height))
    display.frame:SetShown(height > 0)
    return height > 0
end

local function GetLiveSnapshot()
    local health, healthMaximum, validHealthMaximum = API.GetHealth("player")
    local shield = 0
    if validHealthMaximum and D.IsShieldEnabled() and D.ShouldTrackShieldUnit("player") then
        shield = D.GetShieldRemaining("player") or 0
    end
    local incoming = 0
    if validHealthMaximum and D.IsIncomingHealEnabled()
        and D.ShouldTrackIncomingUnit("player") then
        incoming = D.GetIncomingAmount("player") or 0
    end
    return {
        health = health,
        healthMaximum = healthMaximum,
        validHealthMaximum = validHealthMaximum,
        shield = shield,
        incoming = incoming,
        channels = API.GetPowerChannels("player"),
    }
end

local function GetPreviewSnapshot()
    return {
        health = 55,
        healthMaximum = 100,
        validHealthMaximum = true,
        shield = 20,
        incoming = 45,
        channels = API.GetPowerChannels("player"),
    }
end

local function IsEnabled()
    return S.sv and S.sv.enabled == true
        and S.sv.targetEffectRemindersEnabled == true
        and not S.configMode
        and Capabilities.IsFeatureAvailable("targetHud")
end

function H.Refresh()
    assert(live, "PlayerStatusHud must be initialized before refresh")
    local snapshot = GetLiveSnapshot()
    local hasContent = Render(live, snapshot)
    for _, preview in ipairs(previews) do Render(preview, GetPreviewSnapshot()) end
    TargetHud.SetSurfaceEnabled(SURFACE_KEY, IsEnabled() and hasContent)
    return snapshot
end

function H.RefreshVisibility()
    return H.Refresh()
end

function H.Hide()
    if live then TargetHud.SetSurfaceEnabled(SURFACE_KEY, false) end
end

function H.CreateConfigurationPreview(parent)
    assert(live, "PlayerStatusHud must be initialized before creating a preview")
    local preview = CreateDisplay(parent)
    previews[#previews + 1] = preview
    Render(preview, GetPreviewSnapshot())
    return preview.frame
end

function H.Initialize(deps)
    if live then return end
    for _, key in ipairs({
        "IsShieldEnabled", "ShouldTrackShieldUnit", "GetShieldRemaining",
        "IsIncomingHealEnabled", "ShouldTrackIncomingUnit", "GetIncomingAmount",
    }) do
        assert(deps and deps[key] ~= nil, "PlayerStatusHud missing dependency: " .. key)
    end
    D = deps
    live = CreateDisplay(UIParent)
    TargetHud.RegisterSurface(SURFACE_KEY, live.frame, SURFACE_ORDER, SURFACE_GAP)
end

function H.GetAnchor() return live and live.frame or nil end
function H.GetHealthBar() return live and live.healthBar or nil end
function H.GetShieldBar() return live and live.shieldBar or nil end
function H.GetIncomingHealBar() return live and live.incomingHealBar or nil end
function H.GetPowerBars() return live and live.powerBars or {} end
function H.GetPowerBackgrounds() return live and live.powerBackgrounds or {} end
function H.GetChannels() return live and live.channels or {} end
