ApogeePartyHealthBars_C = {
    SHORTCUT_ICON_SIZE = 24,
    SHORTCUT_ICON_GAP = 3,
    MANA_H = 5,
    MANA_GAP = 1,
    FLAT_BAR_TEXTURE = "flat",
    BAR_BG_COLOR = { 0.05, 0.05, 0.05, 1 },
    SHIELD_BAR_COLOR = { 0.15, 0.85, 1, 1 },
    INCOMING_HEAL_COLOR = { 0.25, 0.78, 0.35, 0.65 },
}
ApogeePartyHealthBars_S = {
    configMode = false,
    sv = { enabled = true, targetEffectRemindersEnabled = true },
}

local health, healthMaximum, validHealthMaximum = 80, 100, true
local channels = {
    { powerType = 0, powerToken = "MANA", value = 75, maximum = 100 },
    { powerType = 3, powerToken = "ENERGY", value = 40, maximum = 80 },
}
ApogeePartyHealthBars_UnitAPI = {
    GetHealth = function() return health, healthMaximum, validHealthMaximum end,
    GetPowerChannels = function() return channels end,
    GetPowerColor = function(_, token)
        if token == "MANA" then return 0.3, 0.5, 0.9, 1 end
        return 1, 0.8, 0.1, 1
    end,
}
local hudSupported, effectsSupported = true, true
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(featureKey)
        if featureKey == "targetHud" then return hudSupported end
        if featureKey == "targetEffectReminders" then return effectsSupported end
        return false
    end,
}
local registered, enabledCalls = nil, {}
ApogeePartyHealthBars_TargetNameplateHud = {
    RegisterSurface = function(key, frame, order, gap)
        registered = { key = key, frame = frame, order = order, gap = gap }
    end,
    SetSurfaceEnabled = function(key, enabled)
        enabledCalls[#enabledCalls + 1] = { key, enabled }
    end,
}

local function widget(parent, frameType)
    local value = {
        parent = parent, frameType = frameType, points = {}, shown = true,
        mouseEnabled = nil, frameLevel = 2,
    }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetWidth(width) self.width = width end
    function value:GetWidth() return self.width or (self.parent and self.parent.width) or 1 end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:CreateTexture() return widget(self, "Texture") end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetHorizTile(nextValue) self.horizTile = nextValue end
    function value:SetVertTile(nextValue) self.vertTile = nextValue end
    function value:SetVertexColor(...) self.vertexColor = { ... } end
    function value:SetStatusBarTexture(texture) self.statusBarTexture = texture end
    function value:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function value:SetValue(nextValue) self.value = nextValue end
    function value:SetStatusBarColor(...) self.color = { ... } end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:SetAllPoints(anchor) self.allPoints = anchor or true end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:GetFrameLevel() return self.frameLevel end
    function value:SetShown(shown) self.shown = shown end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    return value
end

UIParent = widget(nil, "Frame")
function CreateFrame(frameType, _, parent) return widget(parent, frameType) end

local shieldEnabled, incomingEnabled = true, true
local shieldAmount, incomingAmount = 20, 30
local deps = {
    IsShieldEnabled = function() return shieldEnabled end,
    ShouldTrackShieldUnit = function(unit) return unit == "player" end,
    GetShieldRemaining = function() return shieldAmount end,
    IsIncomingHealEnabled = function() return incomingEnabled end,
    ShouldTrackIncomingUnit = function(unit) return unit == "player" end,
    GetIncomingAmount = function() return incomingAmount end,
}

dofile("PartyFrames/PlayerStatusHud.lua")
local hud = ApogeePartyHealthBars_PlayerStatusHud
local valid, validationError = pcall(hud.Initialize, {})
assert(not valid and tostring(validationError):find("IsShieldEnabled", 1, true),
    "player status HUD accepted incomplete dependencies")
hud.Initialize(deps)
local row = hud.GetAnchor()
assert(registered and registered.key == "playerStatus" and registered.frame == row
        and registered.order == 1 and registered.gap == 0
        and row.width == 159 and row.height == 1 and row.mouseEnabled == false,
    "player status HUD did not register as the passive lower Target HUD surface")

local snapshot = hud.Refresh()
local healthBar, shieldBar = hud.GetHealthBar(), hud.GetShieldBar()
local incomingBar, powerBars = hud.GetIncomingHealBar(), hud.GetPowerBars()
local powerBackgrounds = hud.GetPowerBackgrounds()
assert(snapshot.health == 80 and snapshot.shield == 20 and snapshot.incoming == 30
        and row.width == 159 and row.height == 22 and #hud.GetChannels() == 2
        and healthBar.minimum == 0 and healthBar.maximum == 120 and healthBar.value == 80
        and healthBar.color[1] == 0.28 and healthBar.color[2] == 0.74
        and shieldBar.shown and shieldBar.points[1][4] == 106 and shieldBar.width == 26.5
        and incomingBar.shown and incomingBar.maximum == 120 and incomingBar.value == 110
        and powerBackgrounds[1].points[1][5] == -11
        and powerBackgrounds[2].points[1][5] == -17
        and powerBars[1].value == 75 and powerBars[2].value == 40
        and enabledCalls[#enabledCalls][2] == true,
    "combined health, overlay, and dual-power geometry changed")

local preview = hud.CreateConfigurationPreview(UIParent)
assert(preview.width == 159 and preview.height == 22 and preview.shown
        and preview.display.healthBar.value == 55
        and preview.display.healthBar.maximum == 120
        and preview.display.shieldBar.shown
        and preview.display.incomingHealBar.value == 100,
    "Target HUD preview did not demonstrate health, shields, incoming heals, and power")

shieldEnabled = false
hud.Refresh()
assert(healthBar.maximum == 100 and not shieldBar.shown
        and incomingBar.maximum == 100 and incomingBar.value == 100,
    "shield preference did not independently remove and rescale its overlay")
incomingEnabled = false
hud.Refresh()
assert(not incomingBar.shown, "incoming-heal preference did not hide its overlay")
shieldEnabled, incomingEnabled = true, true

channels = { { powerType = 1, powerToken = "RAGE", value = 35, maximum = 100 } }
hud.Refresh()
assert(row.height == 16 and powerBackgrounds[1].points[1][5] == -11
        and not powerBars[2].shown,
    "single-resource player status HUD did not collapse to 16px")

validHealthMaximum = false
hud.Refresh()
assert(row.height == 5 and not healthBar.shown and not shieldBar.shown
        and not incomingBar.shown and powerBackgrounds[1].points[1][5] == 0,
    "invalid health did not collapse while retaining valid power")
channels = {}
hud.Refresh()
assert(row.height == 1 and not row.shown and enabledCalls[#enabledCalls][2] == false,
    "missing health and power did not fail closed")
validHealthMaximum, health, healthMaximum = true, 65, 100
hud.Refresh()
assert(row.height == 10 and healthBar.shown and enabledCalls[#enabledCalls][2] == true,
    "health-only player status HUD did not remain available")

ApogeePartyHealthBars_S.configMode = true
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == false, "Settings mode did not suppress player status")
ApogeePartyHealthBars_S.configMode = false
ApogeePartyHealthBars_S.sv.targetEffectRemindersEnabled = false
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == false, "disabled Target HUD retained player status")
ApogeePartyHealthBars_S.sv.targetEffectRemindersEnabled = true
effectsSupported = false
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == true,
    "missing Target Effects APIs incorrectly hid basic player status")
hudSupported = false
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == false, "unsupported Target HUD retained player status")
hudSupported, effectsSupported = true, true
ApogeePartyHealthBars_S.sv.enabled = false
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == false, "disabled addon retained player status")
hud.Hide()
assert(enabledCalls[#enabledCalls][2] == false, "explicit hide re-enabled player status")

print("PASS player status Target HUD")
